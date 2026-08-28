# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A personal dotfiles repo for Arch/EndeavourOS + KDE Plasma. There is no build, no test suite, and no package manager — the "product" is a tree of config files plus bash/fish scripts that get symlinked into `$HOME`. Verification means syntax-checking scripts and re-running the linker, not running tests.

## Commands

```bash
./stow.sh -s          # symlink everything into ~ and ~/.config
./stow.sh -u          # remove those symlinks
./arch-setup.sh -h    # provisioning script; -s full setup, -p/-a/-m/-l/-f/-k/-g per-step

bash -n <script>                        # syntax-check a bash script (_home/**, *.sh)
fish --no-execute <file.fish>           # syntax-check a fish script
_dotfiles/alacritty/themes.sh           # re-pull alacritty themes from upstream
```

## How stowing works (read before adding files)

`stow.sh` is hand-rolled, not GNU stow. `create_links` symlinks each **direct child** of a source dir into the target:

| Source | Target | Effect |
| --- | --- | --- |
| `_home/*` | `~/` | `~/.scripts`, `~/.vpn`, `~/.ucu` are symlinked dirs |
| `_dotfiles/*` | `~/.config/` | `~/.config/alacritty`, `~/.config/mpv`, … |
| `_shell/*` | `~/.config/` | `~/.config/fish`, `~/.config/tmux`, `~/.config/bash`, … |
| `_plasma/*` | `~/.config/` | individual `*rc` files |
| `editors/zed` | `~/.config/zed` | linked as one dir (`create_link`, singular) |

Consequences:
- Adding a file **inside** an already-linked dir needs nothing — the dir itself is the symlink.
- Adding a **new top-level dir** (e.g. `_dotfiles/foo/`) requires re-running `./stow.sh -s`.
- `editors/vim` is *not* stowed by any code path; `_shell/bash/.bashrc` lands at `~/.config/bash/.bashrc`, not `~/.bashrc`. Both are deliberate-looking gaps — don't "fix" them silently.

**`_plasma/*` files are live-written by KDE.** Because they're symlinks back into the repo, Plasma rewrites them during normal desktop use. Seeing `_plasma/kwinrc`, `kdeglobals`, `dolphinrc`, `mimeapps.list` dirty in `git status` is expected drift, not a change you made.

## Recurring code patterns

**Ordered profile maps.** Bash associative arrays are unordered, so scripts that present menus keep an explicit order array alongside the map. When adding an entry, update **both**:
- `_home/.scripts/dns-changer` and `dnsproxy-changer`: `DNS_SERVERS`/`DNS_PROFILES` + `DNS_PROFILE_ORDER` (`dnsresolved-changer` still lacks an order array)
- `arch-setup.sh`: `PACKAGES_LIST` + `ORDERS_LIST`; also `STEP_NAMES` + `STEP_FUNCS`, which are paired **by index** and must stay aligned.

**Library + thin wrapper.** Shared logic lives in a `*-lib.sh` that refuses to run when executed directly (`BASH_SOURCE[0] == $0` guard); callers source it, set config variables, then call one entry point:
- `_home/.vpn/ovpn-lib.sh` ← `eliteping-ovpn`, `vpnbaz-ovpn` set `VPN_CONFIG_DIR`/`VPN_AUTH_FILE`/`VPN_EXTRA_ARGS`, then `vpn_connect_interactive`.
- `_home/.vpn/openconnect-lib.sh` ← `vpnbaz-openconnect`, `openconnect-connect.sh` set `VPN_SERVERS`/`VPN_AUTH_FILE`/`VPN_EXTRA_ARGS`, then `vpn_connect_interactive`.
- `_home/.ucu/ucu-launcher-lib.sh` ← per-game scripts (see `ucu-example`) set `GAME_*`/`WINE_PREFIX`/`PROTONPATH`, define an `umu_env_hook` for Proton env vars, then call `umu_launch_game`.

**Script conventions in `_home/.scripts/`:** `info`/`success`/`warn`/`die` helpers, `require_root` that re-execs via `exec sudo bash "$0" "$@"`, a `usage()` heredoc, `getopts` main, and box-drawing `# ─────` section separators. Interactive by default with non-interactive flags (`-p <profile>`, `-l`). These scripts are on `PATH` via `fish_add_path $HOME/.scripts` and `$HOME/.vpn` in `_shell/fish/_env.fish`.

**`arch-setup.sh` prompting model:** one up-front `select_exclusions` picker (yay-style, accepts `1 2 3`, `1-3`, `^4`) rather than per-step yes/no; it uses bash namerefs for input/output arrays so nested calls can't clobber each other. `ASSUME_YES` suppresses later `ask_prompt` calls once the user has chosen.

## Fish configuration structure

`_shell/fish/config.fish` sources `_env.fish` and `_keybinds.fish`, then `load_files` over three dirs — `aliases/`, `attach/`, `utils/`. A new `.fish` file in one of those loads automatically; a **new directory** needs a `load_files` line added to `config.fish`.

- `aliases/*.fish` — `abbr` definitions grouped by tool (`_pacman`, `_docker`, `_network`, …).
- `utils/*.fish` — eagerly-sourced function definitions.
- `functions/*.fish` — fish's lazy autoload dir: one function per file, filename must match the function name.
- `conf.d/*.fish` — auto-sourced by fish itself before `config.fish`.
- `plugins/` — fisher's install target (`fisher_path` is set in `conf.d/fisher_path.fish`). Files under `plugins/` are vendored by fisher from `fish_plugins`; regenerate via fisher rather than editing by hand.

## Vendored / generated files — do not hand-edit

- `_dotfiles/alacritty/themes/*.toml` — pulled by `themes.sh` from `alacritty/alacritty-theme`.
- `_shell/tmux/tmux.conf` — oh-my-tmux upstream; all customization belongs in `tmux.conf.local`.
- `_shell/fish/plugins/**` — fisher-managed.
- `editors/vim/.vim/autoload/plug.vim` — vim-plug.

## Conventions

- Commits: Conventional Commits with a component scope — `feat(dnsproxy-changer): …`, `chore(fish): …`, `refactor(dns-scripts): …`, `fix(kde): …`.
- Bash scripts use tabs for indentation; fish uses 4 spaces.
- `.gitignore` excludes `**.auth` — VPN credential files are never committed; `_home/.vpn/ovpn-servers/example.auth.txt` is the template.
- Keep `README.md`'s structure/flag tables in sync when changing `stow.sh` or `arch-setup.sh` flags.
