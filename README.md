# Dotfiles

dotfilesです。

## Setup

### Windows

```powershell
winget install jdx.mise
git clone https://github.com/sotiak/dotfiles
cd dotfiles
mise trust
mise bootstrap --only dotfiles --dry-run
mise bootstrap --only dotfiles
```

### Standalone with Home Manager

**Pre-requirements**: Install [Nix](https://nixos.org/download/) and [Home Manager (Standalone)](https://nix-community.github.io/home-manager/index.xhtml).

Deliver dotfiles.

```plaintext
home-manager switch --experimental-features "nix-command flakes" --flake ~/dotfiles#sk@wsl
```

For an Intel Mac, use the `sk@mbp-a2159` profile. Accept the flake's cache configuration so Nix can use Cachix:

```plaintext
home-manager switch --experimental-features "nix-command flakes" --accept-flake-config --flake ~/dotfiles#sk@mbp-a2159
```

The Intel profile uses Nixpkgs and Home Manager 26.05, the final release line supporting `x86_64-darwin`.

Renovate updates `flake.lock` daily and opens a pull request; CI builds both the WSL and Intel Mac profiles before it is merged.

Change default shell.

```plaintext
which zsh | sudo tee -a /etc/shells
chsh -s $(which zsh)
```

### NixOS-WSL

Install [NixOS-WSL](https://nix-community.github.io/NixOS-WSL/index.html).

Clone, bootstrapping.

```plaintext
nix --extra-experimental-features 'nix-command flakes' shell nixpkgs#git -c git clone https://github.com/sotiak/dotfiles
cd dotfiles
sudo nixos-rebuild switch --flake .#wsl
```

## Structure / Tech Stack

Flake structure: [numtide/blueprint](https://numtide.github.io/blueprint/main/)

- `nix/hosts/`: Linux host configurations and standalone Home Manager users, following Blueprint's folder structure.
- `nix/darwin/`: Intel Mac Blueprint root, isolated to use the final Nixpkgs/Home Manager releases that support `x86_64-darwin`.
- `nix/modules/`: shared and private-only Home Manager modules, plus reusable NixOS modules.
- `nix/packages/`: locally defined packages.
- `nix/`: Blueprint formatter and development shell definitions.

- `bootstrap/`: Initial setup scripts for tools that remain outside Home Manager.
- `config/`: Source files linked into platform config locations by Home Manager and mise.
- `docs/`: Operational notes for manual procedures.
- `keys/`: Public key material that is safe to keep in the repository.
