# works-on-my-machine

A collection of personal setup and automation scripts. Each folder is a self-contained toolkit for a specific environment or task.

## Scripts

| Folder | Script | Description |
|--------|--------|-------------|
| [CachySetup](CachySetup/) | [install.sh](CachySetup/install.sh) | Post-install automation for fresh CachyOS systems. Updates packages, swaps yay for Paru, builds Umbriel Wayland compositor, installs Noctalia Shell V5, SwayFX, greetd, Kitty with MapleMono NF, and various tools. Sets zsh as default shell and enables greetd at boot. |

## Usage

Each folder is independent. Check the folder's own README or script header for specific instructions.

```bash
# Example
cd CachySetup
chmod +x install.sh
./install.sh
```
