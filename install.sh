#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "======================================="
echo " Minimal Ubuntu Proot Installer"
echo " Normal User + Sudo + Timezone Auto-Set"
echo "======================================="
echo

# --------- Checks ----------
if ! command -v proot-distro >/dev/null 2>&1; then
  echo "[*] Installing proot-distro..."
  pkg update -y
  pkg install -y proot-distro
fi

# --------- Username ----------
while true; do
  read -rp "Enter Linux username (lowercase, no spaces): " USERNAME
  if [[ "$USERNAME" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
    break
  else
    echo "❌ Invalid username. Use lowercase letters/numbers only."
  fi
done

# --------- Password ----------
echo
echo "Set sudo password for user '$USERNAME'"
while true; do
  read -rsp "Password: " PASS1
  echo
  read -rsp "Confirm Password: " PASS2
  echo
  [[ "$PASS1" == "$PASS2" && -n "$PASS1" ]] && break
  echo "❌ Passwords do not match. Try again."
done

# --------- Timezone Detection ----------
echo
echo "[*] Detecting timezone from Android..."

TZ_ANDROID="$(getprop persist.sys.timezone || true)"

if [[ -z "$TZ_ANDROID" ]]; then
  TZ_ANDROID="UTC"
  echo "⚠️ Timezone not detected, defaulting to UTC"
else
  echo "✔ Detected timezone: $TZ_ANDROID"
fi

# --------- Install Ubuntu ----------
if ! proot-distro list | grep -q "ubuntu"; then
  echo
  echo "[*] Installing minimal Ubuntu..."
  proot-distro install ubuntu
fi

# --------- Setup Inside Ubuntu ----------
echo
echo "[*] Configuring Ubuntu..."

proot-distro login ubuntu -- bash <<EOF
set -e

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

# Cleanup
apt purge -y snapd man-db info || true
apt autoremove -y
apt clean

EOF

# --------- Done ----------
echo
echo "======================================="
echo " ✅ Installation Complete"
echo "======================================="
echo
echo "Login with:"
echo "proot-distro login ubuntu --user $USERNAME"
echo
echo "Optional (Android storage):"
echo "termux-setup-storage"
echo "proot-distro login ubuntu --user $USERNAME \\"
echo "  --bind /sdcard:/home/$USERNAME/storage"
echo
echo "Enjoy your minimal Ubuntu 🚀"
