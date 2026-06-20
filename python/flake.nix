{
  description = "Python application (uv2nix)";

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

    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs = {
        pyproject-nix.follows = "pyproject-nix";
        nixpkgs.follows = "nixpkgs";
      };
    };
    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs = {
        pyproject-nix.follows = "pyproject-nix";
        uv2nix.follows = "uv2nix";
        nixpkgs.follows = "nixpkgs";
      };
    };
  };

  outputs =
    inputs@{
      flake-parts,
      nix-templates,
      taskfile-parts,
      pyproject-nix,
      uv2nix,
      pyproject-build-systems,
      nixpkgs,
      ...
    }:

    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        nix-templates.flakeModules.git-hooks
        nix-templates.flakeModules.common
        nix-templates.flakeModules.python
        taskfile-parts.flakeModules.default
      ];
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      perSystem =
        {
          config,
          pkgs,
          ...
        }:
        let
          inherit (nixpkgs) lib;

          workspace = uv2nix.lib.workspace.loadWorkspace { workspaceRoot = ./.; };

          overlay = workspace.mkPyprojectOverlay { sourcePreference = "wheel"; };

          python = pkgs.python3;

          # Override build systems for packages that need sdist builds.
          # Pattern (Method 2 from uv2nix docs):
          #   some-package = prev.some-package.overrideAttrs (old: {
          #     nativeBuildInputs = old.nativeBuildInputs ++ final.resolveBuildSystem { ... };
          #   });
          pyprojectOverrides = _final: _prev: { };

          pythonSet = (pkgs.callPackage pyproject-nix.build.packages { inherit python; }).overrideScope (
            lib.composeManyExtensions [
              pyproject-build-systems.overlays.wheel
              overlay
              pyprojectOverrides
            ]
          );

          editableOverlay = workspace.mkEditablePyprojectOverlay { root = "$REPO_ROOT"; };
          # hatchling needs `editables` at build time for editable wheel construction
          editablePythonSet = pythonSet.overrideScope (
            lib.composeManyExtensions [
              editableOverlay
              (final: _prev: {
                example = _prev.example.overrideAttrs (old: {
                  nativeBuildInputs = old.nativeBuildInputs ++ final.resolveBuildSystem { editables = [ ]; };
                });
              })
            ]
          );

          virtualenv = pythonSet.mkVirtualEnv "example-env" workspace.deps.default;
          editableVenv = editablePythonSet.mkVirtualEnv "example-dev-env" workspace.deps.all;
        in
        {
          taskfile = {
            enable = true;
            path = ./Taskfile.yml;
          };

          devShells.default = pkgs.mkShell {
            buildInputs = [
              pkgs.go-task
              editableVenv
              pkgs.uv
              pkgs.pre-commit
            ];
            env = {
              UV_NO_SYNC = "1";
              UV_PYTHON = python.interpreter;
              UV_PYTHON_DOWNLOADS = "never";
            };
            shellHook = ''
              ${config.pre-commit.installationScript}
              unset PYTHONPATH
              export REPO_ROOT=$(git rev-parse --show-toplevel)
              ${config.taskfile.shellHookText}
            '';
          };

          packages.default = virtualenv;
        };
    };

}
