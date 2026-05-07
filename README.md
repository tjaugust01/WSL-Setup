WSL/Ubuntu Dev Environment

Automated setup for a modern development stack on Ubuntu/WSL.
🚀 Quick Start

Make scripts executable:
```bash
chmod +x setup.sh test-installation.sh
```

Run the setup:

```bash
./setup.sh
```

Restart your terminal (or run zsh).

Verify the installation:
Bash

```bash
./test-installation.sh
```

🛠 Features

Shell: ZSH + Oh My Zsh (Agnoster theme).

Editor: Neovim + NvChad.

Languages: Python, Node.js (Yarn/pnpm), Go, PHP (Composer/Symfony), Rust.

Databases: PostgreSQL, SQLite3, MongoDB.

Tooling: DDEV, Docker-ready configuration.

Workflow: Custom aliases and structured ~/projects directories.

💡 Important Notes

Fonts: Use a Nerd Font (e.g., Cascadia Code PL or MesloLGS NF) in your terminal settings to display icons correctly.

Docker: If using WSL, ensure Docker Desktop is installed on Windows and "WSL Integration" is enabled for your distro.

Aliases: Commands like npmi, py, and code (for Neovim) are pre-configured in your .zshrc.
