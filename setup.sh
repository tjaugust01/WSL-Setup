#!/usr/bin/env bash
set -euo pipefail

SETUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Setting up Ubuntu/WSL development environment..."

if ! command -v apt >/dev/null 2>&1; then
  echo "Dieses Skript ist für Ubuntu/Debian-basierte Systeme gedacht."
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

echo "Aktualisiere Paketlisten..."
sudo apt update
sudo apt upgrade -y

echo "Installiere Basispakete..."
sudo apt install -y \
  zsh \
  git \
  curl \
  wget \
  unzip \
  tar \
  make \
  gcc \
  g++ \
  build-essential \
  ca-certificates \
  gnupg \
  lsb-release \
  software-properties-common \
  apt-transport-https \
  python3 \
  python3-pip \
  python3-venv \
  python3-full \
  fonts-powerline \
  neovim \
  nodejs \
  npm \
  php-cli \
  php-common \
  php-mbstring \
  php-xml \
  php-curl \
  php-zip \
  php-sqlite3 \
  php-intl \
  php-bcmath \
  php-gd \
  php-mysql \
  php-pgsql \
  php-soap \
  php-readline \
  golang-go \
  sqlite3 \
  postgresql \
  postgresql-contrib

echo "Basispakete installiert."

# ZSH setup
echo "Richte Oh My Zsh ein..."

if [ ! -d "$HOME/.oh-my-zsh" ]; then
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" --unattended
  echo "Oh My Zsh installiert."
else
  echo "Oh My Zsh bereits installiert – überspringe."
fi

if [ -f "$HOME/.zshrc" ]; then
  sed -i 's/plugins=(git)/plugins=(git npm yarn python pip golang rust docker)/' "$HOME/.zshrc" || true
  sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="agnoster"/' "$HOME/.zshrc" || true
fi

echo "Oh My Zsh customisiert."

CUSTOM_THEME="$SETUP_DIR/agnoster.zsh-theme"
TARGET_THEME="$HOME/.oh-my-zsh/themes/agnoster.zsh-theme"

if [ -f "$CUSTOM_THEME" ]; then
  if [ -f "$TARGET_THEME" ]; then
    cp "$TARGET_THEME" "$TARGET_THEME.bak"
    echo "Backup von $TARGET_THEME erstellt als $TARGET_THEME.bak."
  fi

  cp "$CUSTOM_THEME" "$TARGET_THEME"
  echo "Custom Agnoster-Theme kopiert."
else
  echo "Warnung: Custom Agnoster-Theme nicht gefunden – verwende Standard-Theme."
fi

# Neovim / NvChad
echo "Richte Neovim mit NvChad ein..."

if [ ! -d "$HOME/.config/nvim" ]; then
  git clone https://github.com/NvChad/NvChad "$HOME/.config/nvim" --depth 1
else
  echo "NvChad/Neovim-Konfiguration existiert bereits – überspringe Clone."
fi

nvim --headless "+Lazy sync" +qa || {
  echo "Warnung: NvChad Lazy sync ist fehlgeschlagen. Du kannst später 'nvim' starten und Plugins manuell synchronisieren."
}

echo "Neovim mit NvChad eingerichtet."

# Projektstruktur
echo "Erstelle Projektverzeichnisse..."

mkdir -p \
  "$HOME/projects/web" \
  "$HOME/projects/cli" \
  "$HOME/projects/other" \
  "$HOME/projects/desktop" \
  "$HOME/projects/mobile" \

echo "Projektverzeichnisse unter ~/projects erstellt."

# npm global user-local
echo "Konfiguriere npm global prefix..."

NPM_GLOBAL_DIR="$HOME/.npm-global"

mkdir -p "$NPM_GLOBAL_DIR/bin"
npm config set prefix "$NPM_GLOBAL_DIR"

if ! grep -q '### dev-env npm global ###' "$HOME/.zshrc"; then
  cat >> "$HOME/.zshrc" <<EOF

### dev-env npm global ###
export PATH="$NPM_GLOBAL_DIR/bin:\$PATH"
### /dev-env npm global ###
EOF
fi

export PATH="$NPM_GLOBAL_DIR/bin:$PATH"

echo "Installiere globale npm Tools..."
npm install -g yarn pnpm


echo "Installiere Composer..."

if ! command -v composer >/dev/null 2>&1; then
  EXPECTED_CHECKSUM="$(php -r "copy('https://composer.github.io/installer.sig', 'php://stdout');")"
  php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
  ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

  if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then
    rm -f composer-setup.php
    echo "Composer Installer Checksum ungültig."
    exit 1
  fi

  php composer-setup.php --quiet
  rm -f composer-setup.php
  sudo mv composer.phar /usr/local/bin/composer
  sudo chmod +x /usr/local/bin/composer
else
  echo "Composer ist bereits installiert – überspringe."
