#!/usr/bin/env bash
set -euo pipefail

# ── CachyOS Post-Install Script ──────────────────────────────────────────────
# For fresh CachyOS install (no DE, no display manager)
# Installs: Paru, Noctalia Shell V5, Umbriel, Kitty, MapleMono,
#           greetd, noctalia plugins, git, opencode, zed, dolphin, floorp, mpv, zsh
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
UMBRIEL_DIR="/tmp/umbriel-build"

aur_install() {
    sudo -u "$REAL_USER" paru -S --needed --noconfirm "$@"
}

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║        CachyOS Post-Install Setup Script                   ║"
echo "║  Noctalia Shell V5 + Umbriel + Kitty + Tools              ║"
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

# ── Step 4: Build Umbriel from source ────────────────────────────────────────
if command -v umbriel &>/dev/null; then
    ok "Umbriel already installed, skipping."
else
    info "Building Umbriel compositor from source..."

    UMBRIEL_BUILD_DEPS=(
        gcc
        meson
        ninja
        pkgconf
        git
        wayland
        wayland-protocols
        wlroots0.20
        libinput
        systemd-libs
        pixman
        libdrm
        cairo
        pango
        libxkbcommon
        tomlplusplus
        nlohmann-json
    )

    pacman -S --needed --noconfirm "${UMBRIEL_BUILD_DEPS[@]}"

    rm -rf "$UMBRIEL_DIR"
    sudo -u "$REAL_USER" git clone https://github.com/noctalia-dev/umbriel.git "$UMBRIEL_DIR"

    sudo -u "$REAL_USER" bash -c "
        cd '$UMBRIEL_DIR'
        meson setup build --buildtype=release --prefix=/usr
        meson compile -C build
    "

    cd "$UMBRIEL_DIR/build"
    meson install
    cd /
    rm -rf "$UMBRIEL_DIR"
    ok "Umbriel compositor built and installed."
fi

# ── Step 5: Install xwayland-satellite ───────────────────────────────────────
if pacman -Qi xwayland-satellite &>/dev/null; then
    ok "xwayland-satellite already installed, skipping."
else
    info "Installing xwayland-satellite (Xwayland support)..."
    pacman -S --needed --noconfirm xwayland-satellite
    ok "xwayland-satellite installed."
fi

# ── Step 6: Install Noctalia Greeter + greetd ───────────────────────────────
info "Installing greetd and dependencies..."
pacman -S --needed --noconfirm greetd cage dbus

if pacman -Qi noctalia-greeter &>/dev/null; then
    ok "Noctalia Greeter already installed, skipping."
else
    info "Installing Noctalia Greeter..."
    pacman -S --needed --noconfirm noctalia-greeter
    ok "Noctalia Greeter installed."
fi

# ── Step 7: Configure greetd ────────────────────────────────────────────────
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

# ── Step 8: Disable existing display manager ────────────────────────────────
CURRENT_DM=$(systemctl show display-manager.service -p Unit --value 2>/dev/null || true)
if [[ -n "$CURRENT_DM" && "$CURRENT_DM" != "greetd.service" ]]; then
    warn "Disabling existing display manager: $CURRENT_DM"
    systemctl disable --now "$CURRENT_DM"
    ok "Previous display manager disabled."
else
    ok "No conflicting display manager found."
fi

# ── Step 9: Configure Noctalia Plugins ──────────────────────────────────────
info "Configuring Noctalia plugins (wallhaven, wallpaper-depth)..."
NOC_CONF="$REAL_HOME/.config/noctalia/noctalia.toml"
NOC_CONF_DIR="$(dirname "$NOC_CONF")"
mkdir -p "$NOC_CONF_DIR"

if ! grep -q 'noctalia/wallhaven' "$NOC_CONF" 2>/dev/null; then
    cat >> "$NOC_CONF" << 'EOF'
[plugins]
enabled = ["noctalia/wallhaven", "noctalia/wallpaper_depth", "noctalia/umbriel-companion"]

[[plugins.source]]
name = "official"
kind = "git"
location = "https://github.com/noctalia-dev/official-plugins"
enabled = true
EOF
    chown -R "$REAL_USER:$REAL_USER" "$NOC_CONF_DIR"
    ok "Noctalia plugins configured."
else
    ok "Noctalia plugins already configured, skipping."
fi

# ── Step 10: Install Kitty ───────────────────────────────────────────────────
if pacman -Qi kitty &>/dev/null; then
    ok "Kitty already installed, skipping."
