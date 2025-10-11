#!/bin/bash
set -e

# GitHub Actions Runner Installation Script
# Installs and configures a self-hosted runner on the Docker host

echo "================================================"
echo "GitHub Actions Self-Hosted Runner Installation"
echo "================================================"
echo ""

# Configuration
RUNNER_USER="runner"
RUNNER_DIR="/home/$RUNNER_USER/actions-runner"
REPO_URL="https://github.com/scottcoggin/ct-infrastructure"
RUNNER_VERSION="2.311.0"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "[ERROR] This script must be run as root"
  echo "   Run: sudo $0"
  exit 1
fi

# Check if runner already installed
if [ -d "$RUNNER_DIR" ] && [ -f "$RUNNER_DIR/config.sh" ]; then
  echo "[WARNING] Runner directory already exists at $RUNNER_DIR"
  echo "   To reinstall, first remove the existing runner:"
  echo "   1. Stop service: cd $RUNNER_DIR && sudo ./svc.sh stop"
  echo "   2. Uninstall: sudo ./svc.sh uninstall"
  echo "   3. Remove dir: rm -rf $RUNNER_DIR"
  echo ""
  read -p "Continue anyway? (y/N): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

# Prompt for registration token
echo "You need a registration token from GitHub:"
echo ""
echo "1. Go to: https://github.com/scottcoggin/ct-infrastructure/settings/actions/runners/new"
echo "2. Select 'Linux' as the operating system"
echo "3. Copy the token from the configuration command"
echo "   (Starts with something like 'AABCD...')"
echo ""
read -p "Enter registration token: " RUNNER_TOKEN

if [ -z "$RUNNER_TOKEN" ]; then
  echo "[ERROR] Token cannot be empty"
  exit 1
fi

# Create runner user if it doesn't exist
if ! id "$RUNNER_USER" &>/dev/null; then
  echo "Creating user '$RUNNER_USER'..."
  useradd -m -s /bin/bash "$RUNNER_USER"
else
  echo "User '$RUNNER_USER' already exists"
fi

# Add runner user to docker group for container access
if getent group docker > /dev/null 2>&1; then
  echo "Adding '$RUNNER_USER' to docker group..."
  usermod -aG docker "$RUNNER_USER"
fi

# Create runner directory
echo ""
echo "Creating runner directory..."
mkdir -p "$RUNNER_DIR"
chown -R "$RUNNER_USER:$RUNNER_USER" "$RUNNER_DIR"

# Download and extract as runner user
echo "Downloading GitHub Actions runner v${RUNNER_VERSION}..."
su - "$RUNNER_USER" -c "cd $RUNNER_DIR && curl -o actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz -L \
  https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz"

echo "Extracting runner..."
su - "$RUNNER_USER" -c "cd $RUNNER_DIR && tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz"
su - "$RUNNER_USER" -c "cd $RUNNER_DIR && rm ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz"

# Configure runner as runner user
echo "Configuring runner..."
su - "$RUNNER_USER" -c "cd $RUNNER_DIR && ./config.sh --url \"$REPO_URL\" --token \"$RUNNER_TOKEN\" --unattended --replace"

# Grant runner user access to deployment directories
echo "Setting up deployment directory permissions..."
mkdir -p /root/docker/apps/datalab/cube/schema
chown -R "$RUNNER_USER:$RUNNER_USER" /root/docker/apps

# Allow runner user to traverse /root and /root/docker directories
chmod o+rx /root
chmod o+rx /root/docker

# Install as systemd service (must be root)
echo "Installing as systemd service..."
cd "$RUNNER_DIR"
./svc.sh install "$RUNNER_USER"

# Start service
echo "Starting runner service..."
./svc.sh start

# Verify status
echo ""
echo "[SUCCESS] Runner installation complete!"
echo ""
echo "Runner status:"
./svc.sh status

echo ""
echo "================================================"
echo "Next Steps:"
echo "================================================"
echo ""
echo "1. Verify runner in GitHub:"
echo "   https://github.com/scottcoggin/ct-infrastructure/settings/actions/runners"
echo "   (Should show as 'Idle' with green checkmark)"
echo ""
echo "2. Update workflow to use self-hosted runner"
echo "   (This should already be done if you're following the guide)"
echo ""
echo "3. Test by pushing a change to stacks/datalab/"
echo ""
echo "================================================"
echo "Useful Commands:"
echo "================================================"
echo ""
echo "Check status:   cd $RUNNER_DIR && sudo ./svc.sh status"
echo "Stop runner:    cd $RUNNER_DIR && sudo ./svc.sh stop"
echo "Start runner:   cd $RUNNER_DIR && sudo ./svc.sh start"
echo "View logs:      sudo journalctl -u actions.runner.* -f"
echo "Uninstall:      cd $RUNNER_DIR && sudo ./svc.sh uninstall"
echo ""
