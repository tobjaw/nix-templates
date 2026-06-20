{
  description = ''
    Collection of nix templates.

    Usage:
      nix flake init -t github:tobjaw/nix-templates#default
      nix flake init -t github:tobjaw/nix-templates#go
      ...
  '';

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
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
      git-hooks,
      taskfile-parts,
      ...
    }:

    flake-parts.lib.mkFlake { inherit inputs; } (
      {
        self,
        flake-parts-lib,
        ...
      }:
      let
        inherit (flake-parts-lib) importApply;
        importFlakeModule = p: importApply p { inherit flake-parts-lib; };
        commonModule = importFlakeModule ./flake-modules/common.nix;
      in
      {
        imports = [
          commonModule
          git-hooks.flakeModule
          taskfile-parts.flakeModules.default
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
          python = {
            description = "Python application (uv2nix)";
            path = ./python;
          };
        };
        flake.flakeModules = {
          git-hooks = git-hooks.flakeModule;
          common = commonModule;
          go = importFlakeModule ./flake-modules/go.nix;
          javascript = importFlakeModule ./flake-modules/javascript.nix;
          python = importFlakeModule ./flake-modules/python.nix;
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
            taskfile = {
              enable = true;
              path = ./Taskfile.yml;
              shell = {
                buildInputs = [ init ];
              };
            };
            packages = {
              inherit init;
              default = init;
            };
          };
      }
    );

}
