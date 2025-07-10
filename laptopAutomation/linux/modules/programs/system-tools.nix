{ config, pkgs, ... }:

{
  # System tools and utilities
  environment.systemPackages = with pkgs; [
    # System monitoring
    htop
    btop
    iotop
    nethogs
    bandwhich
    
    # Disk and filesystem tools
    parted
    gparted
    ncdu
    du-dust
    duf
    
    # Network tools
    nmap
    netcat
    tcpdump
    wireshark
    speedtest-cli
    
    # File utilities
    rsync
    rclone
    syncthing
    
    # System information
    lshw
    usbutils
    pciutils
    dmidecode
    
    # Process management
    killall
    psmisc
    
    # Text processing
    grep
    sed
    awk
    
    # Archive and compression
    gzip
    bzip2
    xz
    
    # Hardware tools
    lm_sensors
    smartmontools
    
    # Backup tools
    borgbackup
    restic
    
    # Security tools
    gnupg
    pass
    
    # System administration
    sudo
    systemd
    
    # Performance tools
    stress
    stress-ng
    
    # Virtualization
    qemu
    libvirt
    virt-manager
    
    # Container tools
    podman
    podman-compose
    
    # Version control
    git
    git-lfs
    
    # Package managers
    flatpak
    appimage-run
    
    # Fonts
    font-manager
    
    # Documentation
    man-pages
    man-pages-posix
    
    # Build tools
    gcc
    clang
    make
    cmake
    
    # Database tools
    sqlite
    postgresql
    
    # System cleanup
    bleachbit
    
    # Disk encryption
    cryptsetup
    
    # Time synchronization
    chrony
  ];

  # Enable services for system tools
  services = {
    # Hardware sensors
    thermald.enable = true;
    
    # Time synchronization
    chrony.enable = true;
    
    # Locate database
    locate = {
      enable = true;
      locate = pkgs.mlocate;
      localuser = null;
    };
    
    # Flatpak support
    flatpak.enable = true;
    
    # Printing
    printing = {
      enable = true;
      drivers = with pkgs; [ cups-filters ];
    };
    
    # CUPS for printing
    avahi = {
      enable = true;
      nssmdns4 = true;
    };
    
    # Firmware updates
    fwupd.enable = true;
    
    # Power management
    power-profiles-daemon.enable = true;
    
    # Automatic garbage collection
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
    
    # Optimize Nix store
    nix.optimise = {
      automatic = true;
      dates = [ "03:45" ];
    };
  };

  # Virtualization
  virtualisation = {
    libvirtd.enable = true;
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  # Hardware configuration
  hardware = {
    # CPU microcode
    cpu.intel.updateMicrocode = true; # Change to cpu.amd.updateMicrocode for AMD
    
    # Firmware
    enableRedistributableFirmware = true;
    
    # Sensor support
    sensor.hddtemp.enable = true;
  };
}