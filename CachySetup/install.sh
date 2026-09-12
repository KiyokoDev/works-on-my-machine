#!/usr/bin/env bash
set -euo pipefail

# ── CachyOS Post-Install Script ──────────────────────────────────────────────
# For fresh CachyOS install (no DE, no display manager)
# Installs: Paru, Noctalia Shell V5, greetd, Alacritty, MapleMono,
#           Noctalia plugins, git, opencode, zed, nano, rtk, fish, and more
# ──────────────────────────────────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${CYAN}[INFO]${NC} $*"; }
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
err()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }

if [[ $EUID -ne 0 ]]; then
    err "Run this script as root: sudo ./install.sh"
    exit 1
fi

if [[ -z "${SUDO_USER:-}" || "$SUDO_USER" == "root" ]]; then
    err "Run via sudo from a regular user, not as root directly."
    exit 1
fi

REAL_USER="$SUDO_USER"
REAL_HOME=$(eval echo "~$REAL_USER")

aur_install() {
    sudo -u "$REAL_USER" paru -S --needed --noconfirm "$@"
}

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║        CachyOS Post-Install Setup Script                   ║"
echo "║  Noctalia Shell V5 + Alacritty + Plugins + Tools          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ── Step 1: Install base build tools ─────────────────────────────────────────
info "Installing base development packages..."
pacman -S --needed --noconfirm \
    base-devel \
    gcc \
    meson \
    ninja \
    pkgconf
ok "Base build tools installed."

# ── Step 2: Remove yay, install Paru ────────────────────────────────────────
info "Managing AUR helper (removing yay, installing paru)..."
if command -v yay &>/dev/null; then
    warn "yay detected. Removing..."
    pacman -Rns --noconfirm yay
    rm -rf "$REAL_HOME/.cache/yay"
    ok "yay and its cache removed."
fi

if command -v paru &>/dev/null; then
    ok "Paru already installed, skipping."
else
    info "Installing Paru..."
    PARU_TEMP="/tmp/paru-build"
    rm -rf "$PARU_TEMP"
    mkdir -p "$PARU_TEMP"
    chown "$REAL_USER:$REAL_USER" "$PARU_TEMP"
    sudo -u "$REAL_USER" bash -c "
        cd '$PARU_TEMP'
        git clone https://aur.archlinux.org/paru.git .
        makepkg -si --noconfirm
    "
    rm -rf "$PARU_TEMP"
    ok "Paru installed."
fi

# ── Step 3: Install Noctalia Shell V5 from [extra] ──────────────────────────
if pacman -Qi noctalia &>/dev/null; then
    ok "Noctalia Shell V5 already installed, skipping."
else
    info "Installing Noctalia Shell V5..."
    pacman -S --needed --noconfirm noctalia
    ok "Noctalia Shell V5 installed."
fi

# ── Step 4: Install xwayland-satellite ───────────────────────────────────────
if pacman -Qi xwayland-satellite &>/dev/null; then
    ok "xwayland-satellite already installed, skipping."
else
    info "Installing xwayland-satellite (Xwayland support)..."
    pacman -S --needed --noconfirm xwayland-satellite
    ok "xwayland-satellite installed."
fi

# ── Step 5: Install Noctalia Greeter + greetd ───────────────────────────────
info "Installing greetd and dependencies..."
pacman -S --needed --noconfirm greetd cage dbus

if pacman -Qi noctalia-greeter &>/dev/null; then
    ok "Noctalia Greeter already installed, skipping."
else
    info "Installing Noctalia Greeter..."
    pacman -S --needed --noconfirm noctalia-greeter
    ok "Noctalia Greeter installed."
fi

# ── Step 6: Configure greetd ────────────────────────────────────────────────
info "Configuring greetd..."

cat > /etc/greetd/config.toml << 'GREETERCONF'
[terminal]
vt = 1

[default_session]
command = "/usr/bin/noctalia-greeter-session"
user = "greeter"
GREETERCONF

if ! id greeter &>/dev/null; then
    useradd -M -G video -s /bin/nologin greeter
    ok "Created greeter user."
fi

mkdir -p /var/lib/noctalia-greeter
chown greeter:greeter /var/lib/noctalia-greeter

ok "greetd configured."

# ── Step 7: Disable existing display manager for next boot ──────────────────
DM_LINK="/etc/systemd/system/display-manager.service"
if [[ -L "$DM_LINK" ]]; then
    CURRENT_DM=$(readlink -f "$DM_LINK" 2>/dev/null || basename "$(readlink "$DM_LINK")")
    if [[ "$CURRENT_DM" != *"greetd"* ]]; then
        warn "Disabling existing display manager: $CURRENT_DM (will take effect on reboot)"
        systemctl disable "$(basename "$CURRENT_DM")" 2>/dev/null || true
        rm -f "$DM_LINK"
        systemctl enable greetd.service
        ok "Previous display manager disabled, greetd enabled for next boot."
    else
        ok "greetd is already the display manager."
    fi
else
    systemctl enable greetd.service 2>/dev/null || true
    ok "greetd enabled."
fi

# ── Step 8: Install Alacritty ───────────────────────────────────────────────
if pacman -Qi alacritty &>/dev/null; then
    ok "Alacritty already installed, skipping."
else
    info "Installing Alacritty terminal..."
    pacman -S --needed --noconfirm alacritty
    ok "Alacritty installed."
