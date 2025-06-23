# Enhanced Ubuntu Cursor AppImage Installer

A comprehensive shell script to automatically download, install, and configure Cursor AppImage on Linux with full desktop integration and advanced features. This was created because the official installer is not available for Linux, This will most likely not be maintained or updated as I am no longer using Cursor due to the lack of transparency from the Cursor team. I do not support Cursor and I do not recommend using it. I decided to create this a few months ago and hope it helps someone.

## ✨ Features

- 🚀 **Automatic download** from official Cursor API
- 📦 **Multiple installation options** (stable/latest releases, local AppImage)
- 🔄 **Easy updates** with version tracking
- 🏗️ **Multi-architecture support** (x64/ARM64)
- 🛠️ **FUSE dependency handling** (automatic installation)
- 📱 **Complete desktop integration** (applications menu, icons)
- ⌨️ **Command-line interface** like VS Code's `code` command
- 🎯 **Proper system organization** (installs to `/opt/cursor`)
- 🗑️ **Clean uninstaller** included
- 🛡️ **AppImage sandbox handling** (automatic `--no-sandbox` flag)

## 🚀 Quick Installation

### Download and Install Latest Stable Version
```bash
curl -fsSL https://raw.githubusercontent.com/Jordan-Jarvis/ubuntu-cursor-appimage-installer/main/install-cursor.sh | bash
```

### Or Download Script First
```bash
wget https://raw.githubusercontent.com/Jordan-Jarvis/ubuntu-cursor-appimage-installer/main/install-cursor.sh
chmod +x install-cursor.sh
./install-cursor.sh
```

## 📋 Installation Options

### Automatic Download (Recommended)
```bash
# Install stable version (default)
./install-cursor.sh

# Install latest version
./install-cursor.sh --latest

# Install stable version explicitly
./install-cursor.sh --stable
```

### Install from Local AppImage
```bash
# Install from local file
./install-cursor.sh /path/to/Cursor-*.AppImage

# Auto-detect in common locations
./install-cursor.sh
```

### Update Existing Installation
```bash
# Update to latest stable
./install-cursor.sh --update

# Update to latest version
./install-cursor.sh --update --latest

# Check current version
./install-cursor.sh --version
```

## 🖥️ Usage

After installation, you can use Cursor in multiple ways:

### Terminal Commands
```bash
cursor                    # Launch Cursor
cursor .                  # Open current directory
cursor /path/to/project   # Open specific directory
cursor file.js            # Open specific file
cursor --version          # Show version
cursor --help             # Show help
```

### Applications Menu
Cursor will appear in your applications menu under "Development" category with proper icon.

## 🔧 Command Line Options

### Installer Options
```bash
./install-cursor.sh [options] [path-to-appimage]

Options:
  --stable      Download stable version (default)
  --latest      Download latest version  
  --update      Update existing installation
  --version     Show installed version
  --help        Show help message

Examples:
  ./install-cursor.sh                              # Install stable
  ./install-cursor.sh --latest                     # Install latest
  ./install-cursor.sh --update                     # Update to stable
  ./install-cursor.sh --update --latest            # Update to latest
  ./install-cursor.sh /path/to/cursor.AppImage     # Install local file
```

## 🗑️ Uninstalling

### Quick Uninstall
```bash
curl -fsSL https://raw.githubusercontent.com/Jordan-Jarvis/ubuntu-cursor-appimage-installer/main/uninstall-cursor.sh | bash
```

### Download Uninstaller First
```bash
wget https://raw.githubusercontent.com/Jordan-Jarvis/ubuntu-cursor-appimage-installer/main/uninstall-cursor.sh
chmod +x uninstall-cursor.sh
./uninstall-cursor.sh
```

### Uninstaller Options
```bash
./uninstall-cursor.sh [options]

Options:
  --force         Skip confirmation prompts
  --keep-config   Keep configuration files
  --help          Show help message
```

### Manual Uninstall
```bash
sudo rm -rf /opt/cursor
rm -f ~/.local/bin/cursor
rm -f ~/.local/share/applications/cursor.desktop
find ~/.local/share/icons -name "*cursor*" -delete
rm -rf ~/.config/Cursor  # Optional: removes settings
```

## 🔍 What the Installer Does

1. **System Integration**: 
   - Downloads latest Cursor AppImage from official API
   - Installs to `/opt/cursor` for proper system organization
   - Supports both stable and latest release tracks

2. **Command Line Access**: 
   - Creates wrapper script in `~/.local/bin/cursor`
   - Launches with `--no-sandbox` flag (required for AppImages)
   - Runs detached from terminal
   - Accepts file/directory arguments like VS Code

3. **Desktop Integration**: 
   - Creates `.desktop` file for applications menu
   - Extracts and installs proper Cursor icon
   - Updates desktop database

4. **Dependency Management**:
   - Automatically detects and installs FUSE if needed
   - Supports multiple package managers (apt, dnf, pacman)

5. **Version Management**:
   - Tracks installed version
   - Supports easy updates
   - Version checking via command line

6. **PATH Configuration**: 
   - Ensures `~/.local/bin` is in PATH
   - Adds to `.bashrc` if needed

## 📋 Requirements

- Linux system with sudo access
- `curl` for downloading
- `jq` for JSON parsing (auto-installed if missing)
- Standard tools: `bash`, `sudo`, `mktemp`, `realpath`

## 🏗️ Architecture Support

- **x86_64** (Intel/AMD 64-bit)
- **aarch64** (ARM 64-bit)

## 🐛 Troubleshooting

### "cursor: command not found"
Restart your terminal or run:
```bash
source ~/.bashrc
```

### "FUSE not installed"
The script will attempt to install FUSE automatically. If it fails:
```bash
# Ubuntu/Debian
sudo apt-get install fuse

# Fedora
sudo dnf install fuse

# Arch Linux
sudo pacman -S fuse2
```

### Download fails
- Check internet connection
- Verify the Cursor API is accessible
- Try installing from a local AppImage file instead

### Permission denied errors
- Ensure you have sudo access
- Don't run the script as root
- Check file permissions

### AppImage won't launch
- Verify FUSE is installed and working
- Check if AppImage has execute permissions
- Try running manually: `/opt/cursor/cursor.AppImage --no-sandbox`

## 🆚 Comparison with Other Installers

This installer is inspired by and improves upon existing solutions:

### Key Advantages
- **Automatic downloads** from official API
- **Version management** with update capability
- **Multi-architecture** support (x64/ARM64)
- **FUSE handling** across multiple distros
- **Better error handling** and user feedback
- **Comprehensive uninstaller**
- **More robust** PATH and desktop integration

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

### Development
```bash
git clone https://github.com/Jordan-Jarvis/ubuntu-cursor-appimage-installer.git
cd ubuntu-cursor-appimage-installer
# Make your changes
./install-cursor.sh --help  # Test your changes
```

## 📄 License

MIT License - feel free to modify and distribute.

## 🙏 Acknowledgments

- Inspired by [watzon/cursor-linux-installer](https://github.com/watzon/cursor-linux-installer)
- Thanks to the Cursor team for the excellent editor, despite the lack of support for Linux, and lack of transparency.
- Community feedback and contributions