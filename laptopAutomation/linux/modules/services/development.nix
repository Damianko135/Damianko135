{ config, pkgs, userConfig, lib, ... }:

{
  # Development tools and environments
  environment.systemPackages = with pkgs; 
    # Base development tools
    [
      # Version control
      git
      git-lfs
      gh # GitHub CLI
      
      # Build tools
      cmake
      make
      gcc
      clang
      
      # Text processing
      jq
      yq
      
      # HTTP clients
      curl
      wget
      httpie
      
      # Development utilities
      tmux
      screen
      
      # Code analysis
      shellcheck
    ]
    # Programming languages (based on user config)
    ++ lib.optionals (lib.elem "python" userConfig.development.languages) [
      python3
      python3Packages.pip
      python3Packages.virtualenv
      python3Packages.python-lsp-server
      black
      isort
      flake8
    ]
    ++ lib.optionals (lib.elem "nodejs" userConfig.development.languages) [
      nodejs
      yarn
      npm
      nodePackages.typescript-language-server
      nodePackages.pyright
      prettier
      eslint
    ]
    ++ lib.optionals (lib.elem "go" userConfig.development.languages) [
      go
      gopls
    ]
    ++ lib.optionals (lib.elem "rust" userConfig.development.languages) [
      rustc
      cargo
      rust-analyzer
    ]
    ++ lib.optionals (lib.elem "java" userConfig.development.languages) [
      openjdk
    ]
    # IDEs
    ++ lib.optionals (lib.elem "vscode" userConfig.development.ides) [
      vscode
    ]
    ++ lib.optionals (lib.elem "vim" userConfig.development.ides) [
      vim
      neovim
    ]
    # Docker if enabled
    ++ lib.optionals userConfig.features.docker [
      docker
      docker-compose
    ]
    
    # Language servers for editors
    ++ [
      python3Packages.python-lsp-server
      gopls
      rust-analyzer
      
      # Databases
      postgresql
      mysql
      sqlite
      redis
      # mongodb  # Comment out if causing issues
      
      # Database tools
      # dbeaver    # Comment out if causing issues - GUI app
      # pgadmin4   # Comment out if causing issues - GUI app
      
      # Version control
      git
      git-lfs
      gitui
      lazygit
      gh # GitHub CLI
      
      # Build tools
      cmake
      make
      meson
      ninja
      
      # Package managers
      poetry
      pipenv
      
      # API tools
      # postman     # Comment out if causing issues - GUI app
      # insomnia    # Comment out if causing issues - GUI app
      
      # Documentation
      zeal
      
      # Containers
      docker
      docker-compose
      podman
      podman-compose
      
      # Kubernetes
      kubectl
      k9s
      helm
      
      # Cloud tools
      awscli2
      # google-cloud-sdk  # Comment out if causing issues
      # azure-cli         # Comment out if causing issues
      
      # Infrastructure as Code
      terraform
      ansible
      
      # Monitoring
      # prometheus  # Comment out if causing issues - service
      # grafana     # Comment out if causing issues - service
      
      # Text processing
      jq
      yq
      
      # HTTP clients (curl duplicate removed)
      # curl    # Duplicate - defined earlier in base packages
      wget
      httpie
      
      # Development utilities
      tmux
      screen
      
      # Code analysis
      shellcheck
      
      # Testing tools
      # selenium-server-standalone  # Comment out if causing issues
      
      # Network tools
      wireshark
      nmap
      
      # Performance tools
      hyperfine
      
      # Linters and formatters
      black
      isort
      flake8
      prettier
      eslint
      
      # Documentation generators
      sphinx
      mkdocs
      
      # Protobuf
      protobuf
      
      # gRPC tools
      grpcurl
      
      # Message queues
      # rabbitmq-server  # Comment out if causing issues - service
      
      # Search engines
      # elasticsearch    # Comment out if causing issues - service
      
      # Reverse engineering
      # ghidra          # Comment out if causing issues - large GUI app
      radare2
      
      # Binary analysis
      binwalk
      
      # Hex editors
      hexedit
      
      # Debuggers
      gdb
      lldb
      
      # Profilers
      valgrind
      
      # Static analysis
      cppcheck
      
      # Cross-compilation
      # crossPlatformPackages.buildPackages.gcc  # Comment out problematic package
    ];

  # Services for development (only enabled if development is enabled)
  services = lib.mkIf userConfig.development.enable {
    # Development services can go here (not Docker)
  };

  # Virtualization for development
  virtualisation = lib.mkIf userConfig.development.enable {
    docker = lib.mkIf userConfig.features.docker {
      enable = true;
      enableOnBoot = true;
      autoPrune = {
        enable = true;
        dates = "weekly";
      };
    };
    libvirtd.enable = lib.mkIf userConfig.features.virtualization true;
  };

  # Programs for development
  programs = lib.mkIf userConfig.development.enable {
    # Enable Java
    java = lib.mkIf (lib.elem "java" userConfig.development.languages) {
      enable = true;
      package = pkgs.openjdk;
    };
    
    # Enable ADB for Android development
    adb.enable = lib.mkIf (lib.elem "android" userConfig.development.languages) true;
  };

  # Development environment variables (EDITOR managed by editors.nix)
  environment.variables = {
    # EDITOR = "vim";  # Commented to avoid conflict with editors.nix
    BROWSER = "firefox";
    TERMINAL = "gnome-terminal";
    
    # Python
    PYTHONPATH = "$PYTHONPATH:/usr/local/lib/python3.11/site-packages";
    
    # Node.js
    NODE_PATH = "$NODE_PATH:/usr/local/lib/node_modules";
    
    # Go
    GOPATH = "$HOME/go";
    GOBIN = "$GOPATH/bin";
    
    # Rust
    CARGO_HOME = "$HOME/.cargo";
    RUSTUP_HOME = "$HOME/.rustup";
    
    # Java
    JAVA_HOME = "${pkgs.openjdk}/lib/openjdk";
    
    # Docker
    DOCKER_HOST = "unix:///var/run/docker.sock";
  };

  # Shell aliases for development - avoiding duplicates with shell.nix
  environment.shellAliases = {
    # Docker shortcuts (development-specific)
    d = "docker";
    dc = "docker-compose";
    dps = "docker ps";
    di = "docker images";
    
    # Kubernetes shortcuts
    k = "kubectl";
    kgp = "kubectl get pods";
    kgs = "kubectl get services";
    kgd = "kubectl get deployments";
    
    # Python shortcuts
    py = "python3";
    pip = "pip3";
    
    # Node.js shortcuts
    nr = "npm run";
    ni = "npm install";
    
    # Common development tasks
    serve = "python3 -m http.server 8000";
    json = "python3 -m json.tool";
  };
}