{ config, pkgs, lib, userConfig, ... }:

{
  # ─── Boot Loader Configuration ────────────────────────────────────────
  boot = {
    # Use the systemd-boot EFI boot loader
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 10; # Keep only 10 boot entries
        editor = false; # Disable editor for security
      };
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
      timeout = 3; # Faster boot timeout
    };
    
    # ─── Kernel Configuration ─────────────────────────────────────────────
    # Use latest kernel for better hardware support
    kernelPackages = pkgs.linuxPackages_latest;
    
    # Kernel parameters
    kernelParams = [
      "quiet"
      "splash"
      "vt.global_cursor_default=0"
      "mitigations=auto"
      "elevator=mq-deadline"
    ];
    
    # ─── Boot Splash ──────────────────────────────────────────────────────
    plymouth = {
      enable = true;
      theme = "breeze";
    };
    
    # ─── Kernel Modules ───────────────────────────────────────────────────
    kernelModules = [ 
      # KVM virtualization support
      (if userConfig.hardware.cpu or "intel" == "amd" then "kvm-amd" else "kvm-intel")
    ];
    
    # ─── Initial RAM Disk ─────────────────────────────────────────────────
    initrd = {
      verbose = false;
      availableKernelModules = [
        "xhci_pci"
        "ahci"
        "nvme"
        "usbhid"
        "sd_mod"
        "sr_mod"
      ];
    };
    
    # ─── Console and Temporary Files ──────────────────────────────────────
    consoleLogLevel = 0;
    tmp = {
      useTmpfs = true;
      tmpfsSize = "50%";
    };
  };

  # ─── Hardware Acceleration ────────────────────────────────────────────
  hardware.opengl = {
    enable = userConfig.hardware.gpu.enable or true;
    driSupport = true;
    driSupport32Bit = true;
    
    # NVIDIA specific packages
    extraPackages = with pkgs; lib.optionals (userConfig.hardware.gpu.driver or "" == "nvidia") [
      nvidia-vaapi-driver
      vaapiVdpau
      libvdpau-va-gl
    ];
  };

  # ─── Video Drivers ────────────────────────────────────────────────────
  services.xserver.videoDrivers = lib.mkIf (userConfig.hardware.gpu.driver or "" == "nvidia") [ "nvidia" ];
  
  # ─── NVIDIA Configuration ─────────────────────────────────────────────
  hardware.nvidia = lib.mkIf (userConfig.hardware.gpu.driver or "" == "nvidia") {
    # Use the open source version of the kernel module
    open = false;
    
    # Enable the Nvidia settings menu
    nvidiaSettings = true;
    
    # Select the appropriate driver version
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    
    # Power management (experimental)
    powerManagement = {
      enable = false;
      finegrained = false;
    };
    
    # Modesetting required for Wayland
    modesetting.enable = true;
  };
}