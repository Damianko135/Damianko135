#!/usr/bin/env bash
# Automated NixOS Configuration Setup Script
# Usage:
#   ./run.sh [--install-nix] [--setup-config] [--full] [--help]

set -euo pipefail

# ─── Color Definitions ────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ─── Configuration ────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/venv"
ANSIBLE_PLAYBOOK="$SCRIPT_DIR/install-nix.yml"
LOG_FILE="$SCRIPT_DIR/setup.log"
BACKUP_DIR="$SCRIPT_DIR/backups"
MIN_PYTHON_VERSION="3.8"
MIN_DISK_SPACE_GB=5
ANSIBLE_INSTALLED_GLOBALLY=false

# ─── Logging Functions ────────────────────────────────────────────────
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $*${NC}" | tee -a "$LOG_FILE"
}
log_info() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $*${NC}" | tee -a "$LOG_FILE"
}
log_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $*${NC}" | tee -a "$LOG_FILE"
}
log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*${NC}" | tee -a "$LOG_FILE"
}
log_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: $*${NC}" | tee -a "$LOG_FILE"
}
log_step() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] STEP: $*${NC}" | tee -a "$LOG_FILE"
}

# ─── Helpers ──────────────────────────────────────────────────────────
show_help() {
    cat <<EOF
Usage: $0 [OPTIONS]

OPTIONS:
  --install-nix     Install Nix package manager only
  --setup-config    Setup NixOS configuration only
  --full            Full installation (default)
  --dry-run         Show what would be done without executing
  --help            Show this help message

Examples:
  $0                # Full installation
  $0 --install-nix  # Install Nix only
  $0 --setup-config # Setup NixOS configuration only
  $0 --dry-run      # Preview actions without executing
EOF
}

error_exit() {
    log_error "$1"
    cleanup_on_error
    exit 1
}

cleanup_on_error() {
    log_info "Cleaning up on error..."
    if [[ -d "$VENV_DIR" && ! -f "$VENV_DIR/.keep" ]]; then
        log_info "Removing incomplete virtual environment"
        rm -rf "$VENV_DIR"
    fi
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        error_exit "This script must be run as root. Try: sudo $0"
    fi
}

check_system_requirements() {
    log_step "Checking system requirements..."
    
    # Check available disk space
    local available_space
    available_space=$(df "$SCRIPT_DIR" | awk 'NR==2 {print int($4/1024/1024)}')
    if [[ $available_space -lt $MIN_DISK_SPACE_GB ]]; then
        error_exit "Insufficient disk space. Need at least ${MIN_DISK_SPACE_GB}GB, have ${available_space}GB"
    fi
    log_info "Disk space check passed: ${available_space}GB available"
    
    # Check Python version if available
    if command -v python3 &>/dev/null; then
        local python_version
        python_version=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
        if ! python3 -c "import sys; exit(0 if sys.version_info >= (3, 8) else 1)" 2>/dev/null; then
            log_warning "Python version $python_version is below recommended minimum $MIN_PYTHON_VERSION"
        else
            log_info "Python version check passed: $python_version"
        fi
    fi
    
    # Check internet connectivity
    if ! ping -c 1 google.com &>/dev/null && ! ping -c 1 8.8.8.8 &>/dev/null; then
        error_exit "No internet connectivity detected. Please check your network connection."
    fi
    log_info "Internet connectivity check passed"
}

create_backup_dir() {
    if [[ ! -d "$BACKUP_DIR" ]]; then
        mkdir -p "$BACKUP_DIR"
        log_info "Created backup directory: $BACKUP_DIR"
    fi
}

detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS="$NAME"
        VER="$VERSION_ID"
    else
        error_exit "Cannot detect OS. /etc/os-release not found."
    fi
    log_info "Detected OS: $OS $VER"
}

is_nixos() {
    [[ -f /etc/NIXOS ]] || [[ "$OS" == *"NixOS"* ]]
}

