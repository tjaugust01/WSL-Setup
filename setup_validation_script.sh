#!/usr/bin/env bash

set -uo pipefail

FAILED=0
WARNINGS=0

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
RESET="\033[0m"

pass() {
  echo -e "${GREEN}[OK]${RESET} $1"
}

warn() {
  echo -e "${YELLOW}[WARN]${RESET} $1"
  WARNINGS=$((WARNINGS + 1))
}

fail() {
  echo -e "${RED}[FAIL]${RESET} $1"
  FAILED=$((FAILED + 1))
}

info() {
  echo -e "${BLUE}[INFO]${RESET} $1"
}

check_command() {
  COMMAND_NAME="$1"
  DISPLAY_NAME="${2:-$1}"

  if command -v "$COMMAND_NAME" >/dev/null 2>&1; then
    VERSION_OUTPUT="$("$COMMAND_NAME" --version 2>/dev/null | head -n 1 || true)"
    if [ -n "$VERSION_OUTPUT" ]; then
      pass "$DISPLAY_NAME gefunden: $VERSION_OUTPUT"
    else
      pass "$DISPLAY_NAME gefunden: $(command -v "$COMMAND_NAME")"
    fi
  else
    fail "$DISPLAY_NAME nicht gefunden. Erwarteter Command: $COMMAND_NAME"
  fi
}

check_php_extension() {
  EXTENSION_NAME="$1"

  if php -m 2>/dev/null | grep -qi "^${EXTENSION_NAME}$"; then
    pass "PHP Extension vorhanden: $EXTENSION_NAME"
  else
    fail "PHP Extension fehlt: $EXTENSION_NAME"
  fi
}

check_directory() {
  DIRECTORY_PATH="$1"

  if [ -d "$DIRECTORY_PATH" ]; then
    pass "Verzeichnis vorhanden: $DIRECTORY_PATH"
  else
    fail "Verzeichnis fehlt: $DIRECTORY_PATH"
  fi
}

check_file_contains() {
  FILE_PATH="$1"
  SEARCH_TEXT="$2"
  DESCRIPTION="$3"

  if [ ! -f "$FILE_PATH" ]; then
    fail "Datei fehlt: $FILE_PATH"
    return
  fi

  if grep -q "$SEARCH_TEXT" "$FILE_PATH"; then
    pass "$DESCRIPTION"
  else
    fail "$DESCRIPTION nicht gefunden in $FILE_PATH"
  fi
}

check_group_membership() {
  GROUP_NAME="$1"

  if groups "$USER" | grep -q "\\b${GROUP_NAME}\\b"; then
    pass "User '$USER' ist in Gruppe '$GROUP_NAME'"
  else
    warn "User '$USER' ist noch nicht in Gruppe '$GROUP_NAME'. Nach Setup ggf. WSL neu starten."
  fi
}

echo ""
echo "============================================================"
echo " WSL Setup Installationstest"
echo "============================================================"
echo ""

info "User: $USER"
info "Home: $HOME"
info "Shell: ${SHELL:-unbekannt}"

if [ -f /etc/os-release ]; then
  OS_PRETTY_NAME="$(grep '^PRETTY_NAME=' /etc/os-release | cut -d= -f2- | tr -d '"')"
  info "OS: $OS_PRETTY_NAME"
fi

echo ""
echo "------------------------------------------------------------"
echo " Basis-Tools"
echo "------------------------------------------------------------"

check_command "zsh" "Zsh"
check_command "git" "Git"
check_command "curl" "curl"
check_command "wget" "wget"
check_command "unzip" "unzip"
check_command "tar" "tar"
check_command "make" "make"
check_command "gcc" "GCC"
check_command "g++" "G++"

echo ""
echo "------------------------------------------------------------"
echo " Editor / Shell Setup"
echo "------------------------------------------------------------"

check_command "nvim" "Neovim"
check_directory "$HOME/.oh-my-zsh"
check_directory "$HOME/.config/nvim"

check_file_contains "$HOME/.zshrc" "ZSH_THEME=\"agnoster\"" "Agnoster Theme ist in .zshrc gesetzt"
check_file_contains "$HOME/.zshrc" "plugins=(git npm yarn python pip golang rust docker)" "Oh My Zsh Plugins sind gesetzt"
check_file_contains "$HOME/.zshrc" "### dev-env aliases ###" "Alias-Block ist in .zshrc vorhanden"
check_file_contains "$HOME/.zshrc" "### dev-env npm global ###" "npm-global PATH-Block ist in .zshrc vorhanden"
check_file_contains "$HOME/.zshrc" "### dev-env cargo ###" "Cargo PATH-Block ist in .zshrc vorhanden"

if [ -f "$HOME/.oh-my-zsh/themes/agnoster.zsh-theme" ]; then
  pass "Agnoster Theme-Datei vorhanden"
else
  fail "Agnoster Theme-Datei fehlt"
fi

echo ""
echo "------------------------------------------------------------"
echo " Projektstruktur"
echo "------------------------------------------------------------"

check_directory "$HOME/projects"
check_directory "$HOME/projects/web"
check_directory "$HOME/projects/cli"
check_directory "$HOME/projects/other"
check_directory "$HOME/projects/desktop"
check_directory "$HOME/projects/mobile"

echo ""
echo "------------------------------------------------------------"
echo " Node / npm Tooling"
echo "------------------------------------------------------------"

check_command "node" "Node.js"
check_command "npm" "npm"
check_command "yarn" "Yarn"
check_command "pnpm" "pnpm"

NPM_PREFIX="$(npm config get prefix 2>/dev/null || true)"
if [ "$NPM_PREFIX" = "$HOME/.npm-global" ]; then
  pass "npm global prefix korrekt: $NPM_PREFIX"
