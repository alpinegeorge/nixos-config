# nixos-config

NixOS flake configurations for multiple users.

## What this repo does

- Defines a shared NixOS system configuration
- Uses `disko` for disk layout and encryption
- Uses `home-manager` for per-user profiles
- Automatically nixos configurations for each user directory in `users/`

## Structure

- `flake.nix` — entry point and user config discovery
- `configuration.nix` — shared system settings
- `disko-config.nix` — disk and filesystem layout
- `users/<name>/configuration.nix` — NixOS user profile
- `users/<name>/home.nix` — Home Manager config for that user

## Usage

Add a new user by creating:

- `users/<name>/configuration.nix`
- `users/<name>/home.nix`

Then rebuild with the matching flake output.

## Notes

- `x86_64-linux` is the only supported target system for now.

