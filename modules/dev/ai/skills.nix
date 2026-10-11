{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  inherit (lib)
    mkOption
    mkIf
    mapAttrs
    mapAttrs'
    nameValuePair
    mergeAttrsList
    literalExpression
    ;

  cfg = config.modules.dev.ai.skills;

  skillsEnabled =
    if lib.isPath cfg || lib.hm.strings.isPathLike cfg then
      true
    else if builtins.isAttrs cfg then
      cfg != { }
    else
      false;

  # Mirrors programs.codex.skills / home-manager codex/lib.nix.
  mkSkillDir =
    name: content:
    if lib.isPath content then
      pkgs.writeTextDir "SKILL.md" (builtins.readFile content)
    else if lib.hm.strings.isPathLike content then
      pkgs.runCommandLocal "ai-skill-${lib.strings.sanitizeDerivationName name}" { } ''
        source=${lib.escapeShellArg "${content}"}
        if [[ -d "$source" ]]; then
          ln -s "$source" "$out"
        elif [[ -f "$source" ]]; then
          mkdir -p "$out"
          cp "$source" "$out/SKILL.md"
        else
          echo "AI skill source '$source' is neither a file nor a directory" >&2
          exit 1
        fi
      ''
    else
      pkgs.writeTextDir "SKILL.md" content;

  mkSkillSources =
    skills:
    if !lib.hm.strings.isPathLike skills && builtins.isAttrs skills then
      skills
    else if lib.isPath skills && lib.pathIsDirectory skills then
      mapAttrs (name: _type: skills + "/${name}") (builtins.readDir skills)
    else
      { };

  mkSkillEntry =
    skillsDir: name: content:
    nameValuePair "${skillsDir}/${name}" {
      source =
        if lib.isPath content && lib.pathIsDirectory content then
          content
        else
          mkSkillDir name content;
    };

  mkSkillEntries =
    skillsDir: skills: mapAttrs' (mkSkillEntry skillsDir) (mkSkillSources skills);
in
{
  options.modules.dev.ai.skills = mkOption {
    # Prefer path over attrs: derivations are attrsets and would otherwise match
    # attrsOf (same issue as home-manager either(attrs, path) skills options).
    type = lib.types.either lib.types.path (
      lib.types.attrsOf (lib.types.either lib.types.lines lib.types.path)
    );
    default = { };
    description = ''
      Custom skills shared across AI agents (Codex, Claude Code, Cursor Agent,
      OpenCode). Same value shape as {option}`programs.codex.skills`.

      Skills are installed when this option is non-empty.

      This option can be either:
      - An attribute set defining skills
      - A path (or package such as {package}`pkgs.ai-skills`) to a directory
        containing skill folders

      If an attribute set is used, the attribute name becomes the skill
      directory name, and the value is either:
      - Inline content as a string (creates a generated skill directory at
        {file}`<skills-dir>/<name>/`)
      - A path to a file (creates a generated skill directory at
        {file}`<skills-dir>/<name>/`)
      - A path to a directory (symlinks {file}`<skills-dir>/<name>/` to that
        directory)

      If a path is used, it is expected to contain one folder per skill name,
      each containing a {file}`SKILL.md`. Each top-level skill entry is
      symlinked into {file}`<skills-dir>/`, leaving {file}`<skills-dir>/`
      itself as a normal directory so unmanaged skills can coexist.
    '';
    example = literalExpression ''
      {
        pdf-processing = '''
          ---
          name: pdf-processing
          description: Extract text from PDFs.
          ---

          # PDF Processing
        ''';
        data-analysis = ./skills/data-analysis;
      }
    '';
  };

  config = mkIf skillsEnabled {
    assertions = [
      {
        assertion = !lib.isPath cfg || lib.pathIsDirectory cfg;
        message = "`modules.dev.ai.skills` must be a directory when set to a path";
      }
    ];

    home-manager.users.${username} =
      { config, ... }:
      let
        homeRelative = path: lib.removePrefix "/" (lib.removePrefix config.home.homeDirectory path);

        xdgConfigHome = homeRelative config.xdg.configHome;

        # Match programs.codex skillsDir (XDG when preferXdgDirectories is set).
        codexSkillsDir =
          if config.home.preferXdgDirectories then "${xdgConfigHome}/codex/skills" else ".codex/skills";

        claudeSkillsDir = "${homeRelative config.programs.claude-code.configDir}/skills";
        cursorSkillsDir = ".cursor/skills";
        opencodeSkillsDir = "${xdgConfigHome}/opencode/skills";

        targets = lib.concatLists [
          (lib.optional config.programs.codex.enable codexSkillsDir)
          (lib.optional config.programs.claude-code.enable claudeSkillsDir)
          (lib.optional config.programs.cursor-agent.enable cursorSkillsDir)
          (lib.optional config.programs.opencode.enable opencodeSkillsDir)
        ];

        skillsArePath = lib.hm.strings.isPathLike cfg;
        skillsNeedNormalization = skillsArePath && !lib.isPath cfg;

        # Store-path skill roots can't be expanded at eval time; stage per-skill
        # symlinks like programs.codex.skills does.
        normalizedSkills = pkgs.runCommandLocal "ai-skills" { } ''
          source=${lib.escapeShellArg "${cfg}"}
          if [[ ! -d "$source" ]]; then
            echo "modules.dev.ai.skills must be a directory when set to a path" >&2
            exit 1
          fi

          mkdir -p "$out/stage" "$out/normalized"
          shopt -s dotglob nullglob
          for skill in "$source"/*; do
            name="''${skill##*/}"
            if [[ -d "$skill" ]]; then
              ln -s "$skill" "$out/stage/$name"
            elif [[ -f "$skill" ]]; then
              mkdir -p "$out/normalized/$name"
              cp "$skill" "$out/normalized/$name/SKILL.md"
              ln -s "$out/normalized/$name" "$out/stage/$name"
            else
              echo "AI skill source '$skill' is neither a file nor a directory" >&2
              exit 1
            fi
          done
        '';

        skillFilesFor =
          skillsDir:
          if skillsNeedNormalization then
            {
              "${skillsDir}" = {
                source = normalizedSkills + "/stage";
                recursive = true;
                ignorelinks = true;
              };
            }
          else
            mkSkillEntries skillsDir cfg;
      in
      {
        home.file = mergeAttrsList (map skillFilesFor targets);
      };
  };
}
