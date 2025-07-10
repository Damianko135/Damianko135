{ config, pkgs, ... }:

{
  # Text editors and IDEs
  environment.systemPackages = with pkgs; [
    # Terminal editors
    vim
    neovim
    nano
    emacs
    
    # IDEs and advanced editors
    vscode
    jetbrains.idea-ultimate
    jetbrains.pycharm-professional
    
    # Lightweight editors
    gedit
    mousepad
    
    # Development tools
    git
    gitui
    lazygit
    
    # Code formatting and linting
    black
    prettier
    eslint
    
    # Documentation
    man-pages
    tldr
  ];

  # Vim configuration
  programs.vim = {
    enable = true;
    defaultEditor = true;
  };

  # Neovim configuration
  programs.neovim = {
    enable = true;
    defaultEditor = false; # Set to true if you prefer neovim over vim
    viAlias = true;
    vimAlias = true;
    
    configure = {
      customRC = ''
        set number
        set relativenumber
        set tabstop=2
        set shiftwidth=2
        set expandtab
        set smartindent
        syntax on
        
        " Enable mouse support
        set mouse=a
        
        " Search settings
        set hlsearch
        set incsearch
        set ignorecase
        set smartcase
        
        " Visual settings
        set cursorline
        set showmatch
        
        " File handling
        set autoread
        set hidden
      '';
      
      packages.myVimPackage = with pkgs.vimPlugins; {
        start = [
          vim-nix
          vim-airline
          vim-airline-themes
          nerdtree
          vim-gitgutter
          auto-pairs
          vim-surround
          vim-commentary
        ];
      };
    };
  };
}