detect_package_manager() {
    log_step "Detecting package manager..."
    
    # Define package managers with their package names
    declare -A pkg_managers=(
        ["apt"]="apt-get"
        ["yum"]="yum"
        ["dnf"]="dnf"
        ["pacman"]="pacman"
        ["zypper"]="zypper"
    )
    
    for manager in "${!pkg_managers[@]}"; do
        if command -v "${pkg_managers[$manager]}" &>/dev/null; then
            PKG_MANAGER="$manager"
            log_info "Detected package manager: $PKG_MANAGER"
            return 0
        fi
    done
    
    error_exit "Unsupported package manager. Please install Python 3, pip, and git manually."
}

install_system_deps() {
    log_step "Installing system dependencies..."
    
    # Check for essential commands first
    local missing_commands=()
    local essential_commands=("python3" "curl" "wget" "git")
    
    for cmd in "${essential_commands[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            missing_commands+=("$cmd")
        fi
    done
    
    # Check for Python venv capability
    local need_venv=false
    if command -v python3 &>/dev/null; then
        if ! python3 -c "import venv" &>/dev/null; then
            need_venv=true
            log_info "Python3 venv module not available, will install"
        fi
    else
        need_venv=true
    fi
    
    # Check for pip
    local need_pip=false
    if ! command -v pip3 &>/dev/null && ! python3 -c "import pip" &>/dev/null 2>&1; then
        need_pip=true
        log_info "Python3 pip not available, will install"
    fi
    
    # Build package list based on distribution
    local packages_to_install=()
    
    case $PKG_MANAGER in
        apt)
            for cmd in "${missing_commands[@]}"; do
                case $cmd in
                    python3) packages_to_install+=("python3") ;;
                    *) packages_to_install+=("$cmd") ;;
                esac
            done
            [[ "$need_pip" == true ]] && packages_to_install+=("python3-pip")
            [[ "$need_venv" == true ]] && packages_to_install+=("python3-venv")
            ;;
        yum | dnf)
            for cmd in "${missing_commands[@]}"; do
                case $cmd in
                    python3) packages_to_install+=("python3") ;;
                    *) packages_to_install+=("$cmd") ;;
                esac
            done
            [[ "$need_pip" == true ]] && packages_to_install+=("python3-pip")
            # Note: python3-venv is typically included in python3 on RHEL/CentOS/Oracle Linux
            # If venv is still missing after python3 install, we'll handle it separately
            ;;
        pacman)
            for cmd in "${missing_commands[@]}"; do
                case $cmd in
                    python3) packages_to_install+=("python") ;;
                    *) packages_to_install+=("$cmd") ;;
                esac
            done
            [[ "$need_pip" == true ]] && packages_to_install+=("python-pip")
            [[ "$need_venv" == true ]] && packages_to_install+=("python-virtualenv")
            ;;
        zypper)
            for cmd in "${missing_commands[@]}"; do
                case $cmd in
                    python3) packages_to_install+=("python3") ;;
                    *) packages_to_install+=("$cmd") ;;
                esac
            done
            [[ "$need_pip" == true ]] && packages_to_install+=("python3-pip")
            [[ "$need_venv" == true ]] && packages_to_install+=("python3-venv")
            ;;
    esac
    
    # Remove duplicates
    packages_to_install=($(printf '%s\n' "${packages_to_install[@]}" | sort -u))
    
    if [[ ${#packages_to_install[@]} -eq 0 ]]; then
        log_info "All required system dependencies are already available"
        return 0
    fi
    
    log_info "Installing missing packages: ${packages_to_install[*]}"
    
    case $PKG_MANAGER in
        apt)
            apt-get update || error_exit "Failed to update package lists"
            apt-get install -y "${packages_to_install[@]}" || error_exit "Failed to install packages via apt"
            ;;
        yum | dnf)
            "$PKG_MANAGER" update -y || log_warning "Failed to update package lists (continuing anyway)"
            "$PKG_MANAGER" install -y "${packages_to_install[@]}" || error_exit "Failed to install packages via $PKG_MANAGER"
            ;;
        pacman)
            pacman -Syu --noconfirm || error_exit "Failed to update package lists"
            pacman -S --noconfirm "${packages_to_install[@]}" || error_exit "Failed to install packages via pacman"
            ;;
        zypper)
            zypper refresh || error_exit "Failed to refresh package lists"
            zypper install -y "${packages_to_install[@]}" || error_exit "Failed to install packages via zypper"
            ;;
        *)
            error_exit "Unsupported package manager: $PKG_MANAGER"
            ;;
    esac
    
    # Post-installation verification and fixes
    log_info "Verifying installation..."
    
    # Check if venv is still missing after installation (common on RHEL-based systems)
    if ! python3 -c "import venv" &>/dev/null; then
        log_warning "Python venv module still not available after package installation"
        case $PKG_MANAGER in
            yum | dnf)
                log_info "Trying to install python3-venv or alternatives..."
                # Try different package names
                for pkg in "python3-venv" "python3-virtualenv" "python39-venv" "python311-venv"; do
                    if "$PKG_MANAGER" install -y "$pkg" &>/dev/null; then
                        log_info "Successfully installed $pkg"
                        break
                    fi
                done
                
                # If still not available, check if we can install via pip
                if ! python3 -c "import venv" &>/dev/null; then
                    log_warning "venv still not available, will try pip install virtualenv as fallback"
                    if command -v pip3 &>/dev/null; then
                        pip3 install virtualenv || log_warning "Failed to install virtualenv via pip"
                    fi
                fi
                ;;
        esac
    fi
    
    # Final verification
    local verification_failed=false
    for cmd in "${essential_commands[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            log_error "Command $cmd still not available after installation"
            verification_failed=true
        fi
    done
    
    if [[ "$verification_failed" == true ]]; then
        error_exit "Some essential commands are still missing after installation"
    fi
    
    log_success "System dependencies installed and verified successfully"
}

