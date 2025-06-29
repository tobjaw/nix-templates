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
          devshells.default = {
            commands = [
              {
                name = "build";
                help = "build project";
                command = "npm run build";
              }
              {
                name = "run";
                help = "run project";
                command = "npm start";
              }
              {
                name = "tests";
                help = "test project";
                command = "npm run test";
              }
              {
                name = "lint";
                help = "lint project";
                command = "pre-commit run --all-files";
              }
              {
                name = "lint_fix";
                help = "fix linting issues";
                command = "biome check --fix --unsafe";
              }
            ];
            packages = with pkgs; [
              nodejs
              biome
            ];
            devshell.startup.pre-commit.text = ''
              ${config.pre-commit.installationScript}
            '';
          };

        };
    };

}
