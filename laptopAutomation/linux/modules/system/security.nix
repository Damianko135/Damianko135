{ config, pkgs, ... }:

{
  # Security configuration
  security = {
    # Enable sudo
    sudo = {
      enable = true;
      wheelNeedsPassword = true;
    };
    
    # Polkit for privilege escalation
    polkit.enable = true;
    
    # Real-time kit for audio
    rtkit.enable = true;
    
    # AppArmor for additional security
    apparmor = {
      enable = true;
      killUnconfinedConfinables = true;
    };
    
    # PAM configuration
    pam.services = {
      login.enableGnomeKeyring = true;
      gdm.enableGnomeKeyring = true;
    };
  };

  # Enable GnuPG agent
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # Kernel security
  boot.kernel.sysctl = {
    "kernel.sysrq" = 1;
    "net.ipv4.ip_forward" = 0;
    "net.ipv6.conf.all.forwarding" = 0;
  };
}