install_ansible() {
    log_step "Installing Ansible..."
    
    # Check if Ansible is already available
    if command -v ansible-playbook &>/dev/null; then
        local ansible_version
        ansible_version=$(ansible --version | head -n1 | cut -d' ' -f2)
        log_info "Ansible already available: version $ansible_version"
        
        # Test if it works with our playbook
        if [[ -f "$ANSIBLE_PLAYBOOK" ]] && ansible-playbook --syntax-check "$ANSIBLE_PLAYBOOK" &>/dev/null; then
            log_info "Existing Ansible installation works with playbook"
            ANSIBLE_INSTALLED_GLOBALLY=true
            return 0
        else
            log_warning "Existing Ansible has issues with playbook - will use virtual environment"
        fi
    fi
    
    # Try system installation as fallback only
    log_info "Attempting system package installation as fallback..."
    local system_install_success=false
    case $PKG_MANAGER in
        apt)
            if add-apt-repository -y ppa:ansible/ansible 2>/dev/null && \
               apt-get update 2>/dev/null && \
               apt-get install -y ansible 2>/dev/null; then
                system_install_success=true
            fi
            ;;
        yum | dnf)
            if "$PKG_MANAGER" install -y ansible 2>/dev/null; then
                system_install_success=true
            fi
            ;;
        pacman)
            if pacman -S --noconfirm ansible 2>/dev/null; then
                system_install_success=true
            fi
            ;;
        zypper)
            if zypper install -y ansible 2>/dev/null; then
                system_install_success=true
            fi
            ;;
    esac
    
    if [[ "$system_install_success" == true ]]; then
        log_info "System package installation successful - will verify in virtual environment"
        ANSIBLE_INSTALLED_GLOBALLY=true
    else
        log_info "System package installation failed - will install in virtual environment"
    fi
    
    # We'll let setup_venv handle the actual Ansible installation
    log_info "Ansible installation will be completed in virtual environment"
}

