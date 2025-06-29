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
          system,
          config,
          ...
        }:
        {
          devshells.default = {
            commands = [
              {
                name = "build";
                help = "build";
                command = "nix build .#";
              }
              {
                name = "run";
                help = "run";
                command = "nix run .#";
              }
              {
                name = "lint";
                help = "lint project";
                command = "pre-commit run --all-files";
              }
            ];
            devshell.startup.pre-commit.text = ''
              ${config.pre-commit.installationScript}
            '';

          };
          packages = rec {
            # nix run .#example
            example =
              let
                name = "example";
                buildInputs = with pkgs; [ cowsay ];
                script = (pkgs.writeScriptBin name (builtins.readFile ./example.sh)).overrideAttrs (prev: {
                  buildCommand = "${prev.buildCommand} patchShebangs $out";
                });
              in
              pkgs.symlinkJoin {
                inherit name system;
                paths = [ script ] ++ buildInputs;
                buildInputs = [ pkgs.makeWrapper ];
                postBuild = ''
                  wrapProgram \
                    $out/bin/${name} \
                    --prefix PATH : $out/bin'';
              };
            # nix run (or nix run .#default)
            default = example;
          };
        };
    };

}
