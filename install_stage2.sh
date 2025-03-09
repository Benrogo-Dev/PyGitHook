#!/bin/sh

cd /etc/PyGitHook

# Install the correct venv package and git
echo "Installing APT dependencies ..."
PYTHON_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
VENV_PACKAGE="python${PYTHON_VERSION}-venv"
apt install "$VENV_PACKAGE"

# Create a virtual environment for the app
echo "Creating Python virtual environment ..."
python3 -m venv .venv

# Install Pip dependencies
echo "Installing Pip dependencies..."
.venv/bin/pip3 install flask python-dotenv gunicorn

repository_folder=$(whiptail --title "Repository Folder" \
                             --inputbox "Enter the absolute path to the repository folder:" \
                             15 60 3>&1 1>&2 2>&3)

secret=$(whiptail --title "GitHub Webhook secret" \
                  --passwordbox "Type your webhook secret:" \
                  15 60 3>&1 1>&2 2>&3)

# Create the .env file
echo "Creating .env config"
cat > "app/.env" <<EOF
GITHOOK_SECRET = "$secret"
REPO_DIR = "$repository_folder"
EOF

# Instal systemd service and start it
echo "Installing systemd service..."
cat > "/etc/systemd/system/pygithook.service" <<EOF
[Unit]
Description=PyGitHook service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/PyGitHook/app
ExecStart=/etc/PyGitHook/.venv/bin/gunicorn --workers=4 --bind 0.0.0.0:5500 --threads=4 --timeout 600 app:app
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --now pygithook

# Final message
echo "\nPyGitHook should now be running at http://0.0.0.0:5000"