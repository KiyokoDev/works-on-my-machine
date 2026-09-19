#!/usr/bin/env bash

set -e

# Default variables
GIT_NAME=""
GIT_EMAIL=""
SKIP_GITHUB=false

# Help message
function show_help {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -n, --name <name>       Your Git username (e.g., 'John Doe')"
    echo "  -e, --email <email>     Your Git email address (e.g., 'john@example.com')"
    echo "  -s, --skip-github       Skip GitHub authentication and key upload"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "If options are omitted, the script will run interactively and prompt for them."
}

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -n|--name) GIT_NAME="$2"; shift ;;
        -e|--email) GIT_EMAIL="$2"; shift ;;
        -s|--skip-github) SKIP_GITHUB=true ;;
        -h|--help) show_help; exit 0 ;;
        *) echo "Unknown parameter passed: $1"; show_help; exit 1 ;;
    esac
    shift
done

echo "======================================"
echo "    Git & GitHub Setup Helper tool    "
echo "======================================"
echo ""

# Interactive prompts if missing
if [ -z "$GIT_NAME" ]; then
    read -p "Enter your Git Name (e.g., John Doe): " GIT_NAME
fi

if [ -z "$GIT_EMAIL" ]; then
    read -p "Enter your Git Email (e.g., john@example.com): " GIT_EMAIL
fi

# 1. Configure Git
echo "[*] Configuring Git user.name and user.email..."
git config --global user.name "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"
echo "    -> Git configured: $(git config --global user.name) <$(git config --global user.email)>"

# Helper function to install gh cli
install_gh() {
    echo "[*] GitHub CLI (gh) is not installed. Attempting to install it..."

    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_LIKE=$ID_LIKE
    else
        echo "    -> Could not detect OS. Please install GitHub CLI manually: https://cli.github.com/"
        return 1
    fi

    # Using sudo if available, else attempt as root
    SUDO=''
    if command -v sudo >/dev/null 2>&1; then
        SUDO='sudo'
    fi

    if [[ "$OS" == "ubuntu" || "$OS" == "debian" || "$OS_LIKE" == *"debian"* || "$OS_LIKE" == *"ubuntu"* ]]; then
        echo "    -> Detected Debian/Ubuntu based system."
        # Official installation method for debian/ubuntu
        $SUDO mkdir -p -m 755 /etc/apt/keyrings
        wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | $SUDO tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
        $SUDO chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | $SUDO tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        $SUDO apt update
        $SUDO apt install gh -y
    elif [[ "$OS" == "arch" || "$OS_LIKE" == *"arch"* ]]; then
        echo "    -> Detected Arch based system."
        $SUDO pacman -S --noconfirm github-cli
    elif [[ "$OS" == "fedora" || "$OS_LIKE" == *"fedora"* ]]; then
        echo "    -> Detected Fedora based system."
        $SUDO dnf install -y gh
    elif [[ "$OS" == "centos" || "$OS" == "rhel" ]]; then
        echo "    -> Detected CentOS/RHEL based system."
        $SUDO dnf install -y "dnf-command(config-manager)"
        $SUDO dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
        $SUDO dnf install -y gh
    elif [[ "$OS" == "opensuse"* || "$OS_LIKE" == *"suse"* ]]; then
        echo "    -> Detected openSUSE based system."
        $SUDO zypper addrepo https://cli.github.com/packages/rpm/gh-cli.repo
        $SUDO zypper ref
        $SUDO zypper install -y gh
    elif [[ "$OS" == "alpine" ]]; then
        echo "    -> Detected Alpine Linux."
        $SUDO apk add github-cli
    else
        echo "    -> Unsupported OS for automatic installation ($OS). Please install GitHub CLI manually: https://cli.github.com/"
        return 1
    fi

    if command -v gh >/dev/null 2>&1; then
        echo "    -> GitHub CLI installed successfully."
        return 0
    else
        echo "    -> Failed to install GitHub CLI automatically."
        return 1
    fi
}


# 2. GitHub Setup via CLI
echo ""
if [ "$SKIP_GITHUB" = true ]; then
    echo "[*] Skipping GitHub setup as requested."
else
    # Check if gh is installed, try to install if not
    if ! command -v gh >/dev/null 2>&1; then
        install_gh || exit 1
    fi

    echo "[*] Logging into GitHub and setting up SSH key..."
    echo "    -> The GitHub CLI will now guide you through the login process."
    echo "    -> If prompted, select 'SSH' as your preferred protocol."
    echo "    -> Select 'Generate a new SSH key' to have one automatically created and uploaded."
    echo "    -> You can simply follow the on-screen prompts."
    echo "--------------------------------------------------------"

    gh auth login -p ssh -s admin:public_key

    echo "--------------------------------------------------------"
    echo "[*] GitHub authentication complete!"
fi

echo ""
echo "======================================"
echo "          Setup Complete!             "
echo "======================================"
echo "You can test your connection by running:"
echo "ssh -T git@github.com"
