# CachyOS Setup Script

Post-install script for Noctalia Shell V5 + Alacritty + plugins + tools.

## Usage

```bash
sudo ./install.sh
```

Reboot after it finishes.

## What It Does

1. Installs Paru (removes yay if found)
2. Installs Noctalia Shell V5
3. Sets up greetd with Noctalia Greeter (disables existing display manager)
4. Enables Noctalia plugins: wallhaven, wallpaper-depth, keybind-cheatsheet, ai-usagebar
5. Installs Alacritty with MapleMono NF font
6. Installs nano with syntax highlighting
7. Installs rtk and initializes it for opencode
8. Removes vim and firefox
9. Installs opencode, zed, dolphin, floorp, hydra, mpv, fastfetch
10. Switches default shell to zsh

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
| `ai-usagebar-bin` | AUR | AI usage CLI for Noctalia plugin |
| `paru` | AUR | AUR helper |
| `rtk` | AUR | Dev tool |
| `opencode` | [extra] | AI coding agent |
| `zed` | [extra] | Code editor |
| `dolphin` | [extra] | File manager |
| `floorp-bin` | AUR | Browser |
| `hydra-launcher-bin` | AUR | Game launcher |
| `mpv` | [extra] | Media player |
| `fastfetch` | [extra] | System info |
| `zsh` | [extra] | Shell |

## Removed Packages

- `vim` - replaced by nano
- `firefox` - replaced by floorp

## Noctalia Plugins

- **wallhaven** - Browse Wallhaven wallpapers from bar widget
- **wallpaper-depth** - Place desktop widgets behind foreground scenery
- **keybind-cheatsheet** - Searchable keybind panel (Hyprland/Mango/Niri)
- **ai-usagebar** - Track AI plan usage in bar

Plugins configured in `~/.config/noctalia/noctalia.toml`. Active on first login.

## Troubleshooting

- **Greeter black screen**: `journalctl -u greetd -f`
- **Alacritty font missing**: `fc-cache -fv`
- **ai-usagebar not showing**: configure providers in `~/.config/ai-usagebar/config.toml`
