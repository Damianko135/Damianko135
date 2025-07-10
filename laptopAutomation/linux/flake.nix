{
  description = "Modular NixOS Configuration for Laptop Automation";

  inputs = {
    # NixOS packages - using stable for better reliability
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    
    # Unstable packages for latest software when needed
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    # Home Manager for user-specific configurations
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Hardware-specific configurations
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    
    # Nix User Repository for additional packages
    nur.url = "github:nix-community/NUR";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, nixos-hardware, nur, ... }@inputs: 
    let
      # Import user configuration
      userConfig = import ./userConfig.nix;
      
      # System architecture
      system = "x86_64-linux";
      
      # Overlay for unstable packages
      overlays = [
        nur.overlay
        (final: prev: {
          unstable = import nixpkgs-unstable {
            inherit system;
            config.allowUnfree = true;
          };
        })
      ];
      
    in {
      # ─── NixOS Configurations ─────────────────────────────────────────────
      nixosConfigurations = {
        # Main laptop configuration
        laptop = nixpkgs.lib.nixosSystem {
          inherit system;
          
          specialArgs = { 
            inherit inputs userConfig; 
          };
          
          modules = [
            # Core system configuration
            ./configuration.nix
            
            # Hardware configuration (auto-generated or manual)
            ./hardware-configuration.nix
            
            # Apply overlays
            { nixpkgs.overlays = overlays; }
            
            # Home Manager integration
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                
                users.${userConfig.users.mainUser.name} = import ./home.nix;
                
                extraSpecialArgs = { 
                  inherit inputs userConfig; 
                };
              };
            }
            
            # Hardware-specific modules (optional)
            # nixos-hardware.nixosModules.lenovo-thinkpad-x1-7th-gen
          ];
        };
        
        # Alternative hostname support
        ${userConfig.system.hostname} = self.nixosConfigurations.laptop;
      };

      # ─── Development Shell ────────────────────────────────────────────────
      devShells.${system}.default = nixpkgs.legacyPackages.${system}.mkShell {
        buildInputs = with nixpkgs.legacyPackages.${system}; [
          nixos-rebuild
          home-manager
          git
          vim
        ];
        
        shellHook = ''
          echo "🚀 NixOS Development Environment"
          echo "Available commands:"
          echo "  sudo nixos-rebuild switch --flake .#laptop"
          echo "  home-manager switch --flake .#${userConfig.users.mainUser.name}"
          echo "  nix flake update"
        '';
      };

      # ─── Packages ─────────────────────────────────────────────────────────
      packages.${system} = {
        # Custom packages can be defined here
        default = self.nixosConfigurations.laptop.config.system.build.toplevel;
      };

      # ─── Templates ────────────────────────────────────────────────────────
      templates = {
        default = {
          path = ./.;
          description = "NixOS laptop configuration template";
        };
      };
    };
}