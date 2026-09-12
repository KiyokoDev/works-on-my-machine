# CachyOS Setup Script

Post-install script for Noctalia Shell V5 + Alacritty + tools.

## Usage

```bash
sudo ./install.sh
```

Reboot after it finishes.

## What It Does

1. Installs Paru (removes yay if found)
2. Installs Noctalia Shell V5
3. Sets up greetd with Noctalia Greeter (disables existing display manager)
4. Installs Alacritty with MapleMono NF font
5. Installs nano with syntax highlighting
6. Installs rtk and initializes it for opencode
7. Removes firefox
8. Installs opencode, zed, dolphin, floorp, hydra, mpv, fastfetch
9. Switches default shell to fish

## Packages Installed

| Package | Source | Purpose |
|---------|--------|---------|
| `noctalia` | [extra] | Desktop shell |
| `xwayland-satellite` | [extra] | Xwayland support |
| `noctalia-greeter` | [extra] | Login screen |
| `greetd` | [extra] | Display manager daemon |
| `cage` | [extra] | Compositor for greeter |
| `alacritty` | [extra] | Terminal |
| `maplemono-nf-unhinted` | AUR | Font |
| `nano` | [extra] | Text editor |
| `nano-syntax-highlighting` | AUR | Nano syntax colors |
| `paru` | AUR | AUR helper |
| `rtk` | AUR | Dev tool |
| `opencode` | [extra] | AI coding agent |
| `zed` | [extra] | Code editor |
| `dolphin` | [extra] | File manager |
| `floorp-bin` | AUR | Browser |
| `hydra-launcher-bin` | AUR | Game launcher |
| `mpv` | [extra] | Media player |
| `fastfetch` | [extra] | System info |
| `fish` | [extra] | Shell |

## Removed Packages

- `firefox` - replaced by floorp

## Troubleshooting

- **Greeter black screen**: `journalctl -u greetd -f`
- **Alacritty font missing**: `fc-cache -fv`
