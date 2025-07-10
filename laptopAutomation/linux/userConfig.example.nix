# User Configuration Example
# This file shows the structure that userConfig should have
# You can customize these values based on your preferences

{
  # ─── System Configuration ─────────────────────────────────────────────
  system = {
    hostname = "nixos-laptop";
  };

  # ─── Hardware Configuration ───────────────────────────────────────────
  hardware = {
    cpu = "intel"; # "intel" or "amd"
    gpu = {
      enable = true;
      driver = "intel"; # "intel", "amd", "nvidia", or "nouveau"
    };
  };

  # ─── Locale Configuration ─────────────────────────────────────────────
  locale = {
    default = "en_US.UTF-8";
    additional = [ "nl_NL.UTF-8" ]; # Additional locales
    timeZone = "Europe/Amsterdam";
    keyboardLayout = "us";
    keyboardVariant = "";
    keyboardOptions = "grp:alt_shift_toggle";
    keyMap = "us";
    consoleFont = "Lat2-Terminus16";
  };

  # ─── User Configuration ───────────────────────────────────────────────
  users = {
    mainUser = {
      name = "damian";
      description = "Damian";
      isAdmin = true;
      shell = "zsh"; # "bash", "zsh", "fish"
    };
  };

  # ─── Networking Configuration ─────────────────────────────────────────
  networking = {
    allowedTCPPorts = [ 80 443 ];
    allowedUDPPorts = [ ];
    allowedTCPPortRanges = [ ];
    allowedUDPPortRanges = [ ];
    nameservers = [ "1.1.1.1" "1.0.0.1" "8.8.8.8" "8.8.4.4" ];
  };

  # ─── Services Configuration ───────────────────────────────────────────
  services = {
    ssh = {
      enable = true;
      port = 22;
    };
    desktop = {
      enable = true;
      environment = "gnome"; # "gnome", "kde", "xfce", "i3"
    };
  };

  # ─── Programs Configuration ───────────────────────────────────────────
  programs = {
    development = {
      enable = true;
      languages = [ "python" "javascript" "rust" "go" ];
    };
    gaming = {
      enable = false;
      steam = false;
    };
    multimedia = {
      enable = true;
      video = true;
      audio = true;
    };
  };
}
