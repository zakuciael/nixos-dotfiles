#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p "python3.withPackages (ps: [ ps.lief ])"
"""
Patch discord_krisp.node to bypass its signature verification

Krisp checks its own code signature on load. Since Nix modifies the binary
(e.g. patchelf), the signature no longer matches and the module refuses to
start. We patch the verification function to always return true

ELF (Linux)
-----------
The check lives in discord::util::IsSignedByDiscord(). It MD5-hashes the file
and compares the result with SSE2. We find it by scanning .text for a unique
byte sequence (pmovmskb + cmp $0xffff), walk backward to the function entry,
and overwrite it with "mov eax, 1; ret"

  # before:                                    # after:
  #   pmovmskb %xmm0, %eax  ; 66 0f d7 c0      #   mov $0x1, %eax  ; b8 01 00 00 00
  #   cmp $0xffff, %eax     ; 3d ff ff 00 00   #   ret             ; c3
  #   sete %bpl             ; 40 0f 94 c5      #

Mach-O (macOS, fat binary: x86_64 + arm64)
------------------------------------------
On macOS the check uses Apple's Security framework. We find the
_SecStaticCodeCreateWithPath import stub, then walk callers upward. Each hop
follows the single unique caller of the current target. When the chain fans
out (0 or 2+ callers), we've found the right function to patch

  # the call chain (from nm + c++filt, addresses vary per build):
  #   _SecStaticCodeCreateWithPath   [stub]
  #     <- GetSigningInformation()   hop 1 (only caller of the stub)
  #       <- IsSignedBy()            hop 2 (only caller of hop 1)
  #         <- IsSignedByDiscord()   hop 3 (only caller of hop 2) <- PATCH HERE
  #           <- DoKrispInitialize() hop 4 (only caller of hop 3)
  #              ^^^ has multiple callers, so the chain fans out

Useful commands for poking at a binary yourself:
  otool -f discord_krisp.node                                     # fat header
  otool -arch x86_64 -l discord_krisp.node                        # load commands
  otool -arch x86_64 -Iv discord_krisp.node | grep SecStaticCode  # stub lookup
  nm -arch x86_64 discord_krisp.node | c++filt | grep -i sign     # signing symbols
  objdump -d --start-address=0x4754c0 --stop-address=0x475580 discord_krisp.node
"""

import array
import mmap
import sys
from bisect import bisect_right

import lief


def _first(gen, err):
    """Return first item from gen, or raise SystemExit with err."""
    if (result := next(gen, None)) is None:
        raise SystemExit(err)
    return result


def _apply_patch(mm, off, patch, label):
    state = "already patched" if mm[off : off + len(patch)] == patch else "patched -> return true"
    mm[off : off + len(patch)] = patch
    print(f"[krisp-patcher] {label}: {state}")


MAX_FUNC_SCAN = 512
MIN_FUNC_SZ = 32  # minimum expected bytes before signature
FUNC_ALIGN = 16

ARM64_BL, ARM64_B = 0b100101, 0b000101  # branch-with-link, unconditional branch
ARM64_INSN_SZ = 4
ARM64_OP_SHIFT, IMM26_MASK, IMM26_SIGN_BIT, IMM26_NEG = 26, (1 << 26) - 1, 25, 1 << 26
X86_CALL, X86_JMP, X86_BRANCH_SZ = 0xE8, 0xE9, 5  # near call/jmp + rel32

FUNC_BOUNDARY = frozenset({0x90, 0xCC, 0xC3})  # nop, int3, ret
# MD5 hash comparison idiom: pmovmskb %xmm0,%eax + cmp $0xffff,%eax
ELF_SIG = b"\x66\x0f\xd7\xc0\x3d\xff\xff\x00\x00"

X86_RETURN_TRUE = b"\xb8\x01\x00\x00\x00\xc3"  # mov eax,1; ret
ARM64_RETURN_TRUE = b"\x20\x00\x80\x52\xc0\x03\x5f\xd6"  # movz w0,#1; ret

_ARM64 = lief.MachO.Header.CPU_TYPE.ARM64
RETURN_TRUE = {
    lief.MachO.Header.CPU_TYPE.X86_64: (X86_RETURN_TRUE, "x86_64"),
    _ARM64: (ARM64_RETURN_TRUE, "arm64"),
}

ANCHOR_IMPORT = "_SecStaticCodeCreateWithPath"


