#!/bin/bash

# Enhanced Cursor AppImage Installer Script
# This script downloads and installs Cursor AppImage with proper desktop integration
# Usage: ./install-cursor.sh [options] [path-to-appimage]
# Options: --stable (default), --latest, --update, --version, --help

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Version
VERSION="2.0.0"

# Helper functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_debug() {
    echo -e "${BLUE}[DEBUG]${NC} $1"
}

show_help() {
    echo "Enhanced Cursor AppImage Installer v$VERSION"
    echo
    echo "Usage: $0 [options] [path-to-appimage]"
    echo
    echo "Options:"
    echo "  --stable      Download stable version (default)"
    echo "  --latest      Download latest version"
    echo "  --update      Update existing installation"
    echo "  --version     Show installed version"
    echo "  --help        Show this help message"
    echo
    echo "Examples:"
    echo "  $0                              # Install stable version"
    echo "  $0 --latest                     # Install latest version"
    echo "  $0 --update                     # Update to stable version"
    echo "  $0 --update --latest            # Update to latest version"
    echo "  $0 /path/to/cursor.AppImage     # Install from local file"
    echo
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root. Please run as regular user."
        exit 1
    fi
}

# Get system architecture
get_arch() {
    local arch=$(uname -m)
    case "$arch" in
        x86_64)
            echo "x64"
            ;;
        aarch64)
            echo "arm64"
            ;;
        *)
            log_error "Unsupported architecture: $arch"
            exit 1
            ;;
    esac
}

# Check and install FUSE if needed
check_fuse() {
    local cmd_prefix=""
    if [ "$EUID" -ne 0 ]; then
        cmd_prefix="sudo"
    fi

    if command -v apt-get &>/dev/null; then
        if ! dpkg -l | grep -q "^ii.*fuse "; then
            log_info "Installing FUSE..."
            $cmd_prefix apt-get update -qq
            $cmd_prefix apt-get install -y fuse
        fi
    elif command -v dnf &>/dev/null; then
        if ! rpm -q fuse >/dev/null 2>&1; then
            log_info "Installing FUSE..."
            $cmd_prefix dnf install -y fuse
        fi
    elif command -v pacman &>/dev/null; then
        if ! pacman -Qi fuse2 >/dev/null 2>&1; then
            log_info "Installing FUSE..."
            $cmd_prefix pacman -S --noconfirm fuse2
        fi
    else
        log_warn "Could not automatically install FUSE. Please install it manually:"
        echo "  - Debian/Ubuntu: sudo apt-get install fuse"
        echo "  - Fedora: sudo dnf install fuse"
        echo "  - Arch Linux: sudo pacman -S fuse2"
    fi
}

# Find existing Cursor installation
find_cursor_installation() {
    local search_paths=(
        "/opt/cursor"
        "$HOME/.local/share/cursor"
        "$HOME/Applications"
        "$HOME/.local/bin"
    )
    
    for path in "${search_paths[@]}"; do
        if [[ -f "$path/cursor.AppImage" ]] || [[ -f "$path/Cursor-"*".AppImage" ]]; then
            echo "$path"
            return 0
        fi
    done
    return 1
}

