{ config, pkgs, ... }:

{
  # Shell and terminal tools
  environment.systemPackages = with pkgs; [
    # Terminal emulators
    kitty
    alacritty
    terminator
    
    # Shells
    zsh
    bash
    fish
    
    # Shell enhancement tools
    starship
    zoxide
    fzf
    ripgrep
    fd
    bat
    eza
    
    # Terminal multiplexers
    tmux
    screen
    
    # Process monitoring
    htop
    btop
    glances
    
    # File managers
    ranger
    nnn
    mc
    
    # Archive tools
    unzip
    zip
    p7zip
    rar
    
    # Network tools
    wget
    curl
    aria2
    
    # System information
    neofetch
    fastfetch
    
    # Directory navigation
    tree
    
    # Text processing
    jq
    yq
    
    # Development utilities
    direnv
    just
    
    # Terminal recording
    asciinema
  ];

  # Default shell programs
  programs = {
    # Zsh configuration
    zsh = {
      enable = true;
      autosuggestions.enable = true;
      syntaxHighlighting.enable = true;
      
      ohMyZsh = {
        enable = true;
        plugins = [
          "git"
          "sudo"
          "docker"
          "kubectl"
          "systemd"
          "history"
          "colored-man-pages"
        ];
        theme = "robbyrussell";
      };
      
      shellAliases = {
        ll = "eza -alF";
        la = "eza -A";
        l = "eza -CF";
        cls = "clear";
        ls = "eza";
        cat = "bat";
        grep = "rg";
        find = "fd";
        cd = "z";
        
        # Nix aliases
        rebuild = "sudo nixos-rebuild switch --flake .#laptop";
        update = "nix flake update";
        clean = "sudo nix-collect-garbage -d";
        
        # Git aliases
        gs = "git status";
        ga = "git add";
        gc = "git commit";
        gp = "git push";
        gl = "git log --oneline";
      };
    };
    
    # Bash configuration
    bash = {
      enable = true;
      completion.enable = true;
    };
    
    # Starship prompt
    starship = {
      enable = true;
      settings = {
        add_newline = false;
        
        character = {
          success_symbol = "[➜](bold green)";
          error_symbol = "[➜](bold red)";
        };
        
        directory = {
          truncation_length = 3;
          truncate_to_repo = false;
        };
        
        git_branch = {
          symbol = "🌱 ";
        };
        
        nix_shell = {
          disabled = false;
          impure_msg = "[impure shell](bold red)";
          pure_msg = "[pure shell](bold green)";
          symbol = "❄️ ";
        };
      };
    };
    
    # Tmux configuration
    tmux = {
      enable = true;
      clock24 = true;
      historyLimit = 10000;
      keyMode = "vi";
      shortcut = "a";
      terminal = "tmux-256color";
      
      extraConfig = ''
        # Split panes using | and -
        bind | split-window -h
        bind - split-window -v
        unbind '"'
        unbind %
        
        # Reload config file
        bind r source-file ~/.tmux.conf
        
        # Switch panes using Alt-arrow without prefix
        bind -n M-Left select-pane -L
        bind -n M-Right select-pane -R
        bind -n M-Up select-pane -U
        bind -n M-Down select-pane -D
        
        # Enable mouse mode
        set -g mouse on
        
        # Status bar
        set -g status-bg black
        set -g status-fg white
        set -g status-left ""
        set -g status-right "#[fg=green]#H"
      '';
    };
    
    # Direnv for automatic environment loading
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };
}