# Cursor AppImage Installer

A shell script to properly install and configure Cursor AppImage on Linux with full desktop integration.

## Features

- 🚀 Installs Cursor AppImage to `/opt/cursor` for system-wide access
- 📱 Creates desktop entry for applications menu
- 🖼️ Extracts and sets proper application icon
- ⌨️ Creates `cursor` command for terminal usage (like VS Code's `code` command)
- 🔄 Easy updates by running script with new AppImage
- 🛡️ Handles AppImage sandbox issues automatically

## Installation

1. Download the Cursor AppImage from [cursor.sh](https://cursor.sh)
2. Download the installer script:
   ```bash
   wget https://raw.githubusercontent.com/Jordan-Jarvis/ubuntu-cursor-appimage-installer/main/install-cursor.sh
   chmod +x install-cursor.sh
   ```
3. Run the installer:
   ```bash
   ./install-cursor.sh /path/to/Cursor-*.AppImage
   ```
   
   Or if the AppImage is in your Downloads folder:
   ```bash
   ./install-cursor.sh
   ```

## Usage

After installation, you can use Cursor in several ways:

### Terminal Commands
```bash
cursor                    # Launch Cursor
cursor .                  # Open current directory
cursor /path/to/project   # Open specific directory
cursor file.js            # Open specific file
```

### Applications Menu
Cursor will appear in your applications menu under "Development" category.

## Updating

To update Cursor to a newer version:

1. Download the new AppImage
2. Run the installer again:
   ```bash
   ./install-cursor.sh /path/to/new/Cursor-*.AppImage
   ```

The script will automatically replace the old version and update all configurations.

## What the Script Does

1. **System Integration**: Installs AppImage to `/opt/cursor` for proper system organization
2. **Command Line Access**: Creates a wrapper script in `~/.local/bin/cursor` that:
   - Launches Cursor with `--no-sandbox` flag (required for AppImages)
   - Runs in background (detached from terminal)
   - Accepts file/directory arguments like VS Code
3. **Desktop Integration**: Creates a `.desktop` file for applications menu
4. **Icon Extraction**: Extracts the proper Cursor icon from the AppImage
5. **PATH Configuration**: Ensures `~/.local/bin` is in your PATH

## Requirements

- Linux system with sudo access
- Cursor AppImage file
- Standard tools: `bash`, `sudo`, `mktemp`, `realpath`

## Uninstalling

To remove Cursor:

```bash
sudo rm -rf /opt/cursor
rm -f ~/.local/bin/cursor
rm -f ~/.local/share/applications/cursor.desktop
update-desktop-database ~/.local/share/applications
```

## Troubleshooting

### "cursor: command not found"
Restart your terminal or run:
```bash
source ~/.bashrc
```

### Blank icon in applications menu
The script should extract the icon automatically. If it doesn't work, you can manually copy an icon to `/opt/cursor/cursor.png`.

### Permission denied errors
Make sure you have sudo access and the AppImage file is readable.

## License

MIT License - feel free to modify and distribute.