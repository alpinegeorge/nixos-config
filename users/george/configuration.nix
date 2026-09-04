# users/george/configuration.nix
{ pkgs, ... }: {
  users.users.george = {
    isNormalUser = true;
    description = "George";
    extraGroups = [
      "audio"
      "docker"
      "networkmanager"
      "video"
      "wheel"
    ];
    initialPassword = "changeme";
    packages = with pkgs; [
      awscli
      clang
      direnv
      discord
      docker
      ghostty
      git
      github-cli
      htop
      mold
      ripgrep
      rustup
      sccache
      unrar
      unzip
      vscode
      xclip
    ];
  };

  # Desktop Environment
  services.displayManager.cosmic-greeter.enable = true;
  services.desktopManager.cosmic.enable = true;

  # Configure X11
  services.xserver = {
    enable = true;
    xkb = {
      layout = "gb";
      variant = "";
    };
  };

  # Configure keymap
  console.keyMap = "uk";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Setup docker virtualisation
  virtualisation.docker = {
    enable = true;
    storageDriver = "btrfs";
  };

  # Enable passwordless sudo for users in the wheel group
  security.sudo.wheelNeedsPassword = false;

  # Setup OpenPGP
  programs.gnupg.agent.enable = true;

  # Setup Neovim and tmux
  programs.neovim.enable = true;
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      # Headless browser dependencies
      atk
      cairo
      dbus
      expat
      fontconfig
      gcc
      gio-sharp
      glib
      gtk3
      libgbm
      libx11
      libxcb
      libxcomposite
      libxcursor
      libxdamage
      libxext
      libxfixes
      libxkbcommon
      libxrandr
      libxrender
      libxft
      libxi
      nspr
      nss
      pango
      rubyPackages.gdk3
    ];
  };
  programs.tmux.enable = true;

  # Setup user environment
  environment = {
    shellAliases = {
      rebuild-system = "sudo nixos-rebuild switch --flake /etc/nixos#george";
      update-system = "sudo nix flake update /etc/nixos && sudo nixos-rebuild switch --flake /etc/nixos#george";
    };
  };

  # Setup binary symlinks
  system.activationScripts = {
    usrbin-symlinks = ''
      mkdir -p /usr/bin
      ln -sfn ${pkgs.clang}/bin/clang /usr/bin/clang
      ln -sfn ${pkgs.mold}/bin/mold /usr/bin/mold
    '';
  };
}
