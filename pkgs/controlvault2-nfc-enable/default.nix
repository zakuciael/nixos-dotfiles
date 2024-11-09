{
  lib,
  python3Packages,
  fetchFromGitHub,
  ...
}:
python3Packages.buildPythonApplication {
  pname = "controlvault2-nfc-enable";
  version = "1.0.0";

  src = fetchFromGitHub {
    repo = "controlvault2-nfc-enable";
    owner = "jacekkow";
    rev = "2abbab412b68597f2877860bc8fc722a0b52087b";
    hash = "sha256-twl/XhngpqgJnmTwgG5u/LLg2mXe7NbLeDh7SCyAi4U=";
  };

  dependencies = [python3Packages.pyusb];

  build-system = [python3Packages.setuptools];

  postPatch = ''
    mv nfc.py controlvault2-nfc-enable
  '';

  preBuild = ''
    cat > setup.py << EOF
    from setuptools import setup, find_packages

    setup(
      name = "controlvault2-nfc-enable",
      version = "1.0.0",
      py_modules = ["cv2", "cv3", "cvcomm"],
      scripts = ["controlvault2-nfc-enable"],
      install_requires = ["pyusb"],
    )

    EOF
  '';

  meta = with lib; {
    description = "Enable NFC on Linux for pcscd on Dell E7470 (and others) with ControlVault2";
    license = licenses.bsd3;
    maintainers = with maintainers; [zakuciael];
    mainProgram = "controlvault2-nfc-enable";
    platforms = platforms.linux;
  };
}
