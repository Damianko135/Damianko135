{ config, pkgs, lib, inputs, userConfig, ... }:

{
  imports = [
    # Hardware configuration
    ./hardware-configuration.nix
    
    # System modules
    ./modules/system/boot.nix
    ./modules/system/locale.nix
    ./modules/system/networking.nix
    ./modules/system/security.nix
    ./modules/system/users.nix
    
    # Program modules
    ./modules/programs/editors.nix
    ./modules/programs/shell.nix
    ./modules/programs/system-tools.nix
    
    # Service modules
    ./modules/services/desktop.nix
    ./modules/services/development.nix
    ./modules/services/multimedia.nix
  ];

  # ─── Nix Configuration ────────────────────────────────────────────────
  nix = {
    settings = {
      # Enable flakes and modern Nix features
      experimental-features = [ "nix-command" "flakes" ];
      
      # Auto-optimize store for space savings
      auto-optimise-store = true;
      
      # Trusted users for remote builds and sudo access
      trusted-users = [ "root" "@wheel" ];
      
      # Enable sandbox for security
      sandbox = true;
      
      # Keep build logs for debugging
      keep-build-log = true;
      
      # Warn about dirty Git trees
      warn-dirty = false;
      
      # Keep derivations for better debugging
      keep-derivations = true;
      keep-outputs = true;
    };
    
    # Automatic garbage collection
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    
    # Registry for flake inputs (enables 'nix run nixpkgs#package')
    registry = lib.mapAttrs (_: value: { flake = value; }) inputs;
    
    # Add channels to NIX_PATH for legacy compatibility
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;
  };
  
  # ─── Package Configuration ────────────────────────────────────────────
  nixpkgs = {
    config = {
      # Allow unfree packages (required for many proprietary software)
      allowUnfree = true;
      
      # Don't allow broken packages by default
      allowBroken = false;
      
      # Don't allow insecure packages by default
      allowInsecure = false;
      
      # Configure permissions for specific packages if needed
      permittedInsecurePackages = [
        # Add specific packages here if needed
        # "package-name-version"
      ];
    };
    
    # System overlays for package customization
    overlays = [
      # Add overlays here for custom packages or modifications
      # inputs.some-overlay.overlays.default
    ];
  };

  # ─── System Environment ───────────────────────────────────────────────
  environment = {
    # Global environment variables
    variables = {
      EDITOR = lib.mkDefault "vim";
      BROWSER = lib.mkDefault "firefox";
      TERMINAL = lib.mkDefault "alacritty";
    };
    
    # Session variables (set for all users)
    sessionVariables = {
      # XDG Base Directory specification
      XDG_CACHE_HOME = "$HOME/.cache";
      XDG_CONFIG_HOME = "$HOME/.config";
      XDG_DATA_HOME = "$HOME/.local/share";
      XDG_STATE_HOME = "$HOME/.local/state";
    };
    
    # Essential system packages (keep minimal)
    systemPackages = with pkgs; [
      # Core system utilities
      wget
      curl
      git
      vim
      htop
      tree
      file
      which
      
      # Archive tools
      unzip
      zip
      p7zip
      
      # Network diagnostics
      dig
      nmap
      whois
      
      # Hardware information
      pciutils
      usbutils
      lshw
      
      # File system tools
      parted
      ntfs3g
    ];
  };

  # ─── Security Configuration ───────────────────────────────────────────
  security = {
    # Sudo configuration
    sudo = {
      enable = true;
      wheelNeedsPassword = true;
    };
    
    # PolicyKit for GUI privilege escalation
    polkit.enable = true;
    
    # Real-time kit for audio/video applications
    rtkit.enable = true;
  };

  # ─── Hardware Support ─────────────────────────────────────────────────
  hardware = {
    # Enable all firmware for maximum hardware compatibility
    enableAllFirmware = true;
    
    # Enable redistributable firmware
    enableRedistributableFirmware = true;
    
    # CPU microcode updates
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    
    # Graphics support
    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
    };
  };

  # ─── System Services ──────────────────────────────────────────────────
  services = {
    # Firmware updates
    fwupd.enable = true;
    
    # Printing support
    printing.enable = true;
    
    # Sound system (PipeWire is modern replacement for PulseAudio)
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
    
    # Disable old sound systems
    pulseaudio.enable = false;
    
    # Enable D-Bus
    dbus.enable = true;
    
    # Enable udev for device management
    udev.enable = true;
  };

  # ─── Boot Configuration ───────────────────────────────────────────────
  boot = {
    # Use latest kernel for better hardware support
    kernelPackages = pkgs.linuxPackages_latest;
    
    # Kernel parameters for better performance and quieter boot
    kernelParams = [
      "quiet"
      "splash"
      "vt.global_cursor_default=0"
    ];
    
    # Reduce boot verbosity
    consoleLogLevel = 0;
    initrd.verbose = false;
    
    # Faster boot timeout
    loader.timeout = 3;
  };

  # ─── Documentation ────────────────────────────────────────────────────
  documentation = {
    enable = true;
    nixos.enable = true;
    man.enable = true;
    info.enable = true;
  };

  # ─── System State Version ─────────────────────────────────────────────
  # DO NOT CHANGE this after initial installation
  # This is used for maintaining compatibility with stateful data
  system.stateVersion = "24.05";
}