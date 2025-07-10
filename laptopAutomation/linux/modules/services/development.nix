{ config, pkgs, config: userConfig, lib, ... }:

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
    ];
    
    # Language servers for editors
    python3Packages.python-lsp-server
    nodePackages.typescript-language-server
    nodePackages.pyright
    gopls
    rust-analyzer
    
    # Databases
    postgresql
    mysql80
    sqlite
    redis
    mongodb
    
    # Database tools
    dbeaver
    pgadmin4
    
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
    postman
    insomnia
    
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
    google-cloud-sdk
    azure-cli
    
    # Infrastructure as Code
    terraform
    ansible
    
    # Monitoring
    prometheus
    grafana
    
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
    
    # Testing tools
    selenium-server-standalone
    
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
    rabbitmq-server
    
    # Search engines
    elasticsearch
    
    # Reverse engineering
    ghidra
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
    crossPlatformPackages.buildPackages.gcc
  ];

  # Services for development (only enabled if development is enabled)
  services = lib.mkIf userConfig.development.enable {
    # Docker
    docker = lib.mkIf userConfig.features.docker {
      enable = true;
      enableOnBoot = true;
      autoPrune = {
        enable = true;
        dates = "weekly";
      };
    };
  };

  # Virtualization for development
  virtualisation = lib.mkIf userConfig.development.enable {
    docker.enable = lib.mkIf userConfig.features.docker true;
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

  # Development environment variables
  environment.variables = {
    EDITOR = "vim";
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

  # Shell aliases for development
  environment.shellAliases = {
    # Git shortcuts
    gs = "git status";
    ga = "git add";
    gc = "git commit";
    gp = "git push";
    gl = "git log --oneline";
    gd = "git diff";
    gb = "git branch";
    gco = "git checkout";
    
    # Docker shortcuts
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

  # Virtualization for development
  virtualisation = {
    docker.enable = true;
    libvirtd.enable = true;
    
    # VMware if needed
    # vmware.host.enable = true;
    
    # VirtualBox if needed
    # virtualbox.host.enable = true;
  };

  # Programs for development
  programs = {
    # Enable Java
    java = {
      enable = true;
      package = pkgs.openjdk;
    };
    
    # Enable Steam for game development
    steam.enable = true;
    
    # Enable ADB for Android development
    adb.enable = true;
  };
}