{
  description = "TODO";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    nix-tools = {
      url = "github:tobjaw/nix-tools";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      flake-parts,
      nix-tools,
      ...
    }:

    flake-parts.lib.mkFlake { inherit inputs; } (
      { self, ... }:
      {
        imports = [
          nix-tools.flakeModules.default
          nix-tools.flakeModules.git-hooks
          nix-tools.flakeModules.devshell
          nix-tools.flakeModules.go
        ];
        systems = [
          "x86_64-linux"
          "aarch64-linux"
          "aarch64-darwin"
        ];
        perSystem =
          {
            pkgs,
            config,
            ...
          }:
          {
            devshells.default = {
              env = [
                {
                  name = "HTTP_PORT";
                  value = 8080;
                }
              ];
              commands = [
                {
                  name = "build";
                  help = "compile go code into executable";
                  command = "go build";
                }
                {
                  name = "run";
                  help = "run";
                  command = "build && ./example -log.level=debug";
                }
                {
                  name = "tests";
                  help = "test project";
                  command = "go test -v ./... -failfast";
                }
                {
                  name = "lint";
                  help = "lint project";
                  command = "nix flake check";
                }
              ];
              packages = with pkgs; [
                go
                gopls
              ];
              devshell.startup.pre-commit.text = ''
                ${config.pre-commit.installationScript}
              '';
            };

            packages = rec {
              default = example;
              example = pkgs.buildGoModule {
                pname = "example";
                version = builtins.substring 0 8 self.lastModifiedDate;
                src = pkgs.nix-gitignore.gitignoreSource [ ] ./.;
                vendorHash = null;
              };
            };
          };
      }
    );

}
