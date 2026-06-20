{
  flake-parts-lib,
  ...
}:
let
  inherit (flake-parts-lib) mkPerSystemOption;
in
_: {
  options.perSystem = mkPerSystemOption (
    { pkgs, ... }:
    {
      pre-commit = {
        settings = {
          excludes = [ "vendor" ];
          hooks = {
            gofmt.enable = true;
            golines.enable = true;
            golangci-lint = {
              enable = true;
              extraPackages = [ pkgs.go ];
            };
            govet.enable = true;
          };
        };
      };

    }
  );
}
