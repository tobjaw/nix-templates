{
  description = ''
    Collection of nix templates.

    Usage:
      nix flake init -t github:tobjaw/nix-templates#default
      nix flake init -t github:tobjaw/nix-templates#go
      ...
  '';

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
        ];
        flake.templates = {
          default = {
            description = "Generic boilerplate";
            path = ./default;
          };
          go = {
            description = "Go CLI Application";
            path = ./go;
          };
          bash = {
            description = "Shell script";
            path = ./bash;
          };
          html = {
            description = "Vanilla HTML";
            path = ./html;
          };
        };
        systems = [
          "x86_64-linux"
          "aarch64-linux"
          "aarch64-darwin"
        ];
        perSystem =
          {
            system,
            pkgs,
            config,
            ...
          }:
          let
            init =
              let
                name = "init";
                buildInputs = with pkgs; [ nix ];
                script = (pkgs.writeScriptBin name (builtins.readFile ./init.sh)).overrideAttrs (prev: {
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
                    --prefix PATH : $out/bin \
                    --set FLAKE ${self}'';
              };
          in
          {
            devshells.default = {
              commands = [
                {
                  name = "init";
                  help = "init a new project in the current working directory";
                  package = init;
                }
                {
                  name = "lint";
                  help = "lint project";
                  command = "nix flake check";
                }
              ];
              devshell.startup.pre-commit.text = ''
                ${config.pre-commit.installationScript}
              '';
            };
            packages = {
              inherit init;
              default = init;
            };
          };
      }
    );

}