# Get download information from Cursor API
get_download_info() {
    local release_track=${1:-stable}
    local arch=$(get_arch)

    # Primary method: official JSON API
    local api_url="https://cursor.com/api/download?platform=linux-${arch}&releaseTrack=${release_track}"
    local temp_file=$(mktemp)

    if curl -fsSL "$api_url" -o "$temp_file"; then
        # Parse JSON manually (no jq dependency)
        local download_url="$(grep -o '"downloadUrl":"[^"]*' "$temp_file" | head -n1 | cut -d'"' -f4)"
        local version="$(grep -o '"version":"[^"]*' "$temp_file" | head -n1 | cut -d'"' -f4)"
        rm -f "$temp_file"
        if [[ -n "$download_url" && -n "$version" ]]; then
            echo "URL=$download_url"
            echo "VERSION=$version"
            return 0
        fi
    fi
    rm -f "$temp_file"

    # Fallback #1: redirector service (.com)
    local redirector="https://downloader.cursor.com/linux/appImage/${arch}"
    local final_url="$(curl -Ls -o /dev/null -w "%{url_effective}" "$redirector" 2>/dev/null)"
    if [[ -n "$final_url" && "$final_url" == *.AppImage ]]; then
        local version="unknown"
        if [[ "$final_url" =~ Cursor-([0-9]+\.[0-9]+\.[0-9]+) ]]; then
            version="${BASH_REMATCH[1]}"
        fi
        echo "URL=$final_url"
        echo "VERSION=$version"
        return 0
    fi

    # Fallback #2: redirector service (.sh)
    redirector="https://downloader.cursor.sh/linux/appImage/${arch}"
    final_url="$(curl -Ls -o /dev/null -w "%{url_effective}" "$redirector" 2>/dev/null)"
    if [[ -n "$final_url" && "$final_url" == *.AppImage ]]; then
        local version="unknown"
        if [[ "$final_url" =~ Cursor-([0-9]+\.[0-9]+\.[0-9]+) ]]; then
            version="${BASH_REMATCH[1]}"
        fi
        echo "URL=$final_url"
        echo "VERSION=$version"
        return 0
    fi

    log_error "Unable to determine the latest Cursor download URL. Please check your Internet connection or report an issue."
    return 1
}

# Download and install Cursor
download_and_install() {
    local release_track=${1:-stable}
    local install_dir="/opt/cursor"
    
    # Check FUSE before proceeding
    check_fuse
    
    # Get download information
    local download_info
    if ! download_info=$(get_download_info "$release_track"); then
        log_error "Failed to get download information"
        return 1
    fi
    
    local download_url=$(echo "$download_info" | grep "URL=" | sed 's/^URL=//')
    local version=$(echo "$download_info" | grep "VERSION=" | sed 's/^VERSION=//')
    
    log_info "Downloading Cursor v$version..."
    
    # Create temporary file
    local temp_file=$(mktemp)
    
    # Download with progress
    if ! curl -L --progress-bar "$download_url" -o "$temp_file"; then
        log_error "Failed to download Cursor AppImage"
        rm -f "$temp_file"
        return 1
    fi
    
    # Create install directory
    if [[ ! -d "$install_dir" ]]; then
        log_info "Creating installation directory (requires sudo)"
        sudo mkdir -p "$install_dir"
    fi
    
    # Install AppImage
    local appimage_name="Cursor-${version}.AppImage"
    log_info "Installing to $install_dir/$appimage_name"
    
    sudo cp "$temp_file" "$install_dir/$appimage_name"
    sudo chmod +x "$install_dir/$appimage_name"
    
    # Create symlink for easier access
    sudo ln -sf "$install_dir/$appimage_name" "$install_dir/cursor.AppImage"
    
    # Store version information
    echo "$version" | sudo tee "$install_dir/.cursor_version" > /dev/null
    
    rm -f "$temp_file"
    return 0
}

# Extract and install desktop integration
setup_desktop_integration() {
    local install_dir="/opt/cursor"
    local appimage="$install_dir/cursor.AppImage"
    
    if [[ ! -f "$appimage" ]]; then
        log_error "AppImage not found at $appimage"
        return 1
    fi
    
    log_info "Setting up desktop integration..."
    
    # Extract icon and desktop file
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    # Copy AppImage to a temporary directory to run extraction as the user.
    # This avoids FUSE permission issues when the AppImage is in a root-owned location.
    local temp_appimage="cursor-temp.AppImage"
    cp "$appimage" "$temp_appimage"
    chmod +x "$temp_appimage"

    # Extract AppImage contents.
    # The output is captured for debugging in case of failure.
    local extract_log
    extract_log=$(mktemp)
    if ! "./$temp_appimage" --appimage-extract >"$extract_log" 2>&1; then
        log_error "Could not extract AppImage contents."
        log_error "This is required for proper desktop integration (icons, etc)."
        log_error "Please ensure 'fuse' or 'fuse2' is installed and working correctly."
        log_error "Extraction log output:"
        cat "$extract_log"
        rm -f "$extract_log"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
    rm -f "$extract_log"
    
    # Create directories
    mkdir -p "$HOME/.local/share/applications"
    mkdir -p "$HOME/.local/share/icons/hicolor/256x256/apps"
    
    # Copy icon if available
    if [[ -f "squashfs-root/usr/share/icons/hicolor/256x256/apps/cursor.png" ]]; then
        cp "squashfs-root/usr/share/icons/hicolor/256x256/apps/cursor.png" \
           "$HOME/.local/share/icons/hicolor/256x256/apps/"
        # Also copy to install directory for desktop file reference
        sudo cp "squashfs-root/usr/share/icons/hicolor/256x256/apps/cursor.png" \
           "$install_dir/cursor.png"
        log_info "Icon installed successfully"
    else
        log_warn "Could not extract icon"
    fi
    
    # Update desktop database
    if command -v update-desktop-database &>/dev/null; then
        update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
    fi
    
    cd - > /dev/null
    rm -rf "$temp_dir"
    
    # Always regenerate the launcher wrapper & desktop entry so they stay in sync
    create_command_wrapper
    
    log_info "Desktop integration completed"
}

# Create command wrapper
create_command_wrapper() {
    local install_dir="/opt/cursor"
    local appimage="$install_dir/cursor.AppImage"  # always points to current version via symlink

    mkdir -p "$HOME/.local/bin"

    # Overwrite wrapper with a lightweight launcher that always follows the symlink
    cat > "$HOME/.local/bin/cursor" <<'EOS'
#!/bin/bash
APPIMAGE="/opt/cursor/cursor.AppImage"
if [[ "$1" == "--version" || "$1" == "-v" ]]; then
    if [[ -f "/opt/cursor/.cursor_version" ]]; then
        cat /opt/cursor/.cursor_version
        exit 0
    fi
fi
if [[ ! -f "$APPIMAGE" ]]; then
    echo "Cursor AppImage not found at $APPIMAGE" >&2
    exit 1
fi
nohup "$APPIMAGE" --no-sandbox "$@" >/dev/null 2>&1 & disown
EOS

    chmod +x "$HOME/.local/bin/cursor"

    # Ensure desktop file Exec line also points to the symlink so menu entries
    # always open the latest version.
    local desktop_file="$HOME/.local/share/applications/cursor.desktop"
    mkdir -p "$(dirname "$desktop_file")"
    cat > "$desktop_file" <<DESK
[Desktop Entry]
Name=Cursor
Comment=AI-powered code editor
Exec=/opt/cursor/cursor.AppImage --no-sandbox %F
Icon=/opt/cursor/cursor.png
Terminal=false
Type=Application
Categories=Development;TextEditor;
MimeType=text/plain;application/javascript;application/json;text/css;text/html;text/xml;
StartupNotify=true
StartupWMClass=cursor
DESK
    chmod +x "$desktop_file"
}

# Setup PATH
setup_path() {
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        log_warn "~/.local/bin is not in your PATH"
        log_info "Adding ~/.local/bin to PATH in ~/.bashrc"
        
        # Check if already added to avoid duplicates
        if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.bashrc" 2>/dev/null; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
            log_info "Added ~/.local/bin to PATH. Please restart your terminal or run: source ~/.bashrc"
        fi
    fi
}

# Show installed version
show_installed_version() {
    local install_dir="/opt/cursor"
    local version_file="$install_dir/.cursor_version"
    
    if [[ -f "$version_file" ]]; then
        local version=$(cat "$version_file")
        echo "Cursor version: $version"
        return 0
    else
        log_error "Cursor is not installed or version information is missing"
        return 1
    fi
}

# Update existing installation
update_installation() {
    local release_track=${1:-stable}
    
    log_info "Updating Cursor to $release_track version..."
    
    # Check if already installed
    if [[ ! -d "/opt/cursor" ]]; then
        log_info "No existing installation found. Installing fresh..."
        install_cursor "$release_track"
        return $?
    fi
    
    # Get current version
    local current_version=""
    if [[ -f "/opt/cursor/.cursor_version" ]]; then
        current_version=$(cat "/opt/cursor/.cursor_version")
        log_info "Current version: $current_version"
    fi
    
    # Download and install new version
    if download_and_install "$release_track"; then
        setup_desktop_integration
        create_command_wrapper
        log_info "Update completed successfully!"
        
        # Show version info
        show_installed_version
    else
        log_error "Update failed"
        return 1
    fi
}

# Main installation function
install_cursor() {
    local release_track=${1:-stable}
    local appimage_path="$2"
    
    log_info "Installing Cursor AppImage ($release_track version)..."
    
    if [[ -n "$appimage_path" ]]; then
        # Install from local file
        install_from_local_file "$appimage_path"
    else
        # Download and install
        if download_and_install "$release_track"; then
            setup_desktop_integration
            create_command_wrapper
            setup_path
            
            log_info "Installation complete!"
            echo
            log_info "Usage:"
            echo "  - Type 'cursor' to launch Cursor"
            echo "  - Type 'cursor .' to open current directory"
            echo "  - Type 'cursor /path/to/folder' to open specific directory"
            echo "  - Cursor is also available in your applications menu"
            echo
            log_info "To update Cursor:"
            echo "  - Run: $0 --update"
            echo "  - Run: $0 --update --latest"
        else
            log_error "Installation failed"
            return 1
        fi
    fi
}

# Install from local AppImage file
install_from_local_file() {
    local appimage_path="$1"
    local install_dir="/opt/cursor"
    
    # Validate file
    if [[ ! -f "$appimage_path" ]]; then
        log_error "AppImage file not found: $appimage_path"
        exit 1
    fi
    
    # Get absolute path
    appimage_path=$(realpath "$appimage_path")
    local appimage_name=$(basename "$appimage_path")
    
    log_info "Installing from local file: $appimage_name"
    
    # Check FUSE
    check_fuse
    
    # Create install directory
    if [[ ! -d "$install_dir" ]]; then
        log_info "Creating installation directory (requires sudo)"
        sudo mkdir -p "$install_dir"
    fi
    
    # Copy AppImage
    log_info "Copying AppImage to $install_dir"
    sudo cp "$appimage_path" "$install_dir/"
    sudo chmod +x "$install_dir/$appimage_name"
    
    # Create symlink
    sudo ln -sf "$install_dir/$appimage_name" "$install_dir/cursor.AppImage"
    
    # Try to extract version (if possible)
    local version="unknown"
    if [[ "$appimage_name" =~ Cursor-([0-9]+\.[0-9]+\.[0-9]+) ]]; then
        version="${BASH_REMATCH[1]}"
    fi
    echo "$version" | sudo tee "$install_dir/.cursor_version" > /dev/null
    
    # Setup desktop integration and command wrapper
    setup_desktop_integration
    create_command_wrapper
    setup_path
    
    log_info "Installation complete!"
    echo
    log_info "Usage:"
    echo "  - Type 'cursor' to launch Cursor"
    echo "  - Type 'cursor .' to open current directory"
    echo "  - Cursor is also available in your applications menu"
}

# Parse command line arguments
RELEASE_TRACK="stable"
APPIMAGE_PATH=""
ACTION="install"

while [[ $# -gt 0 ]]; do
    case $1 in
        --stable)
            RELEASE_TRACK="stable"
            shift
            ;;
        --latest)
            RELEASE_TRACK="latest"
            shift
            ;;
        --update)
            ACTION="update"
            shift
            ;;
        --version)
            ACTION="version"
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        -*)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
        *)
            APPIMAGE_PATH="$1"
            shift
            ;;
    esac
done

# Check if running as root
check_root

# Execute requested action
case "$ACTION" in
    install)
        install_cursor "$RELEASE_TRACK" "$APPIMAGE_PATH"
        ;;
    update)
        update_installation "$RELEASE_TRACK"
        ;;
    version)
        show_installed_version
        ;;
    *)
        log_error "Unknown action: $ACTION"
        exit 1
        ;;
esac