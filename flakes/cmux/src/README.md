# LCmux

Terminal multiplexer for AI coding agents on Linux. Fork of [cmux](https://github.com/manaflow-ai/cmux) by Manaflow.

Uses **VTE** (GTK4 terminal widget) instead of Ghostty for terminal rendering, making it work natively on Linux.

## Install

### NixOS (flake)

Add to your `flake.nix` inputs:

```nix
inputs.lcmux = {
  url = "github:LucasPC-hub/lcmux";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Then add the package to your environment:

```nix
environment.systemPackages = [
  inputs.lcmux.packages.${pkgs.system}.default
];
```

### Nix (standalone)

```bash
nix run github:LucasPC-hub/lcmux
```

### Arch Linux

```bash
pacman -S gtk4 libadwaita vte4 webkit2gtk-6.0 glib-networking openssl
git clone https://github.com/LucasPC-hub/lcmux.git
cd lcmux
cargo build --release
# Binaries at target/release/lcmux-app and target/release/lcmux
```

### Other distros

Install GTK4, libadwaita, VTE4, WebKitGTK 6.0, glib-networking, and OpenSSL dev packages, then:

```bash
cargo build --release
```

## Usage

```bash
lcmux-app          # Launch the GUI
lcmux ping         # CLI: ping the socket server
lcmux workspace list
lcmux surface send-text "echo hello\n"
```

## Architecture

- `lcmux/` -- Main application (GTK4/libadwaita + VTE4)
  - `model/` -- TabManager, Workspace, Panel, LayoutNode
  - `ui/` -- Window, Sidebar, SplitView, TerminalPanel
  - `socket/` -- Unix socket server, v2 JSON protocol, auth
  - `session/` -- Session persistence (XDG, JSON compatible with macOS cmux)
  - `notifications.rs` -- Notification store + desktop notifications
- `lcmux-cli/` -- CLI client

## Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| `Ctrl+Shift+T` | New workspace |
| `Ctrl+Shift+W` | Close workspace |
| `Ctrl+Shift+E` | Split terminal right |
| `Ctrl+Shift+D` | Split terminal down |
| `Ctrl+Shift+B` | Split browser right |
| `Ctrl+Shift+N` | Split browser down |
| `Ctrl+Tab` | Next workspace |
| `Ctrl+Shift+Tab` | Previous workspace |

## Socket Protocol

Unix socket at `$XDG_RUNTIME_DIR/lcmux.sock` (falls back to `/tmp/lcmux-$UID.sock`).
Line-delimited JSON v2 protocol. Compatible with macOS cmux socket API.

## License

AGPL-3.0 -- same as upstream cmux.

Based on [cmux](https://github.com/manaflow-ai/cmux) by Manaflow and the [Linux port PR #828](https://github.com/manaflow-ai/cmux/pull/828) by shuhei0866.
