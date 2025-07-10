# Modular NixOS Configuration

This is a modular NixOS configuration that organizes system settings into logical modules for easier management and customization.

## Structure

```
├── flake.nix                 # Flake configuration with inputs and outputs
├── configuration.nix         # Main configuration that imports all modules
├── hardware-configuration.nix # Hardware-specific configuration
├── home.nix                  # Home Manager configuration
├── install-nix.yml           # Ansible playbook for installing Nix
├── modules/
│   ├── programs/             # Program-specific configurations
│   │   ├── editors.nix       # Text editors and IDEs
│   │   ├── shell.nix         # Shell tools and terminal emulators
│   │   └── system-tools.nix  # System utilities and tools
│   ├── services/             # Service configurations
│   │   ├── desktop.nix       # Desktop environment and GUI
│   │   ├── development.nix   # Development tools and services
│   │   └── multimedia.nix    # Media players and codecs
│   └── system/               # System-level configurations
│       ├── boot.nix          # Boot loader and kernel settings
│       ├── locale.nix        # Language and timezone settings
│       ├── networking.nix    # Network and firewall settings
│       ├── security.nix      # Security and authentication
│       └── users.nix         # User accounts and permissions
└── README.md                 # This file
```

## Quick Start

### 1. Initial Setup

You can use the provided script to automate the setup process:

```bash
# Make script executable (on Linux/WSL)
chmod +x run.sh

# Full automated setup (install Nix + setup configuration)
sudo ./run.sh

# Or install Nix only
sudo ./run.sh --install-nix

# Or setup configuration only (if Nix is already installed)
sudo ./run.sh --setup-config

# Get help
./run.sh --help
```

### 2. Manual Setup (Alternative)

If you prefer manual setup or the automated script doesn't work:

```bash
# If you need to install Nix first
ansible-playbook install-nix.yml
```

### 2. Customize Configuration

Before applying the configuration, you need to customize several files:

#### Update `flake.nix`

- Change `"laptop"` to your actual hostname
- Change `"damian"` to your actual username

#### Update `hardware-configuration.nix`

Replace the sample hardware configuration with your actual hardware configuration:

```bash
# Generate your hardware configuration
sudo nixos-generate-config --show-hardware-config > hardware-configuration.nix
```

#### Update `home.nix`

- Change `home.username` and `home.homeDirectory` to your actual username and home directory
- Update Git configuration with your name and email

#### Update `modules/system/users.nix`

- Change the username from `"damian"` to your actual username
- Update the user description
- Modify the package list as needed

#### Update `modules/system/locale.nix`

- Change the timezone to your location
- Modify locale settings if needed

#### Update `modules/system/networking.nix`

- Change the hostname to your preferred name
- Adjust firewall rules as needed

### 3. Apply Configuration

#### Using Flakes (Recommended)

```bash
# Build and switch to the new configuration
sudo nixos-rebuild switch --flake .#laptop

# Or just build without switching
sudo nixos-rebuild build --flake .#laptop
```

#### Traditional Method

```bash
# If not using flakes
sudo nixos-rebuild switch
```

### 4. Update System

```bash
# Update flake inputs
nix flake update

# Rebuild with updated packages
sudo nixos-rebuild switch --flake .#laptop
```

## Customization

### Adding New Modules

To add a new module:

1. Create a new `.nix` file in the appropriate directory under `modules/`
2. Add the module to the imports list in `configuration.nix`
3. Follow the existing module structure

Example module structure:

```nix
{ config, pkgs, ... }:

{
  # Module-specific configuration
  environment.systemPackages = with pkgs; [
    # packages
  ];

  # Services
  services = {
    # service configuration
  };

  # Programs
  programs = {
    # program configuration
  };
}
```

### Enabling/Disabling Features

Many features can be enabled or disabled by modifying the relevant module files:

- **Desktop Environment**: Edit `modules/services/desktop.nix`
- **Development Tools**: Edit `modules/services/development.nix`
- **Multimedia**: Edit `modules/services/multimedia.nix`

### Common Customizations

#### Change Desktop Environment

Edit `modules/services/desktop.nix`:

```nix
# Enable GNOME (default)
desktopManager.gnome.enable = true;

# Or enable KDE Plasma
# desktopManager.plasma5.enable = true;

# Or enable XFCE
# desktopManager.xfce.enable = true;
```

#### Add More Programs

Edit the relevant module file and add packages to `environment.systemPackages`:

```nix
environment.systemPackages = with pkgs; [
  # Add your packages here
  firefox
  vscode
  discord
];
```

#### Configure Services

Most services can be configured in their respective module files:

```nix
services.serviceName = {
  enable = true;
  # Additional configuration
};
```

## Useful Commands

```bash
# Rebuild system
sudo nixos-rebuild switch --flake .#laptop

# Update flake inputs
nix flake update

# Clean old generations
sudo nix-collect-garbage -d

# List generations
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Rollback to previous generation
sudo nixos-rebuild switch --rollback

# Check what changed
nix flake show

# Build without switching
sudo nixos-rebuild build --flake .#laptop

# Test configuration without making it default
sudo nixos-rebuild test --flake .#laptop
```

## Troubleshooting

### Common Issues

1. **Build Failures**: Check the error message and ensure all imports are correct
2. **Hardware Issues**: Make sure `hardware-configuration.nix` is properly configured
3. **Permission Issues**: Ensure you're running rebuild commands with `sudo`
4. **Missing Packages**: Check if the package name is correct in nixpkgs

### Debugging

```bash
# Check system logs
journalctl -f

# Check specific service logs
journalctl -u servicename

# Check Nix store
nix-store --verify --check-contents

# Repair Nix store
nix-store --repair --verify --check-contents
```

## Contributing

Feel free to customize this configuration for your needs. The modular structure makes it easy to:

- Add new modules
- Modify existing configurations
- Share modules with others
- Maintain different configurations for different machines

## Resources

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Nix Package Search](https://search.nixos.org/)
- [Home Manager Options](https://nix-community.github.io/home-manager/options.html)
- [NixOS Wiki](https://nixos.wiki/)
