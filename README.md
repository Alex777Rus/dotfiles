# dotfiles — unnxcxssvry

Конфиги для Arch Linux + Hyprland + NVIDIA GTX 1080 Ti.  

![Preview](https://github.com/Alex777Rus/dotfiles/blob/main/image.png)

## Система

| | |
|---|---|
| OS | Arch Linux (CachyOS репозитории) |
| Kernel | linux-cachyos-bore |
| WM | Hyprland (Wayland) |
| CPU | AMD Ryzen 7 7800X3D |
| GPU | NVIDIA GeForce GTX 1080 Ti |
| Terminal | Kitty |
| Shell | Zsh + Starship |
| Bar | Waybar |
| Launcher | Rofi |
| Шрифт | FantasqueSansM Nerd Font + JetBrains Mono NF |

## Установка

```bash
git clone https://github.com/<твой-юзер>/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash install.sh
```

После установки скопируй обои и перезагрузись:
```bash
cp /path/to/wallpaper.png ~/Pictures/wallpaper.png
reboot
```

## Структура

```
dotfiles/
├── install.sh                      # главный скрипт
├── pkglist.txt                     # все 91 пакет
├── config/
│   ├── hypr/
│   │   ├── hyprland.conf           # биндинги, NVIDIA env, анимации
│   │   ├── hyprpaper.conf          # обои
│   │   └── shaders/vibrance.glsl   # шейдер насыщенности
│   ├── kitty/kitty.conf            # прозрачность 45%, FantasqueSansM
│   ├── waybar/
│   │   ├── config.jsonc            # CPU, RAM, сеть, bluetooth, mpris
│   │   └── style.css               # тёмная тема с красными акцентами
│   ├── rofi/config.rasi            # лаунчер
│   ├── starship/starship.toml      # промпт
│   ├── cava/                       # визуализатор аудио + шейдеры
│   └── fastfetch/                  # системная инфа при запуске терминала
├── home/
│   ├── .zshrc                      # autosuggestions, syntax-highlighting, starship
│   ├── start-hyprpaper.sh          # скрипт запуска обоев
│   └── .local/bin/
│       └── osu-wine                # запуск osu!
└── system/
    ├── mkinitcpio.conf             # NVIDIA модули в initramfs
    ├── pacman.conf                 # CachyOS репозитории, ParallelDownloads=15
    ├── modprobe.d/nvidia.conf      # nvidia_drm modeset=1 fbdev=1
    ├── default/grub                # параметры ядра (mitigations=off и др.)
    └── X11/xorg.conf.d/00-keyboard.conf
```

## Что делает install.sh

1. Копирует `pacman.conf` (CachyOS репозитории)
2. Устанавливает `yay`
3. Ставит все 91 пакет из `pkglist.txt`
4. Настраивает NVIDIA: `modprobe.d`, `mkinitcpio`, пересобирает initramfs
5. Настраивает GRUB
6. Копирует все конфиги в `~/.config/`
7. Устанавливает zsh как shell по умолчанию
8. Включает bluetooth, NetworkManager, sddm, cups

## Параметры ядра (GRUB)

```
nvidia_drm.modeset=1 nvidia_drm.fbdev=1
mitigations=off
nowatchdog
transparent_hugepage=madvise
loglevel=3 quiet
```

## Обои

Обои не включены в репозиторий.  
Скрипт ожидает файл `~/Pictures/wallpaper.png`.  
Путь меняется в `~/start-hyprpaper.sh` и `~/.config/hypr/hyprpaper.conf`.
