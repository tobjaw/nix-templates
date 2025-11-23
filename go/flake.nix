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
    taskfile-parts = {
      url = "github:tobjaw/taskfile-parts";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      flake-parts,
      nix-tools,
      taskfile-parts,
      ...
    }:

    flake-parts.lib.mkFlake { inherit inputs; } (
      { self, ... }:
      {
        imports = [
          nix-tools.flakeModules.default
          nix-tools.flakeModules.git-hooks
          taskfile-parts.flakeModules.default
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
            taskfile = {
              enable = true;
              path = ./Taskfile.yml;
              shell = {
                buildInputs = with pkgs; [
                  go
                  gopls
                ];
                env.HTTP_PORT = "8080";
                shellHook = config.pre-commit.installationScript;
              };
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
