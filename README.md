
# UbuntuTermux

A **minimal, production-grade Ubuntu Linux environment inside Termux**  
✔ No root  
✔ Normal Linux user  
✔ Sudo access  
✔ Auto timezone  
✔ One-command install  
✔ `ubuntu` shortcut command

---

## 🚀 One-Command Install (Fresh Termux)

Copy-paste **exactly this** into Termux:

```bash
yes | termux-change-repo && \
pkg update -y && pkg upgrade -y && \
pkg install -y wget proot-distro && \
wget -qO- https://raw.githubusercontent.com/ankit1057/UbuntuTermux/main/install.sh | bash
