#!/bin/bash

# Cursor AppImage Uninstaller Script
# This script removes Cursor AppImage and all associated files

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

show_help() {
    echo "Cursor AppImage Uninstaller"
    echo
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "  --force       Skip confirmation prompts"
    echo "  --keep-config Keep configuration files"
    echo "  --help        Show this help message"
    echo
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    log_error "This script should not be run as root. Please run as regular user."
    exit 1
fi

# Parse arguments
FORCE=false
KEEP_CONFIG=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --force)
            FORCE=true
            shift
            ;;
        --keep-config)
            KEEP_CONFIG=true
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

echo "Cursor AppImage Uninstaller"
echo "=========================="
echo

if [[ "$FORCE" != "true" ]]; then
    echo "This will remove:"
    echo "  - Cursor AppImage from /opt/cursor"
    echo "  - Command wrapper from ~/.local/bin/cursor"
    echo "  - Desktop entry and icons"
    if [[ "$KEEP_CONFIG" != "true" ]]; then
        echo "  - Configuration files (optional)"
    fi
    echo
    read -p "Are you sure you want to uninstall Cursor? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Uninstallation cancelled."
        exit 0
    fi
fi

log_info "Starting Cursor uninstallation..."

# Remove Cursor AppImage from /opt/cursor
if [[ -d "/opt/cursor" ]]; then
    log_info "Removing Cursor AppImage from /opt/cursor (requires sudo)"
    sudo rm -rf "/opt/cursor"
else
    log_warn "Cursor installation directory not found at /opt/cursor"
fi

# Remove command wrapper
if [[ -f "$HOME/.local/bin/cursor" ]]; then
    log_info "Removing cursor command wrapper"
    rm -f "$HOME/.local/bin/cursor"
else
    log_warn "Cursor command wrapper not found"
fi

# Remove desktop entry
if [[ -f "$HOME/.local/share/applications/cursor.desktop" ]]; then
    log_info "Removing desktop entry"
    rm -f "$HOME/.local/share/applications/cursor.desktop"
else
    log_warn "Cursor desktop entry not found"
fi

# Remove icons
log_info "Removing Cursor icons"
find "$HOME/.local/share/icons" -name "*cursor*" -type f -delete 2>/dev/null || true

# Update desktop database
if command -v update-desktop-database &>/dev/null; then
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
fi

# Handle configuration files
if [[ "$KEEP_CONFIG" != "true" ]]; then
    if [[ -d "$HOME/.config/Cursor" ]]; then
        if [[ "$FORCE" == "true" ]]; then
            REMOVE_CONFIG="y"
        else
            echo
            read -p "Do you want to remove Cursor configuration files? (y/N) " -n 1 -r REMOVE_CONFIG
            echo
        fi
        
        if [[ $REMOVE_CONFIG =~ ^[Yy]$ ]]; then
            log_info "Removing Cursor configuration files"
            rm -rf "$HOME/.config/Cursor"
        else
            log_info "Keeping Cursor configuration files"
        fi
    fi
fi

# Clean up any remaining cursor processes
if command -v pkill &>/dev/null; then
    pkill -f "cursor" 2>/dev/null || true
fi

log_info "Cursor has been successfully uninstalled!"

# Check for any remaining files
REMAINING_FILES=()

if [[ -d "/opt/cursor" ]]; then
    REMAINING_FILES+=("/opt/cursor")
fi

if [[ -f "$HOME/.local/bin/cursor" ]]; then
    REMAINING_FILES+=("$HOME/.local/bin/cursor")
fi

if [[ -f "$HOME/.local/share/applications/cursor.desktop" ]]; then
    REMAINING_FILES+=("$HOME/.local/share/applications/cursor.desktop")
fi

if [[ ${#REMAINING_FILES[@]} -gt 0 ]]; then
    echo
    log_warn "Some files may still remain:"
    for file in "${REMAINING_FILES[@]}"; do
        echo "  - $file"
    done
    echo "You may need to remove these manually."
fi

echo
log_info "Uninstallation complete!"