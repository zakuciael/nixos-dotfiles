#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p "python3.withPackages (ps: [ ps.lief ])"
"""
Patch discord_krisp.node to bypass its signature verification

Krisp checks its own code signature on load. Since Nix modifies the binary (e.g.
patchelf), the signature no longer matches and the module refuses to start. We
patch the verification function to always return true

ELF (Linux)
-----------
The check lives in discord::util::IsSignedByDiscord(). It MD5-hashes the file
and compares the result with SSE2. Discord ships stripped ELFs, but .eh_frame
(DWARF unwind info) still gives us every function's start address. We scan .text
for the unique MD5-compare byte sequence (pmovmskb + cmp $0xffff), find the
function whose range contains it, and overwrite the entry with "mov eax, 1; ret"

  # before:                                    # after:
  #   pmovmskb %xmm0, %eax  ; 66 0f d7 c0      #   mov $0x1, %eax  ; b8 01 00 00 00
  #   cmp $0xffff, %eax     ; 3d ff ff 00 00   #   ret             ; c3
  #   sete %bpl             ; 40 0f 94 c5      #
"""

import mmap
import sys
from bisect import bisect_right
from dataclasses import dataclass

import lief

# mov eax, 1; ret
RETURN_TRUE = b"\xb8\x01\x00\x00\x00\xc3"

# MD5-hash comparison idiom inside IsSignedByDiscord:
#   pmovmskb %xmm0,%eax ; cmp $0xffff,%eax
ELF_SIG = b"\x66\x0f\xd7\xc0\x3d\xff\xff\x00\x00"


@dataclass(frozen=True)
class FunctionStarts:
    """Sorted function starts with a helper for address-to-function lookup."""

    addrs: tuple[int, ...]

    @classmethod
    def from_lief(cls, binary) -> "FunctionStarts":
        addrs = tuple(sorted(f.address for f in binary.functions))
        if not addrs:
            raise SystemExit("Error: no function starts found")
        return cls(addrs)

    def require_containing(self, addr: int) -> int:
        idx = bisect_right(self.addrs, addr) - 1
        if idx < 0:
            raise SystemExit(f"Error: no function contains address 0x{addr:x}")
        return self.addrs[idx]


def _apply_patch(mm: mmap.mmap, off: int, patch: bytes) -> None:
    state = (
        "already patched"
        if mm[off : off + len(patch)] == patch
        else "patched -> return true"
    )
    mm[off : off + len(patch)] = patch
    print(f"[krisp-patcher] ELF: {state}")


def _unique_match(mm: mmap.mmap, needle: bytes, start: int, end: int) -> int:
    idx = mm.find(needle, start, end)
    if idx == -1 or mm.find(needle, idx + 1, end) != -1:
        raise SystemExit("Error: expected exactly 1 signature match")
    return idx


def patch_elf(mm: mmap.mmap, path: str) -> None:
    binary = lief.ELF.parse(path)
    text = binary.get_section(".text")
    if text is None:
        raise SystemExit("Error: .text not found")
    text_off, text_sz = text.file_offset, text.size
    # Offset between file offset and vaddr within .text (constant across the section)
    text_delta = text.virtual_address - text_off

    idx = _unique_match(mm, ELF_SIG, text_off, text_off + text_sz)

    # binary.functions is populated from .eh_frame unwind info, which is
    # present even in stripped binaries. Bisect picks the containing function
    functions = FunctionStarts.from_lief(binary)
    func_vaddr = functions.require_containing(idx + text_delta)
    func_off = func_vaddr - text_delta

    print(f"[krisp-patcher] ELF: signature at 0x{idx:x}, function at 0x{func_off:x}")
    _apply_patch(mm, func_off, RETURN_TRUE)


def main() -> None:
    if len(sys.argv) < 2:
        raise SystemExit(f"Usage: {sys.argv[0]} <discord_krisp.node>")
    path = sys.argv[1]
    with open(path, "r+b") as f, mmap.mmap(f.fileno(), 0) as mm:
        if mm[:4] != b"\x7fELF":
            raise SystemExit("Error: expected an ELF discord_krisp.node")
        patch_elf(mm, path)


if __name__ == "__main__":
    main()
