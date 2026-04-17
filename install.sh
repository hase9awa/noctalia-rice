#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/hase9awa/noctalia-rice.git"
REPO_DIR="$HOME/.local/share/noctalia-rice"
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
BRRTFETCH_REPO="https://github.com/ferrebarrat/brrtfetch.git"
BRRTFETCH_TMP="/tmp/brrtfetch-assets-$$"

PACMAN_PKGS=(
  git
  base-devel
  fish
  kitty
  fastfetch
  curl
)

AUR_PKGS=(
  noctalia-shell
  brrtfetch-git
)

info() {
  printf "\033[1;34m[INFO]\033[0m %s\n" "$1"
}

ok() {
  printf "\033[1;32m[OK]\033[0m %s\n" "$1"
}

warn() {
  printf "\033[1;33m[WARN]\033[0m %s\n" "$1"
}

err() {
  printf "\033[1;31m[ERR]\033[0m %s\n" "$1"
  exit 1
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1
}

check_arch() {
  if ! need_cmd pacman; then
    err "Скрипт рассчитан на Arch-based системы."
  fi
}

install_yay() {
  if need_cmd yay; then
    ok "yay уже установлен"
    return
  fi

  info "Устанавливаю yay..."
  sudo pacman -Sy --needed --noconfirm git base-devel

  local tmpdir
  tmpdir="$(mktemp -d)"
  git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
  (
    cd "$tmpdir/yay"
    makepkg -si --noconfirm
  )
  rm -rf "$tmpdir"
  ok "yay установлен"
}

install_packages() {
  info "Устанавливаю пакеты из pacman..."
  sudo pacman -Syu --needed --noconfirm "${PACMAN_PKGS[@]}"

  info "Устанавливаю пакеты из AUR..."
  yay -S --needed --noconfirm "${AUR_PKGS[@]}"

  ok "Пакеты установлены"
}

backup_file_or_dir() {
  local src="$1"
  if [ -e "$src" ]; then
    local rel="${src#$HOME/}"
    mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
    mv "$src" "$BACKUP_DIR/$rel"
    info "Backup: $src -> $BACKUP_DIR/$rel"
  fi
}

backup_configs() {
  info "Делаю backup текущих конфигов..."
  mkdir -p "$BACKUP_DIR"

  backup_file_or_dir "$HOME/.config/fish"
  backup_file_or_dir "$HOME/.config/kitty"
  backup_file_or_dir "$HOME/.config/fastfetch"

  if need_cmd niri; then
    backup_file_or_dir "$HOME/.config/niri"
  fi

  ok "Backup готов: $BACKUP_DIR"
}

clone_repo() {
  if [ -d "$REPO_DIR/.git" ]; then
    info "Обновляю репозиторий с конфигами..."
    git -C "$REPO_DIR" pull --ff-only
  else
    info "Клонирую репозиторий с конфигами..."
    rm -rf "$REPO_DIR"
    git clone "$REPO_URL" "$REPO_DIR"
  fi
}

install_fish_stack() {
  info "Настраиваю fish + fisher + tide..."

  mkdir -p "$HOME/.config/fish/functions"

  if ! fish -c "functions -q fisher" >/dev/null 2>&1; then
    fish -c '
      curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish \
      -o ~/.config/fish/functions/fisher.fish
      and fish -c "fisher install jorgebucaran/fisher IlanCosman/tide@v6"
    '
  else
    fish -c 'fisher install IlanCosman/tide@v6'
  fi

  ok "fish/fisher/tide готовы"
}

copy_configs() {
  info "Копирую конфиги..."

  mkdir -p "$HOME/.config"
  mkdir -p "$HOME/.config/fish"
  mkdir -p "$HOME/.config/kitty/themes"
  mkdir -p "$HOME/.config/fastfetch"

  cp -f "$REPO_DIR/.config/fish/config.fish" "$HOME/.config/fish/config.fish"

  cp -f "$REPO_DIR/.config/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
  cp -f "$REPO_DIR/.config/kitty/current-theme.conf" "$HOME/.config/kitty/current-theme.conf"
  cp -f "$REPO_DIR/.config/kitty/themes/noctalia.conf" "$HOME/.config/kitty/themes/noctalia.conf"

  cp -f "$REPO_DIR/.config/fastfetch/config.jsonc" "$HOME/.config/fastfetch/config.jsonc"

  if need_cmd niri; then
    info "Обнаружен niri, ставлю его конфиги..."
    mkdir -p "$HOME/.config/niri/cfg"
    cp -f "$REPO_DIR/.config/niri/config.kdl" "$HOME/.config/niri/config.kdl"
    cp -f "$REPO_DIR/.config/niri/noctalia.kdl" "$HOME/.config/niri/noctalia.kdl"
    cp -f "$REPO_DIR/.config/niri/cfg/rules.kdl" "$HOME/.config/niri/cfg/rules.kdl"
    cp -f "$REPO_DIR/.config/niri/cfg/layout.kdl" "$HOME/.config/niri/cfg/layout.kdl"
    cp -f "$REPO_DIR/.config/niri/cfg/input.kdl" "$HOME/.config/niri/cfg/input.kdl"
    cp -f "$REPO_DIR/.config/niri/cfg/keybinds.kdl" "$HOME/.config/niri/cfg/keybinds.kdl"
  else
    warn "niri не найден, его конфиги пропускаю"
  fi

  ok "Конфиги скопированы"
}

install_brrtfetch_gifs() {
  info "Скачиваю GIF для brrtfetch..."

  rm -rf "$BRRTFETCH_TMP"
  git clone --depth 1 "$BRRTFETCH_REPO" "$BRRTFETCH_TMP"

  mkdir -p "$HOME/Pictures/brrtfetch/gifs"
  cp -r "$BRRTFETCH_TMP/gifs/." "$HOME/Pictures/brrtfetch/gifs/"

  rm -rf "$BRRTFETCH_TMP"
  ok "GIF для brrtfetch установлены в $HOME/Pictures/brrtfetch/gifs"
}

main() {
  check_arch
  install_yay
  install_packages
  backup_configs
  clone_repo
  install_fish_stack
  copy_configs
  install_brrtfetch_gifs

  ok "Готово"
  printf "Backup конфигов: %s\n" "$BACKUP_DIR"
}

main "$@"