setup_venv() {
    log_step "Setting up Python virtual environment..."
    log_info "Using virtual environment as primary installation method (Python best practice)"
    
    if [[ -d "$VENV_DIR" ]]; then
        log_info "Virtual environment already exists at $VENV_DIR"
        # Check if it's functional
        if [[ -f "$VENV_DIR/bin/activate" ]]; then
            # shellcheck disable=SC1090
            source "$VENV_DIR/bin/activate"
            if python -c "import sys; print(sys.prefix)" &>/dev/null && \
               ansible --version &>/dev/null; then
                log_info "Existing virtual environment is functional with Ansible"
                
                # Ensure we have the latest versions
                log_info "Updating packages in virtual environment..."
                pip install --upgrade pip --quiet
                pip install --upgrade ansible --quiet
                
                return 0
            else
                log_warning "Existing virtual environment is broken, recreating..."
                deactivate 2>/dev/null || true
                rm -rf "$VENV_DIR"
            fi
        else
            log_warning "Virtual environment directory exists but is incomplete, recreating..."
            rm -rf "$VENV_DIR"
        fi
    fi
    
    # Create virtual environment using best available method
    log_info "Creating new virtual environment..."
    local venv_created=false
    
    # Method 1: Try python3 -m venv (preferred)
    if python3 -c "import venv" &>/dev/null; then
        log_info "Using python3 -m venv to create virtual environment"
        if python3 -m venv "$VENV_DIR"; then
            venv_created=true
        else
            log_warning "Failed to create venv using python3 -m venv"
        fi
    fi
    
    # Method 2: Try virtualenv command as fallback
    if [[ "$venv_created" == false ]] && command -v virtualenv &>/dev/null; then
        log_info "Using virtualenv command as fallback"
        if virtualenv "$VENV_DIR"; then
            venv_created=true
        else
            log_warning "Failed to create venv using virtualenv command"
        fi
    fi
    
    # Method 3: Try python3 -m virtualenv as another fallback
    if [[ "$venv_created" == false ]] && python3 -c "import virtualenv" &>/dev/null; then
        log_info "Using python3 -m virtualenv as fallback"
        if python3 -m virtualenv "$VENV_DIR"; then
            venv_created=true
        else
            log_warning "Failed to create venv using python3 -m virtualenv"
        fi
    fi
    
    if [[ "$venv_created" == false ]]; then
        error_exit "Failed to create virtual environment using any available method"
    fi
    
    log_success "Created virtual environment at $VENV_DIR"
    
    # Activate virtual environment
    # shellcheck disable=SC1090
    source "$VENV_DIR/bin/activate" || error_exit "Failed to activate virtual environment"
    
    # Verify activation worked
    if [[ -z "$VIRTUAL_ENV" ]]; then
        error_exit "Virtual environment activation failed - VIRTUAL_ENV not set"
    fi
    
    log_info "Virtual environment activated successfully"
    log_info "Virtual environment path: $VIRTUAL_ENV"

log_info "This is going to take a while, please be patient..."

# Upgrade pip first (best practice)
log_info "Upgrading pip in virtual environment..."
if ! pip install --upgrade pip &>/dev/null; then
    error_exit "Failed to upgrade pip in virtual environment"
fi

# Install Ansible in virtual environment
log_info "Installing Ansible in virtual environment..."
if ! pip install ansible &>/dev/null; then
    error_exit "Failed to install Ansible in virtual environment"
fi

# Verify Ansible installation
if ! command -v ansible &>/dev/null; then
    error_exit "Ansible installation verification failed"
fi

    local ansible_version
    ansible_version=$(ansible --version | head -n1 | cut -d' ' -f2)
    log_info "Ansible version $ansible_version installed in virtual environment"
    
    # Test with actual playbook if available
    if [[ -f "$ANSIBLE_PLAYBOOK" ]]; then
        log_info "Testing Ansible with playbook..."
        if ansible-playbook --syntax-check "$ANSIBLE_PLAYBOOK" &>/dev/null; then
            log_success "Ansible playbook syntax validation passed"
        else
            log_warning "Ansible playbook syntax validation failed - check your playbook"
        fi
    fi
    
    # Mark as successfully created
    touch "$VENV_DIR/.keep"
    log_success "Virtual environment setup completed with Ansible"
}