else
  warn "npm global prefix ist '$NPM_PREFIX', erwartet wäre '$HOME/.npm-global'"
fi

if echo "$PATH" | tr ':' '\n' | grep -qx "$HOME/.npm-global/bin"; then
  pass "npm global bin ist im aktuellen PATH"
else
  warn "$HOME/.npm-global/bin ist nicht im aktuellen PATH. Starte ggf. zsh neu oder führe 'source ~/.zshrc' aus."
fi

echo ""
echo "------------------------------------------------------------"
echo " PHP / Composer / Symfony"
echo "------------------------------------------------------------"

check_command "php" "PHP"
check_command "composer" "Composer"
check_command "symfony" "Symfony CLI"

check_php_extension "curl"
check_php_extension "mbstring"
check_php_extension "xml"
check_php_extension "zip"
check_php_extension "sqlite3"
check_php_extension "intl"
check_php_extension "bcmath"
check_php_extension "gd"
check_php_extension "mysqli"
check_php_extension "pdo_mysql"
check_php_extension "pgsql"
check_php_extension "pdo_pgsql"

echo ""
echo "------------------------------------------------------------"
echo " Python"
echo "------------------------------------------------------------"

check_command "python3" "Python 3"

if command -v pip3 >/dev/null 2>&1; then
  check_command "pip3" "pip3"
elif command -v pip >/dev/null 2>&1; then
  check_command "pip" "pip"
else
  fail "pip/pip3 nicht gefunden"
fi

check_command "python3" "Python venv Support"

if python3 -m venv --help >/dev/null 2>&1; then
  pass "python3 venv funktioniert"
else
  fail "python3 venv funktioniert nicht"
fi

echo ""
echo "------------------------------------------------------------"
echo " Go / Rust"
echo "------------------------------------------------------------"

check_command "go" "Go"
check_command "rustc" "Rust Compiler"
check_command "cargo" "Cargo"

if [ -f "$HOME/.cargo/env" ]; then
  pass "Cargo env-Datei vorhanden"
else
  fail "Cargo env-Datei fehlt: $HOME/.cargo/env"
fi

echo ""
echo "------------------------------------------------------------"
echo " Datenbanken / DB Clients"
echo "------------------------------------------------------------"

check_command "sqlite3" "SQLite"

if command -v psql >/dev/null 2>&1; then
  check_command "psql" "PostgreSQL Client"
else
  fail "PostgreSQL Client psql nicht gefunden"
fi

if command -v mysql >/dev/null 2>&1; then
  pass "MySQL/MariaDB Client vorhanden: $(mysql --version 2>/dev/null | head -n 1)"
else
  warn "MySQL/MariaDB Client nicht gefunden. Für DDEV ist das meistens okay."
fi

if command -v mongod >/dev/null 2>&1; then
  pass "MongoDB Server Binary vorhanden: $(mongod --version 2>/dev/null | head -n 1)"
else
  warn "MongoDB Server Binary nicht gefunden. Falls MongoDB im Setup optional ist, ist das okay."
fi

echo ""
echo "------------------------------------------------------------"
echo " Docker / DDEV"
echo "------------------------------------------------------------"

check_command "docker" "Docker"
check_command "ddev" "DDEV"

check_group_membership "docker"

if command -v docker >/dev/null 2>&1; then
  if docker version >/dev/null 2>&1; then
    pass "Docker Daemon ist erreichbar"
  else
    warn "Docker CLI ist installiert, aber Docker Daemon ist nicht erreichbar."
    warn "Falls Docker Desktop genutzt wird: WSL Integration aktivieren."
    warn "Falls Docker Engine in WSL genutzt wird: systemd aktivieren und Docker starten."
  fi
fi

if command -v docker >/dev/null 2>&1; then
  if docker compose version >/dev/null 2>&1; then
    pass "Docker Compose Plugin funktioniert: $(docker compose version 2>/dev/null)"
  else
    fail "Docker Compose Plugin funktioniert nicht"
  fi
fi

if command -v ddev >/dev/null 2>&1; then
  if ddev version >/dev/null 2>&1; then
    pass "DDEV version funktioniert"
  else
    warn "DDEV ist installiert, aber 'ddev version' konnte nicht sauber ausgeführt werden."
  fi
fi

echo ""
echo "------------------------------------------------------------"
echo " Services / systemd"
echo "------------------------------------------------------------"

if command -v systemctl >/dev/null 2>&1; then
  if systemctl is-system-running >/dev/null 2>&1; then
    pass "systemd scheint aktiv zu sein"
  else
    SYSTEMD_STATE="$(systemctl is-system-running 2>/dev/null || true)"
    warn "systemd ist nicht vollständig aktiv oder meldet: ${SYSTEMD_STATE:-unbekannt}"
  fi
else
  warn "systemctl nicht gefunden"
fi

echo ""
echo "============================================================"
echo " Ergebnis"
echo "============================================================"

if [ "$FAILED" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
  echo -e "${GREEN}Alles sieht gut aus. Setup ist vollständig einsatzbereit.${RESET}"
  exit 0
fi

if [ "$FAILED" -eq 0 ] && [ "$WARNINGS" -gt 0 ]; then
  echo -e "${YELLOW}Setup grundsätzlich okay, aber es gibt $WARNINGS Warnung(en).${RESET}"
  echo "Viele Warnungen lassen sich durch einen WSL-Neustart beheben:"
  echo ""
  echo "  powershell.exe -Command \"wsl --terminate <Dein-WSL-Name>\""
  echo ""
  exit 0
fi

echo -e "${RED}Setup hat $FAILED Fehler und $WARNINGS Warnung(en).${RESET}"
echo "Bitte die FAIL-Meldungen oben prüfen."
exit 1
