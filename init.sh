#!/usr/bin/env bash

set -euo pipefail

template=${1:-}
target_dir=${2:-}

if [[ -z "${template}" ]]; then
	template=default
fi

if [[ -z "${target_dir}" ]]; then
	target_dir=$(mktemp -d)
fi

cd "${target_dir}"
git init .
nix flake init --refresh -t "github:tobjaw/nix-templates#${template}"
direnv allow
direnv reload
