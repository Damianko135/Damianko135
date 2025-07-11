{ config, pkgs, ... }:

{
  # Desktop environment and window manager
  services.xserver = {
    enable = true;
    
    # Display manager
    displayManager.gdm.enable = true;
    
    # Desktop environment - choose one
    desktopManager.gnome.enable = true;
    # desktopManager.plasma6.enable = true;  # Updated from plasma5
    # desktopManager.xfce.enable = true;
    # desktopManager.mate.enable = true;
    
    # Window managers (alternative to DE)
    # windowManager.i3.enable = true;
    # windowManager.awesome.enable = true;
    
    # Touchpad support
    libinput.enable = true;
  };

  # Audio
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Fonts
  fonts = {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji
      liberation_ttf
      fira-code
      fira-code-symbols
      # mplus-outline-fonts.githubRelease  # Comment out if causing issues
      dina-font
      proggyfonts
      font-awesome
      powerline-fonts
      (nerdfonts.override { fonts = [ "FiraCode" "DejaVuSansMono" ]; })
    ];
    
    fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = [ "Fira Code" "Liberation Mono" ];
        sansSerif = [ "Noto Sans" "Liberation Sans" ];
        serif = [ "Noto Serif" "Liberation Serif" ];
      };
    };
  };

  # Desktop packages
  environment.systemPackages = with pkgs; [
    # File managers
    nautilus
    thunar
    
    # Archive managers
    file-roller
    ark
    
    # Image viewers
    eog
    gwenview
    
    # PDF viewers
    evince
    okular
    
    # Terminal emulators
    gnome-terminal
    konsole
    
    # System monitors
    gnome-system-monitor
    
    # Calculator
    gnome-calculator
    
    # Text editors
    gedit
    kate
    
    # Screenshot tools
    gnome-screenshot
    flameshot
    
    # Color picker
    gcolor3
    
    # Clipboard manager
    clipit
    
    # Desktop themes
    gnome-themes-extra
    
    # GTK themes
    arc-theme
    numix-gtk-theme
    
    # Icon themes
    papirus-icon-theme
    numix-icon-theme
    
    # Cursor themes
    vanilla-dmz
    
    # Wallpapers
    gnome-backgrounds
    
    # Desktop utilities
    dconf-editor
    
    # Notification daemon
    dunst
    
    # System tray
    stalonetray
    
    # Application launcher
    rofi
    dmenu
    
    # Compositor (for window managers)
    picom
    
    # Screen locker
    i3lock
    
    # Desktop widgets
    conky
    
    # Wallpaper setter
    feh
    nitrogen
  ];

  # GNOME specific configuration
  services.gnome = {
    core-developer-tools.enable = true;
    gnome-keyring.enable = true;
  };

  # Exclude some GNOME applications
  environment.gnome.excludePackages = with pkgs; [
    gnome-photos
    gnome-tour
    cheese # webcam tool
    gnome-music
    epiphany # web browser
    geary # email reader
    gnome-characters
    tali # poker game
    iagno # go game
    hitori # sudoku game
    atomix # puzzle game
  ];

  # XDG Desktop Portal
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
    ];
  };

  # Location services
  services.geoclue2.enable = true;
  
  # Thumbnail generation
  services.tumbler.enable = true;
  
  # Desktop search
  services.gnome.tracker.enable = true;
  services.gnome.tracker-miners.enable = true;
  
  # Evolution data server (for calendar, contacts, etc.)
  services.gnome.evolution-data-server.enable = true;
  
  # Online accounts
  services.gnome.gnome-online-accounts.enable = true;
  
  # Remote desktop
  services.gnome.gnome-remote-desktop.enable = true;
}