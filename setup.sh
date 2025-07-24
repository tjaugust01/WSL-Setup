#!/bin/bash

# This script sets up the environment for the project
set -e
SETUP_DIR=$(dirname "$0")

echo "Setting up the environment..."
sudo dnf update -y

echo "Installing necessary packages..."
sudo dnf install -y zsh git curl wget unzip tar make gcc gcc-c++ python3-pip

# ZSH setup

if [ ! -d "$HOME/.oh-my-zsh" ]; then
  # Unattended-Modus: Keine Shell-Änderung, kein automatischer Zsh-Start
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" --unattended
  echo "Oh My Zsh installiert (unattended)."
else
  echo "Oh My Zsh bereits installiert – überspringe."
fi
sed -i 's/plugins=(git)/plugins=(git npm yarn python pip golang rust docker)/' ~/.zshrc

sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="agnoster"/' ~/.zshrc

sudo dnf install -y powerline-fonts

echo "Oh My Zsh customisiert (Plugins: git, npm, yarn, python, pip, golang, rust, docker; Theme: Agnoster)."

CUSTOM_THEME="$SETUP_DIR/agnoster.zsh-theme"
TARGET_THEME="$HOME/.oh-my-zsh/themes/agnoster.zsh-theme"
if [ -f "$CUSTOM_THEME" ]; then
  # Backup der Originaldatei (falls vorhanden)
  if [ -f "$TARGET_THEME" ]; then
    cp "$TARGET_THEME" "$TARGET_THEME.bak"
    echo "Backup von $TARGET_THEME erstellt als $TARGET_THEME.bak."
  fi

  # Kopiere die custom Datei
  cp "$CUSTOM_THEME" "$TARGET_THEME"
  echo "Custom Agnoster-Theme aus $CUSTOM_THEME nach $TARGET_THEME kopiert."
else
  echo "Warnung: Custom Agnoster-Theme ($CUSTOM_THEME) nicht gefunden – überspringe Kopie. Verwende Standard-Theme."
fi

echo "Installing Neovim..."
sudo dnf install -y neovim
git clone https://github.com/NvChad/NvChad ~/.config/nvim --depth 1
echo "Um NVChad weiter zu konfigurieren muss es mindestens einmal "nvim" geöffnet werden."

mkdir -p ~/projects/web/js ~/projects/web/php ~/projects/cli/rust ~/projects/cli/python ~/projects/cli/go ~/projects/other ~/projects/desktop ~/projects/mobile ~/projects/desktop/tauri ~/projects/desktop/wails ~/projects/desktop/elektron

echo "Erstelle Projektverzeichnisse unter ~/projects."

echo "Installing Development Tools and Databases..."
sudo dnf install -y nodejs npm php php-cli
npm install -g yarn pnpm
sudo dnf install -y golang
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env
pip install --upgrade pip


sudo dnf install -y mysql-server postgresql-server sqlite
# MongoDB (nicht direkt in dnf, via offizielles Repo)
sudo tee /etc/yum.repos.d/mongodb-org-7.0.repo <<EOF
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/9/mongodb-org/7.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://pgp.mongodb.com/server-7.0.asc
EOF
sudo dnf install -y mongodb-org

echo "Programmiertools und Datenbanken installiert."

echo "Konfiguriere ZSH und PATH..."
cat <<EOT >> ~/.zshrc
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
EOT

echo "Aliase definiert in ~/.zshrc. Lade Zsh neu mit 'source ~/.zshrc'."

source ~/.zshrc  # Lade die neue Konfiguration
echo "Setup abgeschlossen! Starte eine neue Shell oder 'source ~/.zshrc' für Änderungen."
echo "Tipp: Für Agnoster-Theme installiere Powerline-Fonts in deinem Windows-Terminal (z.B. Cascadia Code PL)."
echo "Überprüfe die Farben mit 'echo \$ZSH_THEME' und starte eine neue Shell."