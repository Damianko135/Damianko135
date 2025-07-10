{ config, pkgs, lib, inputs, userConfig, ... }:

{
  # ─── Home Manager Basic Configuration ─────────────────────────────────
  home = {
    username = userConfig.users.mainUser.name;
    homeDirectory = "/home/${userConfig.users.mainUser.name}";
    stateVersion = "24.05";
  };

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  # ─── User Packages ────────────────────────────────────────────────────
  home.packages = with pkgs; [
    # ─── Development Tools ─────────────────────────────────────────────
    git
    curl
    wget
    tree
    htop
    btop
    neofetch
    fastfetch
    
    # ─── Text Editors ─────────────────────────────────────────────────
    vim
    nano
    
    # ─── Archive Tools ─────────────────────────────────────────────────
    unzip
    zip
    p7zip
    rar
    unrar
    
    # ─── File Management ──────────────────────────────────────────────
    ranger
    fd
    ripgrep
    fzf
    
    # ─── Network Tools ────────────────────────────────────────────────
    dig
    nmap
    iperf3
    
    # ─── Media Tools ──────────────────────────────────────────────────
    ffmpeg
    imagemagick
    
    # ─── System Utilities ─────────────────────────────────────────────
    lsof
    strace
    ltrace
    pstree
    
  ] ++ lib.optionals userConfig.programs.development.enable [
    # Development packages
    gcc
    gnumake
    cmake
    
  ] ++ lib.optionals (builtins.elem "python" userConfig.programs.development.languages) [
    python3
    python3Packages.pip
    python3Packages.virtualenv
    
  ] ++ lib.optionals (builtins.elem "javascript" userConfig.programs.development.languages) [
    nodejs
    yarn
    
  ] ++ lib.optionals (builtins.elem "rust" userConfig.programs.development.languages) [
    rustc
    cargo
    rustfmt
    
  ] ++ lib.optionals (builtins.elem "go" userConfig.programs.development.languages) [
    go
  ];

  # ─── Shell Configuration ──────────────────────────────────────────────
  programs = {
    # ─── Bash Configuration ───────────────────────────────────────────
    bash = {
      enable = true;
      enableCompletion = true;
      historyControl = [ "erasedups" "ignoredups" "ignorespace" ];
      
      shellAliases = {
        ll = "ls -alF";
        la = "ls -A";
        l = "ls -CF";
        grep = "grep --color=auto";
        fgrep = "fgrep --color=auto";
        egrep = "egrep --color=auto";
        
        # System shortcuts
        rebuild = "sudo nixos-rebuild switch --flake .#laptop";
        update = "nix flake update";
        clean = "sudo nix-collect-garbage -d";
      };
    };

    # ─── Zsh Configuration (if selected) ──────────────────────────────
    zsh = lib.mkIf (userConfig.users.mainUser.shell == "zsh") {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      
      history = {
        size = 10000;
        save = 10000;
        ignoreDups = true;
        ignoreSpace = true;
      };
      
      shellAliases = {
        ll = "ls -alF";
        la = "ls -A";
        l = "ls -CF";
        
        # System shortcuts
        rebuild = "sudo nixos-rebuild switch --flake .#laptop";
        update = "nix flake update";
        clean = "sudo nix-collect-garbage -d";
      };
      
      oh-my-zsh = {
        enable = true;
        theme = "robbyrussell";
        plugins = [ "git" "sudo" "docker" "kubectl" ];
      };
    };

    # ─── Git Configuration ────────────────────────────────────────────
    git = {
      enable = true;
      userName = userConfig.users.mainUser.description;
      userEmail = "${userConfig.users.mainUser.name}@example.com"; # Update this
      
      extraConfig = {
        init.defaultBranch = "main";
        core.editor = "vim";
        pull.rebase = true;
        push.autoSetupRemote = true;
      };
    };

    # ─── Direnv for Development Environments ──────────────────────────
    direnv = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = userConfig.users.mainUser.shell == "zsh";
      nix-direnv.enable = true;
    };

    # ─── Better cat alternative ───────────────────────────────────────
    bat = {
      enable = true;
      config = {
        theme = "TwoDark";
        style = "numbers,changes,header";
      };
    };

    # ─── Better ls alternative ────────────────────────────────────────
    eza = {
      enable = true;
      enableAliases = true;
    };
  };

  # ─── Environment Variables ────────────────────────────────────────────
  home.sessionVariables = {
    EDITOR = "vim";
    BROWSER = "firefox";
    TERMINAL = "alacritty";
  };

  # ─── XDG Directories ──────────────────────────────────────────────────
  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
    };
  };

  # ─── Font Configuration ───────────────────────────────────────────────
  fonts.fontconfig.enable = true;
    unzip
    zip
    
    # System monitoring
    btop
    
    # File managers
    ranger
    
    # Network tools
    nmap
    
    # Programming languages
    python3
    nodejs
    
    # Version control
    gh # GitHub CLI
  ];

  # Git configuration
  programs.git = {
    enable = true;
    userName = "Damianko135"; # Replace with your name
    userEmail = "139293484+Damianko135@users.noreply.github.com"; # Replace with your email
  };

  # Bash configuration
  programs.bash = {
    enable = true;
    enableCompletion = true;
    historyControl = [ "ignoredups" "ignorespace" ];
    
    shellAliases = {
      ll = "ls -alF";
      la = "ls -A";
      l = "ls -CF";
      grep = "grep --color=auto";
      fgrep = "fgrep --color=auto";
      egrep = "egrep --color=auto";
      rebuild = "sudo nixos-rebuild switch --flake .#laptop";
      update = "nix flake update";
    };
  };

  # Zsh configuration (optional)
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "sudo" "docker" "kubectl" ];
      theme = "robbyrussell";
    };
  };

  # Starship prompt
  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };

  # Direnv for automatic environment loading
  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };
}