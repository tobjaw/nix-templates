{
  flake-parts-lib,
  ...
}:
let
  inherit (flake-parts-lib) mkPerSystemOption;
in
{
  self,
  ...
}:
{
  options.perSystem = mkPerSystemOption (
    { pkgs, config, ... }:
    {
      taskfile.shell.buildInputs = [ pkgs.pre-commit ];
      taskfile.shell.shellHook = config.pre-commit.installationScript;
      pre-commit = {
        settings = {
          src = self.outPath;
          hooks = {
            deadnix.enable = true;
            editorconfig-checker.enable = true;
            end-of-file-fixer.enable = true;
            nixfmt.enable = true;
            markdownlint = {
              enable = true;
              settings.configuration = {
                # MD013/line-length : Line length : https://github.com/DavidAnson/markdownlint/blob/v0.39.0/doc/md013.md
                MD013 = false;
              };
            };
            prettier = {
              enable = true;
              excludes = [ "flake.lock" ];
            };
            shellcheck = {
              enable = true;
              excludes = [ ".envrc" ];
            };
            statix.enable = true;
            trim-trailing-whitespace.enable = true;
          };
        };
      };
    }
  );
}
