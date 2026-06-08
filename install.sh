#!/usr/bin/env bash
# =============================================================================
# alex's dotfiles installer
# Arch Linux + CachyOS + Hyprland + NVIDIA GTX 1080 Ti
# Использование: bash install.sh
# =============================================================================

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USER_HOME="$HOME"
CONFIG_DIR="$USER_HOME/.config"
USERNAME="$(whoami)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${GREEN}[✓]${NC} $1"; }
warn()    { echo -e "${YELLOW}[!]${NC} $1"; }
error()   { echo -e "${RED}[✗]${NC} $1"; exit 1; }
section() { echo -e "\n${RED}${BOLD}━━━ $1 ━━━${NC}"; }

# =============================================================================
section "Проверка окружения"
# =============================================================================

[[ $EUID -eq 0 ]] && error "Не запускай от root. Запусти как обычный пользователь."
command -v pacman &>/dev/null || error "Это не Arch Linux (pacman не найден)"

info "Пользователь: $USERNAME"
info "Домашняя директория: $USER_HOME"
info "Dotfiles: $DOTFILES_DIR"

# =============================================================================
section "Настройка pacman и CachyOS репозиториев"
# =============================================================================

info "Копирование pacman.conf..."
sudo cp "$DOTFILES_DIR/system/pacman.conf" /etc/pacman.conf

if ! pacman -Qq cachyos-mirrorlist &>/dev/null; then
    warn "CachyOS mirrorlist не найден, устанавливаю..."
    sudo pacman-key --recv-keys F3B607488DB35A47 --keyserver keyserver.ubuntu.com
    sudo pacman-key --lsign-key F3B607488DB35A47
    sudo pacman -U --noconfirm \
        'https://mirror.cachyos.org/repo/x86_64/cachyos/cachyos-keyring-20240331-1-any.pkg.tar.zst' \
        'https://mirror.cachyos.org/repo/x86_64/cachyos/cachyos-mirrorlist-18-1-any.pkg.tar.zst' \
        'https://mirror.cachyos.org/repo/x86_64/cachyos/cachyos-v3-mirrorlist-18-1-any.pkg.tar.zst' \
        'https://mirror.cachyos.org/repo/x86_64/cachyos/cachyos-v4-mirrorlist-18-1-any.pkg.tar.zst' \
        'https://mirror.cachyos.org/repo/x86_64/cachyos/pacman-6.1.0-7-x86_64.pkg.tar.zst' || \
        warn "Не удалось установить CachyOS mirrorlist автоматически"
fi

sudo pacman -Sy --noconfirm
info "pacman настроен"

# =============================================================================
section "Установка yay (AUR хелпер)"
# =============================================================================

if ! command -v yay &>/dev/null; then
    info "Устанавливаю yay..."
    sudo pacman -S --needed --noconfirm git base-devel
    tmpdir=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
    (cd "$tmpdir/yay" && makepkg -si --noconfirm)
    rm -rf "$tmpdir"
    info "yay установлен"
else
    info "yay уже установлен"
fi

# =============================================================================
section "Установка пакетов (91 пакет)"
# =============================================================================

