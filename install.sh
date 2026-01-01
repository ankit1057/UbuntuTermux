#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

###############################################################################
# Minimal Ubuntu Proot Installer (PIPE + TTY SAFE)
# - Works with: wget -qO- URL | bash
# - Creates normal user + sudo
# - Auto-detects Android timezone
# - Adds `ubuntu` shortcut command
###############################################################################

# Ensure TTY access when piped
if [ -t 0 ]; then
  TTY="/dev/stdin"
else
  TTY="/dev/tty"
fi

echo "=======================================" >"$TTY"
echo " Minimal Ubuntu Proot Installer" >"$TTY"
echo " Normal User + Sudo + Auto Login Alias" >"$TTY"
echo "=======================================" >"$TTY"
echo >"$TTY"

###############################################################################
# Termux sanity check
###############################################################################

if ! command -v pkg >/dev/null 2>&1; then
  echo "❌ This script must be run inside Termux." >"$TTY"
  exit 1
fi

###############################################################################
# Ensure required tools
###############################################################################

if ! command -v proot-distro >/dev/null 2>&1; then
  echo "[*] Installing proot-distro..." >"$TTY"
  pkg update -y
  pkg install -y proot-distro
fi

###############################################################################
# Username input (TTY-safe)
###############################################################################

while true; do
  read -r -p "Enter Linux username (lowercase only): " USERNAME <"$TTY"
  if [[ "$USERNAME" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
    break
  else
    echo "❌ Invalid username. Use lowercase letters/numbers only." >"$TTY"
  fi
done

###############################################################################
# Password input (TTY-safe)
###############################################################################

echo >"$TTY"
echo "Set sudo password for user '$USERNAME'" >"$TTY"

while true; do
  read -rs -p "Password: " PASS1 <"$TTY"
  echo >"$TTY"
  read -rs -p "Confirm Password: " PASS2 <"$TTY"
  echo >"$TTY"

  if [[ -n "$PASS1" && "$PASS1" == "$PASS2" ]]; then
    break
  else
    echo "❌ Passwords do not match. Try again." >"$TTY"
  fi
done

###############################################################################
# Timezone detection
###############################################################################

echo >"$TTY"
echo "[*] Detecting Android timezone..." >"$TTY"

TZ_ANDROID="$(getprop persist.sys.timezone 2>/dev/null || true)"
if [[ -z "$TZ_ANDROID" ]]; then
  TZ_ANDROID="UTC"
  echo "⚠️  Timezone not detected, defaulting to UTC." >"$TTY"
else
  echo "✔ Timezone detected: $TZ_ANDROID" >"$TTY"
fi

###############################################################################
# Install Ubuntu (minimal)
###############################################################################

if ! proot-distro list | grep -q "^ubuntu"; then
  echo >"$TTY"
  echo "[*] Installing minimal Ubuntu..." >"$TTY"
  proot-distro install ubuntu
fi

###############################################################################
# Configure Ubuntu
###############################################################################

echo >"$TTY"
echo "[*] Configuring Ubuntu..." >"$TTY"

proot-distro login ubuntu -- bash <<EOF
set -e
export DEBIAN_FRONTEND=noninteractive

apt update
apt install -y sudo tzdata ca-certificates

ln -sf /usr/share/zoneinfo/$TZ_ANDROID /etc/localtime
echo "$TZ_ANDROID" > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata

if ! id "$USERNAME" >/dev/null 2>&1; then
  useradd -m -s /bin/bash "$USERNAME"
fi

echo "$USERNAME:$PASS1" | chpasswd
usermod -aG sudo "$USERNAME"

apt purge -y snapd man-db info || true
apt autoremove -y
apt clean
EOF

###############################################################################
# Create helper script + alias
###############################################################################

echo >"$TTY"
echo "[*] Creating ubuntu shortcut command..." >"$TTY"

BIN_DIR="$HOME/.local/bin"
HELPER="$BIN_DIR/ubuntu.sh"

mkdir -p "$BIN_DIR"

cat > "$HELPER" <<EOS
#!/data/data/com.termux/files/usr/bin/bash

STORAGE_BIND=""
if [ -d "/sdcard" ]; then
  STORAGE_BIND="--bind /sdcard:/home/$USERNAME/storage"
fi

exec proot-distro login ubuntu --user $USERNAME \$STORAGE_BIND
EOS

chmod +x "$HELPER"

BASHRC="$HOME/.bashrc"
if ! grep -q "alias ubuntu=" "$BASHRC" 2>/dev/null; then
  echo "" >>"$BASHRC"
  echo "# Ubuntu proot shortcut" >>"$BASHRC"
  echo "alias ubuntu='$HELPER'" >>"$BASHRC"
fi

###############################################################################
# Done
###############################################################################

echo >"$TTY"
echo "=======================================" >"$TTY"
echo " ✅ Installation Complete" >"$TTY"
echo "=======================================" >"$TTY"
echo >"$TTY"
echo "Restart Termux, then run:" >"$TTY"
echo "  ubuntu" >"$TTY"
echo >"$TTY"
echo "Android storage will auto-mount if permission is granted." >"$TTY"
echo "Enjoy your minimal Ubuntu 🚀" >"$TTY"
