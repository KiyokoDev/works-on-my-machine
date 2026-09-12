# works-on-my-machine

A collection of personal setup and automation scripts. Each folder is a self-contained toolkit for a specific environment or task.

## Scripts

| Folder | Script | Description |
|--------|--------|-------------|
| [CachySetup](CachySetup/) | [install.sh](CachySetup/install.sh) | Post-install automation for fresh CachyOS systems. Swaps yay for Paru, installs Noctalia Shell V5, greetd, Alacritty with MapleMono NF, nano with syntax highlighting, rtk, and various tools. Removes firefox. Sets fish as default shell. |

## Usage

Each folder is independent. Check the folder's own README or script header for specific instructions.

```bash
# Example
cd CachySetup
chmod +x install.sh
./install.sh
```