if [[ -f "$DOTFILES_DIR/pkglist.txt" ]]; then
    info "Устанавливаю пакеты из pkglist.txt..."
    # Разделяем на официальные и AUR
    AUR_PKGS=(grimblast-git unimatrix-git wttrbar zen-browser-bin hyprshade)

    # Всё из pkglist кроме AUR пакетов
    OFFICIAL_PKGS=()
    while IFS= read -r pkg; do
        [[ -z "$pkg" || "$pkg" == \#* ]] && continue
        skip=0
        for aur in "${AUR_PKGS[@]}"; do
            [[ "$pkg" == "$aur" ]] && skip=1 && break
        done
        [[ $skip -eq 0 ]] && OFFICIAL_PKGS+=("$pkg")
    done < "$DOTFILES_DIR/pkglist.txt"

    info "Официальные пакеты (pacman)..."
    sudo pacman -S --needed --noconfirm "${OFFICIAL_PKGS[@]}" 2>/dev/null || \
        warn "Некоторые пакеты не найдены — возможно сменились имена"

    info "AUR пакеты (yay)..."
    yay -S --needed --noconfirm "${AUR_PKGS[@]}" || \
        warn "Некоторые AUR пакеты не удалось установить"
else
    error "pkglist.txt не найден! Файл должен быть в корне репозитория."
fi

# =============================================================================
section "Настройка NVIDIA (GTX 1080 Ti)"
# =============================================================================

info "Копирование nvidia.conf..."
sudo cp "$DOTFILES_DIR/system/modprobe.d/nvidia.conf" /etc/modprobe.d/nvidia.conf

info "Копирование mkinitcpio.conf..."
sudo cp "$DOTFILES_DIR/system/mkinitcpio.conf" /etc/mkinitcpio.conf

info "Пересборка initramfs..."
sudo mkinitcpio -P
info "initramfs пересобран"

# =============================================================================
section "Настройка GRUB"
# =============================================================================

info "Копирование /etc/default/grub..."
sudo cp "$DOTFILES_DIR/system/default/grub" /etc/default/grub

info "Генерация grub.cfg..."
sudo grub-mkconfig -o /boot/grub/grub.cfg
info "GRUB настроен"

# =============================================================================
section "Настройка X11 клавиатуры"
# =============================================================================

sudo mkdir -p /etc/X11/xorg.conf.d
sudo cp "$DOTFILES_DIR/system/X11/xorg.conf.d/00-keyboard.conf" /etc/X11/xorg.conf.d/
info "Клавиатура настроена (us/ru, alt+shift)"

# =============================================================================
section "Копирование конфигов"
# =============================================================================

safe_copy() {
    local src="$1"
    local dst="$2"
    mkdir -p "$(dirname "$dst")"
    if [[ -e "$dst" ]]; then
        warn "Backup: $dst -> $dst.bak"
        mv "$dst" "$dst.bak"
    fi
    cp -r "$src" "$dst"
    info "$(basename "$dst")"
}

safe_copy "$DOTFILES_DIR/config/hypr"      "$CONFIG_DIR/hypr"
safe_copy "$DOTFILES_DIR/config/kitty"     "$CONFIG_DIR/kitty"
safe_copy "$DOTFILES_DIR/config/waybar"    "$CONFIG_DIR/waybar"
safe_copy "$DOTFILES_DIR/config/rofi"      "$CONFIG_DIR/rofi"
safe_copy "$DOTFILES_DIR/config/starship"  "$CONFIG_DIR/starship"
safe_copy "$DOTFILES_DIR/config/cava"      "$CONFIG_DIR/cava"
safe_copy "$DOTFILES_DIR/config/fastfetch" "$CONFIG_DIR/fastfetch"

# .zshrc
[[ -f "$USER_HOME/.zshrc" ]] && mv "$USER_HOME/.zshrc" "$USER_HOME/.zshrc.bak" && warn ".zshrc -> .zshrc.bak"
cp "$DOTFILES_DIR/home/.zshrc" "$USER_HOME/.zshrc"
info ".zshrc"

# start-hyprpaper.sh
cp "$DOTFILES_DIR/home/start-hyprpaper.sh" "$USER_HOME/start-hyprpaper.sh"
chmod +x "$USER_HOME/start-hyprpaper.sh"
info "start-hyprpaper.sh"

# ~/.local/bin/
mkdir -p "$USER_HOME/.local/bin"
cp -r "$DOTFILES_DIR/home/.local/bin/." "$USER_HOME/.local/bin/"
chmod +x "$USER_HOME/.local/bin/"* 2>/dev/null || true
info ".local/bin/ скрипты"

# =============================================================================
section "Настройка shell"
# =============================================================================

if [[ "$SHELL" != "$(which zsh)" ]]; then
    info "Устанавливаю zsh как shell по умолчанию..."
    chsh -s "$(which zsh)"
fi

# =============================================================================
section "Создание директорий"
# =============================================================================

mkdir -p "$USER_HOME/Pictures/Screenshots"
mkdir -p "$USER_HOME/Pictures"
info "~/Pictures/Screenshots создан"

# Wallpaper reminder
if [[ ! -f "$USER_HOME/Pictures/wallpaper.png" ]]; then
    warn "Обои не найдены! Скопируй wallpaper.png в ~/Pictures/"
    warn "Или измени путь в ~/start-hyprpaper.sh и ~/.config/hypr/hyprpaper.conf"
fi

# =============================================================================
section "Системные сервисы"
# =============================================================================

sudo systemctl enable --now bluetooth.service   && info "bluetooth включён"    || warn "bluetooth: ошибка"
sudo systemctl enable --now NetworkManager.service && info "NetworkManager включён" || warn "NetworkManager: ошибка"
sudo systemctl enable sddm.service              && info "sddm включён"         || warn "sddm: ошибка"
sudo systemctl enable --now cups.service        && info "cups включён"          || warn "cups: ошибка"

# =============================================================================
section "Готово!"
# =============================================================================

echo ""
echo -e "${RED}${BOLD}╔══════════════════════════════════════════════╗"
echo -e "║        Установка завершена успешно!          ║"
echo -e "╚══════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Что делать дальше:"
echo -e "  ${BOLD}1.${NC} Скопируй обои: ${YELLOW}cp /path/to/wallpaper.png ~/Pictures/wallpaper.png${NC}"
echo -e "  ${BOLD}2.${NC} Перезагрузись: ${YELLOW}reboot${NC}"
echo -e "  ${BOLD}3.${NC} Войди через SDDM → Hyprland"
echo ""