validate_config() {
    log_step "Validating configuration files..."
    
    local required_files=(
        "flake.nix"
        "configuration.nix"
        "home.nix"
        "modules/system/boot.nix"
        "modules/system/users.nix"
        "modules/programs/editors.nix"
    )
    
    local optional_files=(
        "hardware-configuration.nix"
        "modules/system/locale.nix"
        "modules/system/networking.nix"
        "modules/system/security.nix"
        "modules/services/desktop.nix"
        "modules/services/development.nix"
        "modules/services/multimedia.nix"
        "modules/programs/shell.nix"
        "modules/programs/system-tools.nix"
    )
    
    local missing_required=()
    local missing_optional=()
    
    # Check required files
    for file in "${required_files[@]}"; do
        if [[ ! -f "$SCRIPT_DIR/$file" ]]; then
            missing_required+=("$file")
        else
            log_info "Found required config file: $file"
        fi
    done
    
    # Check optional files
    for file in "${optional_files[@]}"; do
        if [[ ! -f "$SCRIPT_DIR/$file" ]]; then
            missing_optional+=("$file")
        else
            log_info "Found optional config file: $file"
        fi
    done
    
    # Report missing files
    if [[ ${#missing_required[@]} -gt 0 ]]; then
        log_error "Missing required configuration files:"
        for file in "${missing_required[@]}"; do
            log_error "  - $file"
        done
        error_exit "Cannot proceed without required configuration files"
    fi
    
    if [[ ${#missing_optional[@]} -gt 0 ]]; then
        log_warning "Missing optional configuration files:"
        for file in "${missing_optional[@]}"; do
            log_warning "  - $file"
        done
    fi
    
    # Basic syntax validation for Nix files
    if command -v nix &>/dev/null; then
        log_info "Validating Nix syntax..."
        for file in "${required_files[@]}" "${optional_files[@]}"; do
            if [[ -f "$SCRIPT_DIR/$file" ]]; then
                if ! nix-instantiate --parse "$SCRIPT_DIR/$file" &>/dev/null; then
                    log_error "Syntax error in $file"
                    error_exit "Invalid Nix syntax in configuration files"
                fi
            fi
        done
        log_success "Nix syntax validation passed"
    else
        log_warning "Nix not available for syntax validation"
    fi
}

run_ansible_playbook() {
    log_step "Running Ansible playbook..."
    
    if [[ ! -f "$ANSIBLE_PLAYBOOK" ]]; then
        error_exit "Ansible playbook not found: $ANSIBLE_PLAYBOOK"
    fi
    
    # Always prefer virtual environment if available
    local ansible_cmd="ansible-playbook"
    local ansible_context="system"
    
    if [[ -d "$VENV_DIR" && -f "$VENV_DIR/bin/ansible-playbook" ]]; then
        # Activate virtual environment for consistent execution
        # shellcheck disable=SC1090
        source "$VENV_DIR/bin/activate"
        ansible_cmd="ansible-playbook"
        ansible_context="virtual environment"
        log_info "Using Ansible from virtual environment: $VENV_DIR"
    elif [[ -n "$VIRTUAL_ENV" && -f "$VIRTUAL_ENV/bin/ansible-playbook" ]]; then
        # Already in virtual environment
        ansible_cmd="ansible-playbook"
        ansible_context="virtual environment"
        log_info "Using Ansible from active virtual environment: $VIRTUAL_ENV"
    else
        # Fallback to system ansible
        log_warning "No virtual environment available, using system Ansible"
        ansible_context="system"
    fi
    
    # Verify ansible is available
    if ! command -v ansible-playbook &>/dev/null; then
        error_exit "Ansible playbook command not found in $ansible_context"
    fi
    
    # Show ansible version and location
    local ansible_version
    ansible_version=$(ansible --version | head -n1 | cut -d' ' -f2)
    local ansible_path
    ansible_path=$(which ansible-playbook)
    log_info "Using Ansible version $ansible_version from $ansible_path"
    
    # Validate playbook syntax
    log_info "Validating playbook syntax..."
    if ! ansible-playbook --syntax-check "$ANSIBLE_PLAYBOOK" &>/dev/null; then
        error_exit "Ansible playbook syntax validation failed"
    fi
    log_success "Ansible playbook syntax validation passed"
    
    # Run the playbook
    log_info "Executing Ansible playbook from $ansible_context..."
    if ! ansible-playbook "$ANSIBLE_PLAYBOOK" \
        --inventory localhost, \
        --connection local \
        --become \
        --verbose; then
        error_exit "Ansible playbook execution failed"
    fi
    
    log_success "Ansible playbook executed successfully"
}

setup_nixos_config() {
    if ! is_nixos; then
        log_warning "Skipping NixOS configuration setup (not running on NixOS)."
        return 0
    fi
    
    log_step "Setting up NixOS configuration..."
    create_backup_dir
    
    # Backup existing configuration
    if [[ -f /etc/nixos/configuration.nix ]]; then
        local backup_file="$BACKUP_DIR/configuration.nix.backup.$(date +%Y%m%d_%H%M%S)"
        cp /etc/nixos/configuration.nix "$backup_file"
        log_info "Backed up existing configuration.nix to $backup_file"
    fi
    
    # Generate hardware configuration if missing
    if [[ ! -s "$SCRIPT_DIR/hardware-configuration.nix" ]]; then
        log_info "Generating hardware-configuration.nix..."
        if ! nixos-generate-config --show-hardware-config > "$SCRIPT_DIR/hardware-configuration.nix"; then
            error_exit "Failed to generate hardware configuration"
        fi
        log_success "Generated hardware-configuration.nix"
    fi
    
    # Validate NixOS build
    if command -v nixos-rebuild &>/dev/null; then
        log_info "Testing NixOS build..."
        if ! nixos-rebuild build --flake "$SCRIPT_DIR#laptop" --no-link; then
            error_exit "NixOS build failed - please check your configuration"
        fi
        log_success "NixOS build test passed"
        
        # Prompt for application
        echo
        log_info "NixOS configuration is ready to apply."
        read -rp "Apply NixOS configuration now? [y/N]: " apply
        if [[ "$apply" =~ ^[Yy]$ ]]; then
            log_info "Applying NixOS configuration..."
            if ! nixos-rebuild switch --flake "$SCRIPT_DIR#laptop"; then
                error_exit "Failed to apply NixOS configuration"
            fi
            log_success "NixOS configuration applied successfully"
        else
            log_info "Skipping apply. You can apply it later with:"
            log_info "  nixos-rebuild switch --flake \"$SCRIPT_DIR#laptop\""
        fi
    else
        log_warning "nixos-rebuild not found. Skipping build step."
    fi
}

# ─── Nix Environment Setup ───────────────────────────────────────────
setup_nix_environment() {
    log_step "Setting up Nix environment..."
    
    # Check if Nix is already available
    if command -v nix &>/dev/null; then
        local nix_version
        nix_version=$(nix --version 2>/dev/null | head -n1)
        log_info "Nix already available: $nix_version"
        return 0
    fi
    
    # Try to source Nix environment from common locations
    local nix_profile_locations=(
        "/etc/profile.d/nix.sh"
        "$HOME/.nix-profile/etc/profile.d/nix.sh"
        "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
    )
    
    for nix_profile in "${nix_profile_locations[@]}"; do
        if [[ -f "$nix_profile" ]]; then
            log_info "Found Nix profile script: $nix_profile"
            # shellcheck disable=SC1090
            source "$nix_profile"
            
            # Test if Nix is now available
            if command -v nix &>/dev/null; then
                local nix_version
                nix_version=$(nix --version 2>/dev/null | head -n1)
                log_success "Nix environment loaded successfully: $nix_version"
                
                # Setup Nix configuration for flakes support
                setup_nix_configuration
                
                # Add to user's shell profile for persistence
                setup_nix_profile_persistence "$nix_profile"
                return 0
            fi
        fi
    done
    
    log_warning "Nix environment not found or not working after installation"
    log_info "You may need to:"
    log_info "  1. Restart your shell session"
    log_info "  2. Manually source: source /etc/profile.d/nix.sh"
    log_info "  3. Or add it to your shell profile"
    return 1
}

setup_nix_profile_persistence() {
    local nix_profile="$1"
    log_step "Setting up Nix profile persistence..."
    
    # Determine user's shell and profile file
    local shell_name
    shell_name=$(basename "$SHELL")
    local profile_files=()
    
    case "$shell_name" in
        bash)
            profile_files=("$HOME/.bashrc" "$HOME/.bash_profile")
            ;;
        zsh)
            profile_files=("$HOME/.zshrc")
            ;;
        fish)
            log_info "Fish shell detected - Nix should be automatically available"
            return 0
            ;;
        *)
            profile_files=("$HOME/.profile")
            ;;
    esac
    
    # Check if Nix is already sourced in profile
    for profile_file in "${profile_files[@]}"; do
        if [[ -f "$profile_file" ]]; then
            if grep -q "nix.sh" "$profile_file" 2>/dev/null; then
                log_info "Nix already configured in $profile_file"
                return 0
            fi
        fi
    done
    
    # Add Nix sourcing to the first available profile file
    for profile_file in "${profile_files[@]}"; do
        if [[ -f "$profile_file" ]] || [[ "$profile_file" == "$HOME/.profile" ]]; then
            log_info "Adding Nix environment to $profile_file"
            
            # Create backup
            if [[ -f "$profile_file" ]]; then
                cp "$profile_file" "$profile_file.backup.$(date +%Y%m%d_%H%M%S)"
            fi
            
            # Add Nix sourcing
            cat >> "$profile_file" << EOF

# Nix environment setup (added by NixOS automation script)
if [ -f "$nix_profile" ]; then
    source "$nix_profile"
fi
EOF
            
            log_success "Added Nix environment to $profile_file"
            return 0
        fi
    done
    
    log_warning "Could not find suitable profile file to persist Nix environment"
}

setup_nix_configuration() {
    log_step "Setting up Nix configuration..."
    
    # Create Nix configuration directory
    local nix_config_dir="$HOME/.config/nix"
    if [[ ! -d "$nix_config_dir" ]]; then
        mkdir -p "$nix_config_dir"
        log_info "Created Nix configuration directory: $nix_config_dir"
    fi
    
    # Create or update nix.conf
    local nix_conf="$nix_config_dir/nix.conf"
    local experimental_features="experimental-features = nix-command flakes"
    
    if [[ -f "$nix_conf" ]]; then
        # Check if experimental features are already configured
        if grep -q "experimental-features" "$nix_conf" 2>/dev/null; then
            if grep -q "nix-command" "$nix_conf" && grep -q "flakes" "$nix_conf"; then
                log_info "Nix experimental features already configured"
                return 0
            else
                log_info "Updating existing Nix configuration with experimental features"
                # Remove old experimental-features line and add new one
                sed -i '/experimental-features/d' "$nix_conf"
                echo "$experimental_features" >> "$nix_conf"
            fi
        else
            log_info "Adding experimental features to existing Nix configuration"
            echo "$experimental_features" >> "$nix_conf"
        fi
    else
        log_info "Creating new Nix configuration with experimental features"
        cat > "$nix_conf" << EOF
# Nix configuration (created by NixOS automation script)
$experimental_features
EOF
    fi
    
    log_success "Nix configuration updated with experimental features"
    log_info "Nix configuration file: $nix_conf"
}

# ─── Main ─────────────────────────────────────────────────────────────
show_dry_run() {
    log_info "DRY RUN MODE - Actions that would be performed:"
    echo
    case "$1" in
        install-nix)
            echo "  1. Check system requirements (disk space, connectivity)"
            echo "  2. Install system dependencies (python3, pip, git, etc.)"
            echo "  3. Check for existing Ansible installation"
            echo "  4. Setup Python virtual environment with Ansible"
            echo "  5. Run Ansible playbook: $ANSIBLE_PLAYBOOK"
            echo "  6. Setup Nix environment and shell integration"
            ;;
        setup-config)
            echo "  1. Setup Nix environment and shell integration"
            echo "  2. Validate NixOS configuration files"
            echo "  3. Generate hardware-configuration.nix (if missing)"
            echo "  4. Test NixOS build"
            echo "  5. Prompt to apply configuration"
            ;;
        full)
            echo "  1. Check system requirements (disk space, connectivity)"
            echo "  2. Install system dependencies (python3, pip, git, etc.)"
            echo "  3. Check for existing Ansible installation"
            echo "  4. Setup Python virtual environment with Ansible"
            echo "  5. Run Ansible playbook: $ANSIBLE_PLAYBOOK"
            echo "  6. Setup Nix environment and shell integration"
            echo "  7. Validate NixOS configuration files"
            echo "  8. Generate hardware-configuration.nix (if missing)"
            echo "  9. Test NixOS build"
            echo "  10. Prompt to apply configuration"
            ;;
    esac
    echo
}

