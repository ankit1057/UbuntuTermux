#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

###############################################################################
# Minimal Ubuntu Proot Installer (PIPE-SAFE)
# - Works with: wget -qO- URL | bash
# - Normal user + sudo
# - Android timezone autodetect
###############################################################################

# Ensure we can read from a real TTY even when piped
if [ ! -t 0 ]; then
  TTY=/dev/tty
else
  TTY=/dev/stdin
fi

echo "=======================================" >"$TTY"
echo " Minimal Ubuntu Proot Installer" >"$TTY"
echo " Normal User + Sudo + Timezone Auto-Set" >"$TTY"
echo "=======================================" >"$TTY"
echo >"$TTY"

###############################################################################
# Termux sanity checks
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
  read -r -p "Enter Linux username (lowercase, no spaces): " USERNAME <"$TTY"
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
# Timezone detection (Android)
###############################################################################

echo >"$TTY"
echo "[*] Detecting Android timezone..." >"$TTY"

TZ_ANDROID="$(getprop persist.sys.timezone 2>/dev/null || true)"

if [[ -z "$TZ_ANDROID" ]]; then
  TZ_ANDROID="UTC"
  echo "⚠️  Timezone not detected. Defaulting to UTC." >"$TTY"
else
  echo "✔ Detected timezone: $TZ_ANDROID" >"$TTY"
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

# Timezone
ln -sf /usr/share/zoneinfo/$TZ_ANDROID /etc/localtime
echo "$TZ_ANDROID" > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata

# User
if ! id "$USERNAME" >/dev/null 2>&1; then
  useradd -m -s /bin/bash "$USERNAME"
fi

echo "$USERNAME:$PASS1" | chpasswd
usermod -aG sudo "$USERNAME"

# Cleanup (keep minimal)
apt purge -y snapd man-db info || true
apt autoremove -y
apt clean
EOF

###############################################################################
# Done
###############################################################################

echo >"$TTY"
echo "=======================================" >"$TTY"
echo " ✅ Installation Complete" >"$TTY"
echo "=======================================" >"$TTY"
echo >"$TTY"
echo "Login with:" >"$TTY"
echo "  proot-distro login ubuntu --user $USERNAME" >"$TTY"
echo >"$TTY"
echo "Optional (Android storage):" >"$TTY"
echo "  termux-setup-storage" >"$TTY"
echo "  proot-distro login ubuntu --user $USERNAME \\" >"$TTY"
echo "    --bind /sdcard:/home/$USERNAME/storage" >"$TTY"
echo >"$TTY"
echo "Enjoy your minimal Ubuntu 🚀" >"$TTY"
