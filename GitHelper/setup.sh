#!/usr/bin/env bash

set -e

# Default variables
GIT_NAME=""
GIT_EMAIL=""
GITHUB_TOKEN=""
SKIP_GITHUB=false
KEY_TYPE="ed25519"

# Help message
function show_help {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -n, --name <name>       Your Git username (e.g., 'John Doe')"
    echo "  -e, --email <email>     Your Git email address (e.g., 'john@example.com')"
    echo "  -t, --token <token>     Your GitHub Personal Access Token (classic with 'admin:public_key' or fine-grained)"
    echo "  -k, --key-type <type>   SSH key type to generate (rsa or ed25519). Default: ed25519"
    echo "  -s, --skip-github       Skip uploading the SSH key to GitHub"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "If options are omitted, the script will run interactively and prompt for them."
}

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -n|--name) GIT_NAME="$2"; shift ;;
        -e|--email) GIT_EMAIL="$2"; shift ;;
        -t|--token) GITHUB_TOKEN="$2"; shift ;;
        -k|--key-type) KEY_TYPE="$2"; shift ;;
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

# 2. Generate SSH Key
SSH_KEY_FILE="$HOME/.ssh/id_$KEY_TYPE"
if [ "$KEY_TYPE" == "rsa" ]; then
    SSH_KEY_FILE="$HOME/.ssh/id_rsa"
fi

echo ""
echo "[*] Checking for existing SSH keys..."
if [ -f "$SSH_KEY_FILE" ]; then
    echo "    -> SSH key already exists at $SSH_KEY_FILE"
    echo "    -> Skipping key generation."
else
    echo "    -> Generating new $KEY_TYPE SSH key..."
    # -N "" means no passphrase for fully automated, but we could prompt for it.
    # For a helper, we will use an empty passphrase for automation, or let ssh-keygen prompt if we don't pass -N.
    # To keep it configurable but smooth, we'll set no passphrase.
    ssh-keygen -t "$KEY_TYPE" -C "$GIT_EMAIL" -f "$SSH_KEY_FILE" -N "" -q
    echo "    -> SSH key generated at $SSH_KEY_FILE"
fi

# 3. Start ssh-agent and add key
echo ""
echo "[*] Adding SSH key to the ssh-agent..."
# Start the ssh-agent in the background
eval "$(ssh-agent -s)" > /dev/null
ssh-add "$SSH_KEY_FILE"

# 4. Upload to GitHub
echo ""
if [ "$SKIP_GITHUB" = true ]; then
    echo "[*] Skipping GitHub SSH key upload as requested."
else
    if [ -z "$GITHUB_TOKEN" ]; then
        read -s -p "Enter your GitHub Personal Access Token (leave empty to skip): " GITHUB_TOKEN
        echo ""
    fi

    if [ -n "$GITHUB_TOKEN" ]; then
        echo "[*] Uploading SSH key to GitHub..."

        # Read the public key
        PUB_KEY=$(cat "${SSH_KEY_FILE}.pub")
        TITLE="$(hostname)-$(date +'%Y-%m-%d')"

        # Call GitHub API
        RESPONSE=$(curl -s -w "%{http_code}" -X POST \
            -H "Accept: application/vnd.github+json" \
            -H "Authorization: Bearer $GITHUB_TOKEN" \
            -H "X-GitHub-Api-Version: 2022-11-28" \
            https://api.github.com/user/keys \
            -d "{\"title\":\"$TITLE\",\"key\":\"$PUB_KEY\"}")

        HTTP_CODE=${RESPONSE:${#RESPONSE}-3}
        BODY=${RESPONSE:0:${#RESPONSE}-3}

        if [ "$HTTP_CODE" == "201" ]; then
            echo "    -> Successfully uploaded SSH key to GitHub!"
        elif [ "$HTTP_CODE" == "422" ]; then
            echo "    -> GitHub API returned 422: The key might already exist on your account."
        else
            echo "    -> Failed to upload SSH key. HTTP Code: $HTTP_CODE"
            echo "    -> Response: $BODY"
        fi
    else
        echo "[*] No GitHub token provided. Skipping GitHub upload."
        echo "    -> Here is your public key if you want to add it manually:"
        cat "${SSH_KEY_FILE}.pub"
    fi
fi

echo ""
echo "======================================"
echo "          Setup Complete!             "
echo "======================================"
echo "You can test your connection by running:"
echo "ssh -T git@github.com"
