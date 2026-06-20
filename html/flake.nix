{
  description = "";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
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

    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        nix-tools.flakeModules.default
        nix-tools.flakeModules.git-hooks
        taskfile-parts.flakeModules.default
        nix-tools.flakeModules.javascript
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
                nodejs
                biome
              ];
              shellHook = config.pre-commit.installationScript;
            };
          };
        };
    };

}
