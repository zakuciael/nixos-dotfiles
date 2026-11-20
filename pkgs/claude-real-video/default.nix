{
  lib,
  python3Packages,
  fetchFromGitHub,
  ffmpeg,
  deno,
  makeWrapper,
}:
python3Packages.buildPythonApplication rec {
  pname = "claude-real-video";
  version = "0.10.7";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "HUANGCHIHHUNGLeo";
    repo = "claude-real-video";
    rev = "ab4b9b2b23790f5d63a6d15165d3d8ba284c6023";
    hash = "sha256-zKttxLI4j5BUhohR5aeH6tqy5DZou2D6m7nLc348JSQ=";
  };

  build-system = with python3Packages; [ setuptools ];

  dependencies = with python3Packages; [
    yt-dlp
    pillow
    # Prefer faster-whisper ([fast] extra); openai-whisper (torch) is the fallback.
    faster-whisper
    mcp
    sherpa-onnx
    numpy
  ];

  nativeBuildInputs = [ makeWrapper ];

  # ffmpeg/ffprobe for frames + audio; deno for yt-dlp YouTube JS challenges.
  makeWrapperArgs = [
    "--prefix"
    "PATH"
    ":"
    (lib.makeBinPath [
      ffmpeg
      deno
    ])
  ];

  pythonImportsCheck = [
    "claude_real_video"
  ];

  # Upstream tests need network, models, and fixtures.
  doCheck = false;

  meta = {
    description = "Let any LLM watch a video via scene-aware keyframes and transcript";
    homepage = "https://github.com/HUANGCHIHHUNGLeo/claude-real-video";
    changelog = "https://github.com/HUANGCHIHHUNGLeo/claude-real-video/blob/master/CHANGELOG.md";
    license = lib.licenses.mit;
    mainProgram = "crv";
    platforms = lib.platforms.unix;
  };
}
