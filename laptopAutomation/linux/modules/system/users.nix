{ config, pkgs, ... }:

{
  # User configuration
  users = {
    # Use mutable users (allows passwd command)
    mutableUsers = true;
    
    # Default shell
    defaultUserShell = pkgs.zsh;
    
    # User accounts
    users.damian = { # Replace "damian" with your username
      isNormalUser = true;
      description = "Damian"; # Replace with your full name
      extraGroups = [ 
        "wheel"        # Admin privileges
        "networkmanager" # Network management
        "audio"        # Audio devices
        "video"        # Video devices
        "docker"       # Docker (if enabled)
        "libvirtd"     # Virtual machines
        "input"        # Input devices
        "storage"      # Storage devices
        "optical"      # Optical drives
      ];
      
      # User packages (system-wide)
      packages = with pkgs; [
        firefox
        thunderbird
        libreoffice
        vlc
        gimp
        discord
        steam
        vscode
        obsidian
        spotify
      ];
    };
    
    # Root user configuration
    users.root = {
      hashedPassword = null; # Disable root login
    };
  };

  # Enable ZSH system-wide
  programs.zsh.enable = true;
  
  # Environment variables
  environment.variables = {
    EDITOR = "vim";
    BROWSER = "firefox";
  };
}