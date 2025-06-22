{
  description = "";

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

    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        nix-tools.flakeModules.default
        nix-tools.flakeModules.git-hooks
        nix-tools.flakeModules.devshell
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
            commands = [
              {
                name = "build";
                help = "build project";
                command = "echo TODO && exit 1";
              }
              {
                name = "run";
                help = "run project";
                command = "hello && exit 1";
              }
              {
                name = "tests";
                help = "test project";
                command = "echo TODO && exit 1";
              }
              {
                name = "lint";
                help = "lint project";
                command = "nix flake check";
              }
            ];
            packages = with pkgs; [
              hello
            ];
            devshell.startup.pre-commit.text = ''
              ${config.pre-commit.installationScript}
            '';
          };

        };
    };

}
