{ config, pkgs, lib, userConfig, ... }:

{
  # ─── Internationalization ─────────────────────────────────────────────
  i18n = {
    defaultLocale = userConfig.locale.default or "en_US.UTF-8";
    
    # Additional locale settings for consistency
    extraLocaleSettings = {
      LC_ADDRESS = userConfig.locale.default or "en_US.UTF-8";
      LC_IDENTIFICATION = userConfig.locale.default or "en_US.UTF-8";
      LC_MEASUREMENT = userConfig.locale.default or "en_US.UTF-8";
      LC_MONETARY = userConfig.locale.default or "en_US.UTF-8";
      LC_NAME = userConfig.locale.default or "en_US.UTF-8";
      LC_NUMERIC = userConfig.locale.default or "en_US.UTF-8";
      LC_PAPER = userConfig.locale.default or "en_US.UTF-8";
      LC_TELEPHONE = userConfig.locale.default or "en_US.UTF-8";
      LC_TIME = userConfig.locale.default or "en_US.UTF-8";
    };
    
    # Support additional locales if specified
    supportedLocales = [ 
      (userConfig.locale.default or "en_US.UTF-8")
    ] ++ (userConfig.locale.additional or []);
  };

  # ─── Console Configuration ────────────────────────────────────────────
  console = {
    font = userConfig.locale.consoleFont or "Lat2-Terminus16";
    keyMap = userConfig.locale.keyMap or "us";
    useXkbConfig = true; # Use X11 keymap configuration
  };

  # ─── Time Zone ────────────────────────────────────────────────────────
  time.timeZone = userConfig.locale.timeZone or "Europe/Amsterdam";

  # ─── Keyboard Layout ──────────────────────────────────────────────────
  services.xserver.xkb = {
    layout = userConfig.locale.keyboardLayout or "us";
    variant = userConfig.locale.keyboardVariant or "";
    options = userConfig.locale.keyboardOptions or "grp:alt_shift_toggle";
  };

  # ─── Fonts ────────────────────────────────────────────────────────────
  fonts = {
    enable = true;
    
    # Font directories
    fontDir.enable = true;
    
    # Default fonts
    packages = with pkgs; [
      # Core fonts
      dejavu_fonts
      liberation_ttf
      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji
      
      # Programming fonts
      (nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" "JetBrainsMono" ]; })
      
      # Additional fonts
      ubuntu_font_family
      open-sans
      roboto
      
      # Microsoft fonts (if unfree is allowed)
    ] ++ lib.optionals config.nixpkgs.config.allowUnfree [
      corefonts
      vistafonts
    ];
    
    # Font configuration
    fontconfig = {
      enable = true;
      antialias = true;
      hinting.enable = true;
      hinting.style = "slight";
      subpixel.rgba = "rgb";
      
      # Default fonts
      defaultFonts = {
        serif = [ "Noto Serif" "DejaVu Serif" ];
        sansSerif = [ "Noto Sans" "DejaVu Sans" ];
        monospace = [ "JetBrainsMono Nerd Font" "FiraCode Nerd Font" "DejaVu Sans Mono" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };
    layout = "us";
    variant = "";
  };
}