else
    info "Installing Kitty terminal..."
    pacman -S --needed --noconfirm kitty
    ok "Kitty installed."
fi

# ── Step 11: Install MapleMono NF font ───────────────────────────────────────
if pacman -Qi maplemono-nf-unhinted &>/dev/null || ls "$REAL_HOME/.local/share/fonts/"*apleMono* &>/dev/null; then
    ok "MapleMono NF already installed, skipping."
else
    info "Installing MapleMono NF font (terminal glyphs + ligatures)..."
    aur_install maplemono-nf-unhinted
    ok "MapleMono NF installed."
fi

# ── Step 12: Configure Kitty with MapleMono ──────────────────────────────────
info "Configuring Kitty..."
KITTY_CONF="$REAL_HOME/.config/kitty"
mkdir -p "$KITTY_CONF"
chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.config"

cat > "$KITTY_CONF/kitty.conf" << KITTYCONF
# ── Font ─────────────────────────────────────────────────────────────────────
font_family      MapleMono NF
bold_font        MapleMono NF Bold
italic_font      MapleMono NF Italic
bold_italic_font MapleMono NF Bold Italic
font_size        12.0

# ── Cursor ───────────────────────────────────────────────────────────────────
cursor_shape          beam
cursor_blink_interval 0

# ── Scrollback ───────────────────────────────────────────────────────────────
scrollback_lines 10000

# ── Bell ─────────────────────────────────────────────────────────────────────
enable_audio_bell no

# ── Window ───────────────────────────────────────────────────────────────────
window_padding_width 4
hide_window_decorations no

# ── Tab Bar ──────────────────────────────────────────────────────────────────
tab_bar_edge   bottom
tab_bar_style  powerline
tab_powerline_style slanted
KITTYCONF

chown -R "$REAL_USER:$REAL_USER" "$KITTY_CONF"
ok "Kitty configured with MapleMono NF at size 12."

# ── Step 13: Install remaining packages ──────────────────────────────────────
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

# ── Step 14: Set zsh as default shell ────────────────────────────────────────
if [[ "$(getent passwd "$REAL_USER" | cut -d: -f7)" == "$(which zsh)" ]]; then
    ok "zsh already default shell for $REAL_USER, skipping."
else
    info "Installing zsh and setting as default shell..."
    pacman -S --needed --noconfirm zsh

    ZSH_BIN=$(which zsh)
    if ! grep -q "$ZSH_BIN" /etc/shells; then
        echo "$ZSH_BIN" >> /etc/shells
    fi

    sudo -u "$REAL_USER" chsh -s "$ZSH_BIN"
    ok "zsh set as default shell for $REAL_USER."
fi

# ── Step 15: Enable greetd service ──────────────────────────────────────────
if systemctl is-enabled greetd.service &>/dev/null; then
    ok "greetd already enabled, skipping."
else
    info "Enabling greetd service..."
    systemctl enable --now greetd.service
    ok "greetd enabled at boot."
fi

# ── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗"
echo -e "║                    SETUP COMPLETE                           ║"
echo -e "╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Installed:"
echo -e "  ${CYAN}Noctalia Shell V5${NC}  - Desktop shell"
echo -e "  ${CYAN}Umbriel${NC}           - Wayland compositor (built from source)"
echo -e "  ${CYAN}Noctalia Plugins${NC}  - wallhaven + wallpaper-depth"
echo -e "  ${CYAN}Noctalia Greeter${NC}  - Login screen (greetd)"
echo -e "  ${CYAN}Kitty${NC}             - Terminal with MapleMono NF @ 12pt"
echo -e "  ${CYAN}Paru${NC}              - AUR helper"
echo -e "  ${CYAN}Git${NC}               - Version control"
echo -e "  ${CYAN}OpenCode${NC}          - AI terminal agent"
echo -e "  ${CYAN}Zed${NC}               - Code editor"
echo -e "  ${CYAN}Dolphin${NC}           - File manager"
echo -e "  ${CYAN}Floorp${NC}            - Web browser"
echo -e "  ${CYAN}Hydra${NC}             - Game launcher"
echo -e "  ${CYAN}mpv${NC}               - Media player"
echo -e "  ${CYAN}fastfetch${NC}         - System info"
echo -e "  ${CYAN}zsh${NC}               - Default shell"
echo ""
echo -e "Reboot recommended. greetd will launch the Noctalia Greeter at login."
echo ""
