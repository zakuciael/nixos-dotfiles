{
  _7zz,
  bash,
  cabextract,
  fetchFromGitHub,
  glib,
  lib,
  libloot-python,
  python3Packages,
  qt6,
  winetricks,
  xdg-utils,
}:

python3Packages.buildPythonApplication (finalAttrs: {
  pname = "amethyst-mod-manager";
  version = "2.0.5";
  pyproject = false;

  src = fetchFromGitHub {
    owner = "ChrisDKN";
    repo = "Amethyst-Mod-Manager";
    tag = "v${finalAttrs.version}";
    hash = "sha256-TR2dLZ+7gHSO8eosskCKg5JP9b/2MCZQingd3psFK8M=";
  };

  nativeBuildInputs = [
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    qt6.qtbase
  ];

  dependencies = [
    libloot-python
  ]
  ++ (with python3Packages; [
    # https://github.com/ChrisDKN/Amethyst-Mod-Manager/blob/main/src/requirements-vendor.txt
    pyside6
    py7zr
    pillow
    lz4
    zstandard
    requests
    websocket-client
    keyring
    jeepney
    msgpack
    bsdiff4
  ]);

  postPatch = /* bash */ ''
    substituteInPlace src/Utils/protontricks.py \
        --replace-fail '_get_tools_dir() / "winetricks"' 'Path("${lib.getExe winetricks}")' \
        --replace-fail '_get_tools_dir() / "cabextract"' 'Path("${lib.getExe cabextract}")'

    # .NET WindowsDesktop Runtime installers under Wine/Proton frequently exit
    # with code 2 (ERROR_FILE_NOT_FOUND) even when the runtime is successfully
    # installed — Wine's 32-bit dlopen path for libfreetype.so.6 and other
    # libraries fails inside the FHS environment, causing the bundle engine to
    # report a spurious extraction failure.  Treat exit code 2 like exit code 1
    # (already-present / ambiguous-success), since the runtime is usually
    # present after this exit code and retrying won't help.
    substituteInPlace src/Utils/proton_tools.py \
        --replace-fail \
            "frozenset({0, 102, 1638, 3010, 1})" \
            "frozenset({0, 2, 102, 1638, 3010, 1})"

    # Same issue applies to the direct-wine path in synthesis_setup.py —
    # the .NET SDK and Desktop Runtime installers can spuriously return 2.
    substituteInPlace src/Utils/synthesis_setup.py \
        --replace-fail \
            "if result.returncode not in (0, 3010, 1):" \
            "if result.returncode not in (0, 2, 3010, 1):"

    substituteInPlace src/Nexus/nxm_handler.py \
        --replace-fail \
            "f'{cls._quote_if_needed(exe)} {cls._quote_if_needed(script)} --nxm %u'" \
            "'amethyst-mod-manager --nxm %u'"
  '';

  # https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=amethyst-mod-manager
  installPhase = /* bash */ ''
    runHook preInstall

    pushd src > /dev/null
    find . -path "./appimage" -prune -o \
        -not -name "requirements*.txt" \
        -not -name "rebuild_libloot.sh" \
        -not -name "run_qt.sh" \
        -not -name "loot.cpython*.so" \
        -type f \
        -exec install -Dm 755 '{}' "$out/${python3Packages.python.sitePackages}/{}" \;
    popd > /dev/null

    install -d $out/bin/

    cat >$out/bin/amethyst-mod-manager <<EOL
    #!/bin/sh
    exec ${python3Packages.python.interpreter} $out/${python3Packages.python.sitePackages}/run_qt.py "\$@"
    EOL
    chmod +x $out/bin/amethyst-mod-manager

    cat >$out/bin/amethyst-mod-manager-cli <<EOL
    #!/bin/sh
    exec ${python3Packages.python.interpreter} $out/${python3Packages.python.sitePackages}/cli.py "\$@"
    EOL
    chmod +x $out/bin/amethyst-mod-manager-cli

    install -Dm644 flatpak/io.github.Amethyst.ModManager.desktop $out/share/applications/io.github.Amethyst.ModManager.desktop
    install -Dm644 src/appimage/mod-manager.png $out/share/icons/hicolor/256x256/apps/io.github.Amethyst.ModManager.png

    install -Dm644 Changelog.txt $out/${python3Packages.python.sitePackages}/Changelog.txt

    runHook postInstall
  '';

  dontWrapQtApps = true;

  preFixup = ''
    makeWrapperArgs+=(
        --set PYTHONPATH "$out/${python3Packages.python.sitePackages}:$PYTHONPATH"
        --suffix PATH : "${
          lib.makeBinPath [
            # https://github.com/ChrisDKN/Amethyst-Mod-Manager/blob/main/flatpak/io.github.Amethyst.ModManager.yml
            (_7zz.override { enableUnfree = true; })
            bash
            cabextract
            glib # gio, gdbus
            python3Packages.python
            winetricks
            xdg-utils # xdg-open, xdg-mime, xdg-settings
          ]
        }"
    )
    wrapQtApp $out/bin/amethyst-mod-manager "''${makeWrapperArgs[@]}"
    wrapProgram $out/bin/amethyst-mod-manager-cli "''${makeWrapperArgs[@]}"
  '';

  meta = {
    description = "Linux native mod manager for a variety of games";
    homepage = "https://github.com/ChrisDKN/Amethyst-Mod-Manager";
    license = lib.licenses.gpl3Plus;
    maintainers = with lib.maintainers; [ RoGreat ];
    mainProgram = "amethyst-mod-manager";
    platforms = [ "x86_64-linux" ];
  };
})
