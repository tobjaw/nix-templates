# AGENTS.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a collection of Nix flake templates for bootstrapping new projects. The repository contains multiple template directories (default, go, bash, html), each providing a complete project structure with Nix flake configuration using flake-parts and nix-tools.

## Commands

### Build and Test

```bash
# Lint the repository (runs pre-commit hooks on all files)
nix flake check

# Test init script with default template
nix run . -- default .

# Test a specific template initialization
nix run . -- go /tmp/test-dir
```

### Development Shell

When working in a development shell (`nix develop` or via direnv), tasks are available via the `task` command:

- `task lint` - Lint the project (runs `nix flake check`)
- `task init` - Initialize a new project in the current directory

Tasks are also available as Nix apps:

- `nix run .#lint` - Run lint task
- `nix run .#init` - Run init task

## Architecture

### Root Flake Structure

The root `flake.nix` uses flake-parts and defines:

- **Templates export**: Each subdirectory (default, go, bash, html) is exposed as a flake template via `flake.templates`
- **Init package**: The `init.sh` script is wrapped as a Nix package that handles project initialization. It's injected with the FLAKE environment variable pointing to this repository
- **Shared inputs**: All templates follow nixpkgs 26.05 and depend on:
  - tobjaw/nix-tools for common flake modules
  - tobjaw/taskfile-parts for task runner integration

### Template Pattern

All templates follow a consistent structure:

- Use flake-parts for modular flake configuration
- Import nix-tools flake modules for common functionality:
  - `nix-tools.flakeModules.default` - Base module
  - `nix-tools.flakeModules.git-hooks` - Pre-commit hook integration
  - Language-specific modules (e.g., `go`, `javascript`)
- Import taskfile-parts for task runner integration:
  - `taskfile-parts.flakeModules.default` - Task runner module
- Define tasks in `Taskfile.yml` (using go-task format): `build`, `run`, `tests`, `lint`
- Configure shell environment via `shell.buildInputs` and `shell.env`
- Support three architectures: x86_64-linux, aarch64-linux, aarch64-darwin

### Init Script (init.sh)

The init script automates new project creation:

1. Creates a git repository in the target directory
2. Initializes the selected template via `nix flake init -t`
3. Enables and reloads direnv for immediate development shell activation

### Template-Specific Details

**Go template**:

- Imports `nix-tools.flakeModules.go`
- Provides `buildGoModule` package configuration
- Uses `vendorHash = null` for Go modules

**Bash template**:

- Wraps shell scripts with `writeScriptBin` and patches shebangs
- Uses `symlinkJoin` to combine script with runtime dependencies
- Uses `wrapProgram` to set PATH for dependencies

**HTML template**:

- Imports `nix-tools.flakeModules.javascript`
- Configured for biome linting with `lint_fix` command
- Uses npm for build/run/test commands

**Default template**:

- Minimal boilerplate with placeholder commands
- Starting point for custom project types

## Working with Templates

When modifying templates:

- Template changes affect the files that will be copied to new projects
- Each template's `flake.nix` should maintain consistency with the template pattern
- Each template includes a `Taskfile.yml` defining available tasks in go-task format
- Pre-commit hooks are automatically installed via `shell.shellHook = config.pre-commit.installationScript`
- Tasks are automatically exposed as Nix apps via `taskfile.generatePackages = true`
- The `flake.lock` files in templates should be kept in sync with dependency updates
