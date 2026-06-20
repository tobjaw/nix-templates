{
  description = "TODO";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    nix-templates = {
      url = "github:tobjaw/nix-templates";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        taskfile-parts.follows = "taskfile-parts";
      };
    };
    taskfile-parts = {
      url = "github:tobjaw/taskfile-parts";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      flake-parts,
      nix-templates,
      taskfile-parts,
      ...
    }:

    flake-parts.lib.mkFlake { inherit inputs; } (
      { self, ... }:
      {
        imports = [
          nix-templates.flakeModules.git-hooks
          taskfile-parts.flakeModules.default
          nix-templates.flakeModules.common
          nix-templates.flakeModules.go
        ];
        systems = [
          "x86_64-linux"
          "aarch64-linux"
          "aarch64-darwin"
        ];
        perSystem =
          {
            pkgs,
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