def _unique_caller(mm, fstart, text_sz, text_vm, target, cputype, func_entries):
    """Return the single function calling target, or None if not unique."""
    if cputype == _ARM64:
        funcs = {func_entries[bisect_right(func_entries, text_vm + i * ARM64_INSN_SZ) - 1]
                 for i, insn in enumerate(array.array("I", mm[fstart : fstart + text_sz]))
                 if (insn >> ARM64_OP_SHIFT) in (ARM64_BL, ARM64_B)
                 and text_vm + i * ARM64_INSN_SZ + ((insn & IMM26_MASK) - ((insn >> IMM26_SIGN_BIT & 1) * IMM26_NEG)) * ARM64_INSN_SZ == target}
    else:
        funcs = {func_entries[bisect_right(func_entries, text_vm + (off - fstart)) - 1]
                 for off in range(fstart, fstart + text_sz - X86_BRANCH_SZ)
                 if mm[off] in (X86_CALL, X86_JMP)
                 and text_vm + (off - fstart) + X86_BRANCH_SZ + int.from_bytes(mm[off + 1 : off + 5], "little", signed=True) == target}
    return funcs.pop() if len(funcs) == 1 else None


def patch_elf(mm, path):
    text = lief.ELF.parse(path).get_section(".text")
    if text is None:
        raise SystemExit("Error: .text not found")
    text_off, text_sz = text.file_offset, text.size

    if (idx := mm.find(ELF_SIG, text_off, text_off + text_sz)) == -1 \
            or mm.find(ELF_SIG, idx + 1, text_off + text_sz) != -1:
        raise SystemExit("Error: expected exactly 1 signature match in .text")

    func = _first(
        (a for a in range((idx - MIN_FUNC_SZ) & -FUNC_ALIGN, max(idx - MAX_FUNC_SCAN, text_off), -FUNC_ALIGN)
         if mm[a - 1] in FUNC_BOUNDARY and mm[a] not in FUNC_BOUNDARY),
        "Error: could not locate function entry",
    )

    print(f"[krisp-patcher] ELF: signature at 0x{idx:x}, function at 0x{func:x}")
    _apply_patch(mm, func, X86_RETURN_TRUE, "ELF")


def patch_macho_slice(mm, binary):
    """Trace from _SecStaticCodeCreateWithPath up the call chain and patch."""
    cputype = binary.header.cpu_type
    base = binary.fat_offset

    text = binary.get_section("__text")
    text_vm, text_sz, text_off = text.virtual_address, text.size, text.offset

    stubs = binary.get_section("__stubs")
    stub_esz = stubs.reserved2
    n_stubs = stubs.size // stub_esz if stub_esz else 0

    # find anchor stub via indirect symbol table
    indirect = list(binary.dynamic_symbol_command.indirect_symbols)
    target = _first(
        (stubs.virtual_address + i * stub_esz
         for i in range(n_stubs)
         if stubs.reserved1 + i < len(indirect)
         and ANCHOR_IMPORT in indirect[stubs.reserved1 + i].name),
        "Error: _SecStaticCodeCreateWithPath stub not found",
    )

    # build sorted function entry table (reused across hops)
    func_entries = sorted(s.value for s in binary.symbols
                          if text_vm <= s.value < text_vm + text_sz)

    # hop up the call chain; patch the last function before the chain fans out
    # (fan-out = the caller has 0 or 2+ callers itself, so we can't trace further)
    patch, arch = RETURN_TRUE[cputype]
    fstart, hop, prev = base + text_off, 0, target
    while (caller := _unique_caller(mm, fstart, text_sz, text_vm, target, cputype, func_entries)) is not None:
        prev, target, hop = target, caller, hop + 1
        print(f"[krisp-patcher] Mach-O {arch}: hop {hop} -> 0x{target:x}")
    if hop < 2:
        raise SystemExit("Error: call chain too short (expected >= 2 hops)")

    _apply_patch(mm, fstart + (prev - text_vm), patch, arch)


def main():
    if len(sys.argv) < 2:
        raise SystemExit(f"Usage: {sys.argv[0]} <discord_krisp.node>")
    path = sys.argv[1]
    with open(path, "r+b") as f, mmap.mmap(f.fileno(), 0) as mm:
        if mm[:4] == b"\x7fELF":
            patch_elf(mm, path)
        else:
            fat = lief.MachO.parse(path)
            for binary in fat:
                patch_macho_slice(mm, binary)


if __name__ == "__main__":
    main()
