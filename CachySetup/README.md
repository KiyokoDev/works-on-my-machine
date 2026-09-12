# CachyOS Setup Script

Post-install script for Noctalia Shell V5 + Umbriel + SwayFX + Kitty + tools.

## Usage

```bash
sudo ./install.sh
```

Reboot after it finishes.

## What It Does

1. Updates system, removes yay if found, installs Paru
2. Installs Noctalia Shell V5, builds Umbriel from source
3. Installs SwayFX (removes sway if present, they conflict)
4. Sets up greetd with Noctalia Greeter
5. Enables Noctalia plugins: wallhaven, wallpaper-depth
6. Installs Kitty with MapleMono NF font
7. Installs opencode, zed, dolphin, floorp, hydra, mpv, fastfetch
8. Switches default shell to zsh

## Packages Installed

| Package | Source | Purpose |
|---------|--------|---------|
| `noctalia` | [extra] | Desktop shell |
| `umbriel` | source | Wayland compositor |
| `swayfx` | AUR | Wayland compositor (sway + effects) |
| `xwayland-satellite` | [extra] | Xwayland support |
| `noctalia-greeter` | AUR | Login screen |
| `greetd` | [extra] | Display manager daemon |
| `cage` | [extra] | Compositor for greeter |
| `kitty` | [extra] | Terminal |
| `maplemono-nf-unhinted` | AUR | Font |
| `paru` | AUR | AUR helper |
| `git` | [extra] | Version control |
| `opencode` | [extra] | AI coding agent |
| `zed` | [extra] | Code editor |
| `dolphin` | [extra] | File manager |
| `floorp-bin` | AUR | Browser |
| `hydra-launcher-bin` | AUR | Game launcher |
| `mpv` | [extra] | Media player |
| `fastfetch` | [extra] | System info |
| `zsh` | [extra] | Shell |

## Noctalia Plugins

- **wallhaven** - Browse Wallhaven wallpapers from bar widget
- **wallpaper-depth** - Place desktop widgets behind foreground scenery in wallpaper

Plugins configured directly in `~/.config/noctalia/noctalia.toml`. Active on first login.

## Troubleshooting

- **Umbriel won't build**: `pacman -S wlroots0.20`
- **Greeter black screen**: `journalctl -u greetd -f`
- **Kitty font missing**: `fc-cache -fv`
- **SwayFX conflicts with sway**: script removes sway automatically before installing swayfx
