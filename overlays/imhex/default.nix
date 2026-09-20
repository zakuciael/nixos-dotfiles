{ lib, ... }:
lib.singleton (
  final: prev:
  let
    imhexMcpVersion = "2.0.0";
    imhexMcpRev = "c9ceb7f791e5e9233c555a1fc3770b4403d08dcf";

    imhexMcpSrc = final.fetchFromGitHub {
      owner = "jmpnop";
      repo = "imhexMCP";
      rev = imhexMcpRev;
      hash = "sha256-gDcUYTQrYBCU/XI+Y/dJIc3nFNFInMMB0HQuMNblTOg=";
    };

    # Order matches setup-imhex-mcp.sh. Upstream 0002 conflicts with ImHex
    # 1.38.1's OpenResult API, so we ship a local replacement instead.
    imhexMcpPatches = map (name: "${imhexMcpSrc}/patches/${name}") [
      "0007-fix-Replace-RequestOpenFile-event-based-approach-wit.patch"
      "0008-fix-Improve-disassembly-and-diff-error-handling.patch"
      "0009-fix-Implement-TaskManager-based-diff-analysis-ALL-v0.patch"
      "0010-feat-Add-batch-open_directory-endpoint-v1.0.0-Phase-.patch"
      "0011-Add-batch-search-endpoint-for-v1.0.0-Phase-2.patch"
      "0012-Add-batch-hash-endpoint-for-v1.0.0-Phase-2.patch"
      "0013-Fix-glob-pattern-matching-in-batch-open_directory.patch"
      "0014-Fix-glob-pattern-escaping-bug-in-batch-open_director.patch"
      "0001-feat-Implement-queue-based-file-opening-to-fix-netwo.patch"
    ];

    pythonEnv = final.python3.withPackages (
      ps: with ps; [
        mcp
        orjson
        prometheus-client
        pydantic
        pyyaml
        zstandard
      ]
    );

    imhex-mcp-server = final.stdenv.mkDerivation {
      pname = "imhex-mcp-server";
      version = imhexMcpVersion;

      src = imhexMcpSrc;

      nativeBuildInputs = [ final.makeWrapper ];

      dontConfigure = true;
      dontBuild = true;

      installPhase = ''
        runHook preInstall

        mkdir -p "$out/share/imhex-mcp"
        cp -r mcp-server lib "$out/share/imhex-mcp/"

        # AI provider MCP configs belong in modules/dev/ai, not the package.
        rm -f "$out/share/imhex-mcp/mcp-server/config.json"

        # Drop tests, benchmarks, and docs from the runtime closure.
        find "$out/share/imhex-mcp" -type f \( \
          -name 'test_*.py' -o \
          -name 'benchmark_*.py' -o \
          -name 'demo_*.py' -o \
          -name '*.md' -o \
          -name 'requirements*.txt' -o \
          -name 'pyproject.toml' -o \
          -name 'install.sh' \
        \) -delete
        rm -rf \
          "$out/share/imhex-mcp/mcp-server/.hypothesis" \
          "$out/share/imhex-mcp/mcp-server/examples"

        makeWrapper ${lib.getExe pythonEnv} "$out/bin/imhex-mcp-server" \
          --add-flags "$out/share/imhex-mcp/mcp-server/server.py" \
          --prefix PYTHONPATH : "$out/share/imhex-mcp/mcp-server"

        runHook postInstall
      '';

      meta = {
        description = "Model Context Protocol server for ImHex";
        homepage = "https://github.com/jmpnop/imhexMCP";
        license = lib.licenses.gpl2Only;
        mainProgram = "imhex-mcp-server";
        platforms = lib.platforms.linux ++ lib.platforms.darwin;
      };
    };
  in
  {
    inherit imhex-mcp-server;

    imhex = prev.imhex.overrideAttrs (prevAttrs: {
      nativeBuildInputs = prevAttrs.nativeBuildInputs ++ [ final.makeWrapper ];

      patches =
        (prevAttrs.patches or [ ])
        ++ imhexMcpPatches
        ++ [
          ./patches/imhex-1.38.1-mcp-compat.patch
        ];

      postInstall = prevAttrs.postInstall + ''
        wrapProgram $out/bin/imhex \
          --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ final.libGL ]}"
      '';

      passthru = (prevAttrs.passthru or { }) // {
        mcpServer = imhex-mcp-server;
        inherit imhexMcpSrc;
      };
    });
  }
)
