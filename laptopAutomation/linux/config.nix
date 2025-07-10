# Central configuration file for easy customization
{
  # User configuration
  user = {
    name = "damian"; # Change this to your username
    fullName = "Damian"; # Change this to your full name
    email = "139293484+Damianko135@users.noreply.github.com"; # Change this to your email
  };

  # System configuration
  system = {
    hostname = "laptop"; # Change this to your hostname
    timezone = "Europe/Amsterdam"; # Change this to your timezone
    locale = "en_US.UTF-8"; # Change this to your locale
    keyMap = "us"; # Change this to your keyboard layout
  };

  # Hardware configuration
  hardware = {
    # Change based on your CPU
    cpu = "intel"; # "intel" or "amd"
    # Enable if you have a laptop
    laptop = true;
    # Enable if you have a GPU
    gpu = {
      enable = true;
      driver = "intel"; # "intel", "nvidia", "amd"
    };
  };

  # Desktop environment preference
  desktop = {
    # Choose one: "gnome", "kde", "xfce", "i3", "awesome"
    environment = "gnome";
    # Enable common desktop packages
    includeCommonApps = true;
  };

  # Development environment
  development = {
    # Enable development tools
    enable = true;
    # Programming languages to install
    languages = [ "python" "nodejs" "rust" "go" ];
    # IDEs to install
    ides = [ "vscode" "vim" ];
  };

  # Feature flags
  features = {
    # Enable gaming support
    gaming = true;
    # Enable multimedia codecs
    multimedia = true;
    # Enable virtualization
    virtualization = true;
    # Enable Docker
    docker = true;
  };
}