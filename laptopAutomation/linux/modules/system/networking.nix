{ config, pkgs, lib, userConfig, ... }:

{
  # ─── Network Configuration ────────────────────────────────────────────
  networking = {
    # System hostname
    hostName = userConfig.system.hostname or "nixos-laptop";
    
    # Enable NetworkManager for easy network management
    networkmanager = {
      enable = true;
      wifi = {
        powersave = false; # Disable WiFi power saving for better performance
        backend = "wpa_supplicant";
      };
      ethernet.macAddress = "preserve"; # Keep original MAC address
    };
    
    # ─── Firewall Configuration ───────────────────────────────────────────
    firewall = {
      enable = true;
      
      # Basic ports
      allowedTCPPorts = [ 
        22   # SSH
      ] ++ (userConfig.networking.allowedTCPPorts or []);
      
      allowedUDPPorts = userConfig.networking.allowedUDPPorts or [ ];
      
      # Port ranges for specific applications
      allowedTCPPortRanges = [
        { from = 1714; to = 1764; } # KDE Connect
      ] ++ (userConfig.networking.allowedTCPPortRanges or []);
      
      allowedUDPPortRanges = [
        { from = 1714; to = 1764; } # KDE Connect
      ] ++ (userConfig.networking.allowedUDPPortRanges or []);
      
      # Enable ping responses
      allowPing = true;
      
      # Log dropped packets (for debugging)
      logReversePathDrops = true;
    };
    
    # ─── DNS Configuration ────────────────────────────────────────────────
    nameservers = userConfig.networking.nameservers or [ 
      "1.1.1.1"     # Cloudflare
      "1.0.0.1"     # Cloudflare secondary
      "8.8.8.8"     # Google
      "8.8.4.4"     # Google secondary
    ];
    
    # Enable systemd-resolved for better DNS management
    resolvconf.enable = false;
    
    # Disable old wireless support (using NetworkManager instead)
    wireless.enable = false;
    
    # ─── Network Optimization ─────────────────────────────────────────────
    dhcpcd.enable = false; # Use NetworkManager's DHCP client
    useDHCP = false; # Managed by NetworkManager
  };

  # ─── SSH Configuration ────────────────────────────────────────────────
  services.openssh = {
    enable = userConfig.services.ssh.enable or true;
    
    settings = {
      # Security settings
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      
      # Performance settings
      X11Forwarding = false;
      AllowAgentForwarding = false;
      AllowTcpForwarding = false;
      
      # Connection settings
      ClientAliveInterval = 300;
      ClientAliveCountMax = 2;
      
      # Custom port if specified
      Port = userConfig.services.ssh.port or 22;
    };
    
    # Host keys
    hostKeys = [
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
      {
        path = "/etc/ssh/ssh_host_rsa_key";
        type = "rsa";
        bits = 4096;
      }
    ];
  };

  # ─── Network Services ─────────────────────────────────────────────────
  services = {
    # Enable systemd-resolved for better DNS handling
    resolved = {
      enable = true;
      dnssec = "true";
      domains = [ "~." ];
      fallbackDns = [ "1.1.1.1" "8.8.8.8" ];
      extraConfig = ''
        DNSOverTLS=yes
      '';
    };
    
    # Network Time Protocol
    timesyncd = {
      enable = true;
      servers = [ 
        "0.nixos.pool.ntp.org"
        "1.nixos.pool.ntp.org"
        "2.nixos.pool.ntp.org"
        "3.nixos.pool.ntp.org"
      ];
    };
  };

  # ─── Network Tools ────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    # Network diagnostics
    dig
    nmap
    iperf3
    tcpdump
    wireshark
    
    # Network management
    networkmanager-applet
    bluez-tools
  ];

  # Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;
}