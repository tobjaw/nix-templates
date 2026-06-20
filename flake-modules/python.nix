{
  flake-parts-lib,
  ...
}:
let
  inherit (flake-parts-lib) mkPerSystemOption;
in
_: {
  options.perSystem = mkPerSystemOption (_: {
    pre-commit = {
      settings = {
        excludes = [ ".venv" ];
        hooks = {
          ruff.enable = true;
          ruff-format.enable = true;
        };
      };
    };
  });
}
