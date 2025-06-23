#!/bin/bash

# Cursor AppImage Installer Script
# This script installs Cursor AppImage with proper desktop integration
# Usage: ./install-cursor.sh [path-to-appimage]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    log_error "This script should not be run as root. Please run as regular user."
    exit 1
fi

# Parse arguments
APPIMAGE_PATH=""
if [[ $# -eq 1 ]]; then
    APPIMAGE_PATH="$1"
elif [[ $# -eq 0 ]]; then
    # Look for AppImage in common locations
    POSSIBLE_PATHS=(
        "$HOME/Downloads/Cursor-*.AppImage"
        "$HOME/Desktop/Cursor-*.AppImage"
        "./Cursor-*.AppImage"
    )
    
    for pattern in "${POSSIBLE_PATHS[@]}"; do
        files=($(ls $pattern 2>/dev/null || true))
        if [[ ${#files[@]} -gt 0 ]]; then
            APPIMAGE_PATH="${files[0]}"
            log_info "Found AppImage: $APPIMAGE_PATH"
            break
        fi
    done
else
    log_error "Usage: $0 [path-to-cursor-appimage]"
    exit 1
fi

# Validate AppImage path
if [[ -z "$APPIMAGE_PATH" ]]; then
    log_error "No Cursor AppImage found. Please specify the path or place it in Downloads/Desktop directory."
    exit 1
fi

if [[ ! -f "$APPIMAGE_PATH" ]]; then
    log_error "AppImage file not found: $APPIMAGE_PATH"
    exit 1
fi

# Get absolute path
APPIMAGE_PATH=$(realpath "$APPIMAGE_PATH")
APPIMAGE_NAME=$(basename "$APPIMAGE_PATH")

log_info "Installing Cursor AppImage: $APPIMAGE_NAME"

# Check if /opt/cursor exists, create if needed
if [[ ! -d "/opt/cursor" ]]; then
    log_info "Creating /opt/cursor directory (requires sudo)"
    sudo mkdir -p /opt/cursor
fi

# Copy AppImage to /opt/cursor
log_info "Copying AppImage to /opt/cursor (requires sudo)"
sudo cp "$APPIMAGE_PATH" /opt/cursor/
sudo chmod +x "/opt/cursor/$APPIMAGE_NAME"

# Create local bin directory
mkdir -p "$HOME/.local/bin"

# Create wrapper script
log_info "Creating cursor command wrapper"
cat > "$HOME/.local/bin/cursor" << 'EOF'
#!/bin/bash
nohup /opt/cursor/APPIMAGE_PLACEHOLDER --no-sandbox "$@" > /dev/null 2>&1 & disown
EOF

# Replace placeholder with actual AppImage name
sed -i "s/APPIMAGE_PLACEHOLDER/$APPIMAGE_NAME/g" "$HOME/.local/bin/cursor"
chmod +x "$HOME/.local/bin/cursor"

# Extract icon from AppImage
log_info "Extracting icon from AppImage"
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"
"/opt/cursor/$APPIMAGE_NAME" --appimage-extract > /dev/null 2>&1

if [[ -f "squashfs-root/usr/share/icons/hicolor/256x256/apps/cursor.png" ]]; then
    sudo cp "squashfs-root/usr/share/icons/hicolor/256x256/apps/cursor.png" /opt/cursor/
    log_info "Icon extracted successfully"
else
    log_warn "Could not extract icon, desktop entry will use default icon"
fi

# Cleanup temp directory
cd - > /dev/null
rm -rf "$TEMP_DIR"

# Create desktop applications directory
mkdir -p "$HOME/.local/share/applications"

# Create desktop entry
log_info "Creating desktop entry"
cat > "$HOME/.local/share/applications/cursor.desktop" << EOF
[Desktop Entry]
Name=Cursor
Comment=AI-powered code editor
Exec=/opt/cursor/$APPIMAGE_NAME --no-sandbox %F
Icon=/opt/cursor/cursor.png
Terminal=false
Type=Application
Categories=Development;TextEditor;
MimeType=text/plain;application/javascript;application/json;text/css;text/html;text/xml;
StartupNotify=true
StartupWMClass=cursor
EOF

chmod +x "$HOME/.local/share/applications/cursor.desktop"

# Update desktop database
log_info "Updating desktop database"
update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true

# Check if ~/.local/bin is in PATH
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    log_warn "~/.local/bin is not in your PATH"
    log_info "Adding ~/.local/bin to PATH in ~/.bashrc"
    
    # Check if already added to avoid duplicates
    if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.bashrc"; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
        log_info "Added ~/.local/bin to PATH. Please restart your terminal or run: source ~/.bashrc"
    fi
fi

log_info "Installation complete!"
echo
log_info "Usage:"
echo "  - Type 'cursor' to launch Cursor"
echo "  - Type 'cursor .' to open current directory"
echo "  - Type 'cursor /path/to/folder' to open specific directory"
echo "  - Cursor is also available in your applications menu"
echo
log_info "To update Cursor:"
echo "  1. Download new AppImage"
echo "  2. Run: $0 /path/to/new/Cursor-AppImage"