fi
echo "Installiere Symfony CLI..."

if ! command -v symfony >/dev/null 2>&1; then
  curl -1sLf 'https://dl.cloudsmith.io/public/symfony/stable/setup.deb.sh' | sudo -E bash
  sudo apt install -y symfony-cli
else
  echo "Symfony CLI ist bereits installiert – überspringe."
fi

# Python pip
echo "Konfiguriere Python/pip..."

python3 -m pip install --user --upgrade pip || \
python3 -m pip install --user --upgrade pip --break-system-packages || \
echo "Warnung: pip Upgrade wurde übersprungen. Ubuntu blockiert ggf. systemweite pip-Änderungen."

# Rust
echo "Installiere Rust, falls nicht vorhanden..."

if [ ! -d "$HOME/.cargo" ]; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
else
  echo "Rust/Cargo bereits vorhanden – überspringe."
fi

if [ -f "$HOME/.cargo/env" ]; then
  # shellcheck disable=SC1090
  source "$HOME/.cargo/env"
fi

if ! grep -q '### dev-env cargo ###' "$HOME/.zshrc"; then
  cat >> "$HOME/.zshrc" <<'EOF'

### dev-env cargo ###
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"
### /dev-env cargo ###
EOF
fi

# MongoDB
echo "Installiere MongoDB Community Server..."

UBUNTU_CODENAME="$(lsb_release -cs)"

case "$UBUNTU_CODENAME" in
  noble|jammy)
    MONGODB_CODENAME="$UBUNTU_CODENAME"
    ;;
  *)
    echo "Ubuntu Codename '$UBUNTU_CODENAME' wird von diesem MongoDB-Setup nicht explizit behandelt."
    echo "Fallback auf 'jammy'. Falls das fehlschlägt, MongoDB bitte manuell nachinstallieren."
    MONGODB_CODENAME="jammy"
    ;;
esac

if [ ! -f /usr/share/keyrings/mongodb-server-8.0.gpg ]; then
  curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | \
    sudo gpg --dearmor -o /usr/share/keyrings/mongodb-server-8.0.gpg
fi

echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu $MONGODB_CODENAME/mongodb-org/8.0 multiverse" | \
  sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list >/dev/null

sudo apt update

sudo apt install -y mongodb-org || {
  echo "Warnung: MongoDB konnte nicht installiert werden."
  echo "Das restliche Setup wird fortgesetzt."
}

echo "Datenbanken und Programmiertools installiert."

# Aliase
echo "Konfiguriere Aliase..."

if ! grep -q '### dev-env aliases ###' "$HOME/.zshrc"; then
  cat >> "$HOME/.zshrc" <<'EOF'

### dev-env aliases ###
alias npmi="npm install"
alias yarni="yarn install"
alias py="python3"
alias pipi="pip install"
alias goi="go install"
alias giti="git init"
alias gita="git add ."
alias newi="nvim"
alias nvim="nvim"
alias neovim="nvim"
alias code="nvim"
alias ls="ls --color=auto"
alias nvimconfig="nvim ~/.config/nvim/init.lua"
alias zshconfig="nvim ~/.zshrc"
### /dev-env aliases ###
EOF
else
  echo "Aliase bereits vorhanden – überspringe."
fi

# DDEV
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://pkg.ddev.com/apt/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/ddev.gpg >/dev/null
sudo chmod a+r /etc/apt/keyrings/ddev.gpg

echo "deb [signed-by=/etc/apt/keyrings/ddev.gpg] https://pkg.ddev.com/apt/ * *" | sudo tee /etc/apt/sources.list.d/ddev.list >/dev/null

sudo apt update
sudo apt install -y ddev

# Default Shell
echo "Setze zsh als Default-Shell..."

ZSH_PATH="$(command -v zsh)"

if [ -n "$ZSH_PATH" ]; then
  if [ "$SHELL" != "$ZSH_PATH" ]; then
    chsh -s "$ZSH_PATH" || {
      echo "Warnung: chsh konnte die Shell nicht ändern."
      echo "Du kannst zsh manuell starten mit: zsh"
    }
  else
    echo "zsh ist bereits Default-Shell."
  fi
fi

echo ""
echo "Setup abgeschlossen!"
echo ""
echo "Empfohlen:"
echo "1. WSL einmal neu starten:"
echo "   In PowerShell: wsl --terminate <Dein-WSL-Name>"
echo ""
echo "2. Danach WSL neu öffnen."
echo ""
echo "3. Falls du sofort testen willst:"
echo "   zsh"
echo ""
echo "Tipp für Agnoster:"
echo "Nutze im Windows Terminal eine Powerline/Nerd Font, z. B. Cascadia Code PL oder MesloLGS NF."
echo "Nach dem Neustart kannst du dein Setup testen mit:"
echo "  ./test-installation.sh"