#!/usr/bin/env bash
# =============================================================================
#  Node.js Latest Setup — Ubuntu 24
#  Menggunakan NodeSource repo (selalu dapat versi terbaru)
#  Usage: chmod +x setup-node.sh && ./setup-node.sh
# =============================================================================

set -euo pipefail

# ── Colours ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}[ERROR]${RESET} $*" >&2; exit 1; }
step()    { echo -e "\n${BOLD}${GREEN}━━━ $* ${RESET}"; }

# ── Banner ────────────────────────────────────────────────────────────────────
echo -e "${BOLD}${CYAN}"
echo "  ╔═══════════════════════════════════════════════╗"
echo "  ║   Node.js Latest Setup  •  Ubuntu 24          ║"
echo "  ║   via NodeSource  •  includes npm & npx        ║"
echo "  ╚═══════════════════════════════════════════════╝"
echo -e "${RESET}"

# ── 0. Hapus Node lama dari apt (kalau ada) ───────────────────────────────────
step "0/4  Bersihkan Node.js lama (apt)"

if dpkg -l nodejs &>/dev/null; then
    warn "Node.js versi lama ditemukan, menghapus…"
    sudo apt-get remove -y nodejs npm 2>/dev/null || true
    sudo apt-get autoremove -y 2>/dev/null || true
    success "Node.js lama dihapus"
else
    info "Tidak ada Node.js apt yang perlu dihapus"
fi

# ── 1. Dependensi ─────────────────────────────────────────────────────────────
step "1/4  Dependensi sistem"

sudo apt-get update -qq
sudo apt-get install -y --no-install-recommends \
    curl wget ca-certificates gnupg
success "Dependensi siap"

# ── 2. Tambah NodeSource repo (Node.js LTS terbaru) ──────────────────────────
step "2/4  Tambah NodeSource repository"

# Deteksi versi LTS terbaru dari NodeSource
# Saat ini Node 22 adalah LTS terbaru (codename: Jod)
NODE_MAJOR=22

info "Menggunakan Node.js ${NODE_MAJOR}.x (LTS terbaru)"

curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | sudo -E bash -

success "NodeSource repo ditambahkan"

# ── 3. Install Node.js ────────────────────────────────────────────────────────
step "3/4  Install Node.js"

sudo apt-get install -y nodejs
success "Node.js terinstall"

# ── 4. Verifikasi & global tools ──────────────────────────────────────────────
step "4/4  Verifikasi & setup npm global"

# Buat direktori npm global agar tidak perlu sudo saat install global package
NPM_GLOBAL="${HOME}/.npm-global"
mkdir -p "${NPM_GLOBAL}"
npm config set prefix "${NPM_GLOBAL}"

PROFILE_FILE="${HOME}/.bashrc"
[[ "${SHELL}" == *zsh ]] && PROFILE_FILE="${HOME}/.zshrc"

MARKER="# >>> Node.js npm-global"
if ! grep -qF "${MARKER}" "${PROFILE_FILE}" 2>/dev/null; then
    cat >> "${PROFILE_FILE}" <<EOF

${MARKER}
export PATH="\${HOME}/.npm-global/bin:\${PATH}"
EOF
    info "PATH npm global ditulis ke ${PROFILE_FILE}"
else
    info "PATH npm global sudah ada di ${PROFILE_FILE} — skipped"
fi

export PATH="${NPM_GLOBAL}/bin:${PATH}"

# Update npm ke versi terbaru
info "Update npm ke versi terbaru…"
npm install -g npm@latest
success "npm diupdate"

# ── Ringkasan ─────────────────────────────────────────────────────────────────
echo -e "\n${BOLD}${GREEN}╔══════════════════════════════════════════════╗"
echo    "║          Verifikasi Instalasi                ║"
echo -e "╚══════════════════════════════════════════════╝${RESET}"

echo -e "  ${GREEN}✔${RESET}  Node.js : $(node --version)"
echo -e "  ${GREEN}✔${RESET}  npm     : $(npm --version)"
echo -e "  ${GREEN}✔${RESET}  npx     : $(npx --version)"
echo -e "  ${GREEN}✔${RESET}  Lokasi  : $(which node)"

echo -e "\n${BOLD}${CYAN}Next steps:${RESET}"
echo "  1. Reload shell:        source ${PROFILE_FILE}"
echo "  2. Install global tool: npm install -g <package>  (tanpa sudo)"
echo "  3. Cek versi:           node -v && npm -v"
echo ""
success "Node.js siap digunakan! 🚀"

