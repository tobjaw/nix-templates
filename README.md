# nix-templates

Collection of nix templates.

## Usage

Just copy template files:

```shell
# copy default template into cwd
nix flake init -t github:tobjaw/nix-templates

# copy Go template into cwd
nix flake init -t github:tobjaw/nix-templates#go

# ...
```

[Init](./init.sh) new project:

```shell
# init from default template into new temporary directory
nix run github:tobjaw/nix-templates

# init from Go template into new temporary directory
nix run github:tobjaw/nix-templates -- go

# init from Go template into cwd
nix run github:tobjaw/nix-templates -- go .

# ...
```
