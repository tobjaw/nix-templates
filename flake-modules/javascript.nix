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
        excludes = [
          "node_packages"
          "package-lock.json"
        ];
        hooks = {
          biome.enable = true;
        };
      };
    };
  });
}