main() {
    local action="full"
    local dry_run=false
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --install-nix)  action="install-nix" ;;
            --setup-config) action="setup-config" ;;
            --full)         action="full" ;;
            --dry-run)      dry_run=true ;;
            --help)         show_help; exit 0 ;;
            *) log_error "Unknown option: $1"; show_help; exit 1 ;;
        esac
        shift
    done
    
    # Initialize logging
    echo "# NixOS Setup Log - $(date)" > "$LOG_FILE"
    
    log "Starting NixOS setup (action: $action, dry-run: $dry_run)"
    
    if [[ "$dry_run" == true ]]; then
        show_dry_run "$action"
        exit 0
    fi
    
    # Pre-flight checks
    check_root
    check_system_requirements
    detect_os
    detect_package_manager
    
    # Execute based on action
    case "$action" in
        install-nix)
            install_system_deps
            install_ansible
            setup_venv
            run_ansible_playbook
            setup_nix_environment
            ;;
        setup-config)
            setup_nix_environment
            validate_config
            setup_nixos_config
            ;;
        full)
            install_system_deps
            install_ansible
            setup_venv
            run_ansible_playbook
            setup_nix_environment
            validate_config
            setup_nixos_config
            ;;
    esac
    
    log_success "Setup completed successfully!"
    log_info "Full log available at: $LOG_FILE"
    
    # Show summary
    echo
    log_info "=== SETUP SUMMARY ==="
    log_info "Action performed: $action"
    log_info "Log file: $LOG_FILE"
    if [[ -d "$BACKUP_DIR" ]]; then
        log_info "Backups stored in: $BACKUP_DIR"
    fi
    if [[ -d "$VENV_DIR" ]]; then
        log_info "Virtual environment: $VENV_DIR"
    fi
    
    # Show Nix information
    if command -v nix &>/dev/null; then
        local nix_version
        nix_version=$(nix --version 2>/dev/null | head -n1)
        log_info "Nix package manager: $nix_version"
        log_info "Nix is ready to use!"
    else
        log_warning "Nix environment not loaded. To use Nix, run:"
        log_info "  source /etc/profile.d/nix.sh"
        log_info "  nix --version"
    fi
    
    # Show next steps
    echo
    log_info "=== NEXT STEPS ==="
    if [[ "$action" == "install-nix" ]]; then
        log_info "1. Test Nix: nix --version"
        log_info "2. Test your flake: nix flake check"
        log_info "3. Build configuration: nix build .#nixosConfigurations.laptop.config.system.build.toplevel"
        log_info "4. Install NixOS to apply your configuration"
    elif [[ "$action" == "setup-config" ]]; then
        log_info "1. Your NixOS configuration is validated and ready"
        log_info "2. Install NixOS on target system"
        log_info "3. Copy configuration and run: nixos-rebuild switch --flake .#laptop"
    else
        log_info "1. Your system is ready with Nix and validated configuration"
        log_info "2. For WSL/non-NixOS usage: Test with 'nix flake check'"
        log_info "3. For NixOS installation: Copy config and run 'nixos-rebuild switch --flake .#laptop'"
        log_info "4. For Home Manager: Consider using home-manager for user-level config"
    fi
}

main "$@"