fi

# ── Step 11: Install MapleMono NF font ───────────────────────────────────────
if pacman -Qi maplemono-nf-unhinted &>/dev/null || ls "$REAL_HOME/.local/share/fonts/"*apleMono* &>/dev/null 2>&1; then
    ok "MapleMono NF already installed, skipping."
else
    info "Installing MapleMono NF font (terminal glyphs + ligatures)..."
    aur_install maplemono-nf-unhinted
    ok "MapleMono NF installed."
fi

# ── Step 12: Configure Alacritty with MapleMono ──────────────────────────────
info "Configuring Alacritty..."
ALACRITTY_CONF="$REAL_HOME/.config/alacritty"
mkdir -p "$ALACRITTY_CONF"
chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.config"

cat > "$ALACRITTY_CONF/alacritty.toml" << 'ALACRITTYCONF'
# ── Font ─────────────────────────────────────────────────────────────────────
[font]
size = 12.0

[font.normal]
family = "MapleMono NF"
style = "Regular"

[font.bold]
family = "MapleMono NF"
style = "Bold"

[font.italic]
family = "MapleMono NF"
style = "Italic"

[font.bold_italic]
family = "MapleMono NF"
style = "Bold Italic"

# ── Cursor ───────────────────────────────────────────────────────────────────
[cursor]
style = { shape = "Beam", blinking = "Off" }

# ── Scrolling ────────────────────────────────────────────────────────────────
[scrolling]
history = 10000

# ── Window ───────────────────────────────────────────────────────────────────
[window]
padding = { x = 4, y = 4 }
ALACRITTYCONF

chown -R "$REAL_USER:$REAL_USER" "$ALACRITTY_CONF"
ok "Alacritty configured with MapleMono NF at size 12."

# ── Step 13: Install nano + syntax highlighting ──────────────────────────────
if pacman -Qi nano &>/dev/null; then
    ok "nano already installed, skipping."
else
    info "Installing nano..."
    pacman -S --needed --noconfirm nano
    ok "nano installed."
fi

if pacman -Qi nano-syntax-highlighting &>/dev/null; then
    ok "nano-syntax-highlighting already installed, skipping."
else
    info "Installing nano syntax highlighting..."
    aur_install nano-syntax-highlighting
    ok "nano syntax highlighting installed."
fi

# ── Step 12: Remove firefox ──────────────────────────────────────────────────
if pacman -Qi firefox &>/dev/null; then
    info "Removing firefox..."
    pacman -Rns --noconfirm firefox
    ok "firefox removed."
else
    ok "firefox not installed, skipping."
fi

# ── Step 15: Install rtk ────────────────────────────────────────────────────
if command -v rtk &>/dev/null; then
    ok "rtk already installed, skipping."
else
    info "Installing rtk..."
    aur_install rtk
    ok "rtk installed."
fi

info "Initializing rtk for opencode..."
sudo -u "$REAL_USER" rtk init -g --opencode || warn "rtk init may have failed."

# ── Step 16: Install remaining packages ──────────────────────────────────────
info "Installing remaining packages..."
pacman -S --needed --noconfirm \
    opencode \
    zed \
    dolphin \
    mpv \
    fastfetch

info "Installing Floorp browser and Hydra game launcher..."
aur_install floorp-bin hydra-launcher-bin
ok "All packages installed."

# ── Step 17: Set fish as default shell ───────────────────────────────────────
if [[ "$(getent passwd "$REAL_USER" | cut -d: -f7)" == "$(which fish)" ]]; then
    ok "fish already default shell for $REAL_USER, skipping."
else
    info "Installing fish and setting as default shell..."
    pacman -S --needed --noconfirm fish

    FISH_BIN=$(which fish)
    if ! grep -q "$FISH_BIN" /etc/shells; then
        echo "$FISH_BIN" >> /etc/shells
    fi

    sudo -u "$REAL_USER" chsh -s "$FISH_BIN"
    ok "fish set as default shell for $REAL_USER."
fi

# ── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗"
echo -e "║                    SETUP COMPLETE                           ║"
echo -e "╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Installed:"
echo -e "  ${CYAN}Noctalia Shell V5${NC}  - Desktop shell"
echo -e "  ${CYAN}Noctalia Greeter${NC}  - Login screen (greetd)"
echo -e "  ${CYAN}Alacritty${NC}         - Terminal with MapleMono NF @ 12pt"
echo -e "  ${CYAN}nano${NC}              - Text editor with syntax highlighting"
echo -e "  ${CYAN}Paru${NC}              - AUR helper"
echo -e "  ${CYAN}rtk${NC}               - Dev tool"
echo -e "  ${CYAN}OpenCode${NC}          - AI terminal agent"
echo -e "  ${CYAN}Zed${NC}               - Code editor"
echo -e "  ${CYAN}Dolphin${NC}           - File manager"
echo -e "  ${CYAN}Floorp${NC}            - Web browser"
echo -e "  ${CYAN}Hydra${NC}             - Game launcher"
echo -e "  ${CYAN}mpv${NC}               - Media player"
echo -e "  ${CYAN}fastfetch${NC}         - System info"
echo -e "  ${CYAN}fish${NC}               - Default shell"
echo ""
echo -e "Removed: firefox"
echo ""
echo -e "Reboot recommended. greetd will launch the Noctalia Greeter at login."
echo ""
