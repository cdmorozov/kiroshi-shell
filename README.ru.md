# kiroshi-shell

**Рабочий стол для Fedora в стиле Cyberpunk 2077 / Edgerunners: Hyprland и собственный HUD на Quickshell.**
Приглушённые синий и бирюзовый вместо кричащего неона, плашки со срезанными углами, подписи иероглифами,
нумерованный список приложений и живая телеметрия на рабочем столе. Ставится одной командой и откатывается назад.

[English version](README.md)

![Desktop demo](docs/img/desktop-preview-2026-11-22.gif)

| Лаунчер (`Super+D`) | Терминал |
| --- | --- |
| ![launcher](docs/img/launcher-2026-11-22.png) | ![terminal](docs/img/terminal-2026-11-22.png) |

![RADIOPORT](docs/img/radioport-2026-11-22.png)

## Что внутри

- **Верхняя панель**: рабочие столы, список окон, часы с иероглифом дня недели, трей, показания CPU / MEM / VOL / NET / BT / BAT. Клик по показанию открывает его панель.
- **Меню приложений**: нумерованный список со ступенчатым сдвигом, иероглиф категории на каждой строке, поиск, плавная прокрутка.
- **Панели**: Wi-Fi, Bluetooth, микшер звука, история уведомлений, меню питания, переключатель окон, индикаторы громкости и яркости.
- **RADIOPORT**: карточка плеера (MPRIS) на рабочем столе и большое окно.
- **HUD на рабочем столе**: бегущая диагностика и живая телеметрия на пустом рабочем столе; при открытии окна гаснут.
- **Экран блокировки** (hyprlock) и автоблокировка (hypridle).
- **Терминал**: kitty, fish, starship, fastfetch с логотипом из точек, eza / zoxide / fzf, файловый менеджер Yazi.
- **По желанию**: тема Firefox и стартовая страница, тема VS Code, тема Spotify (Spicetify) с «тёплым стартом».
- **Страховка**: установщик делает копию того, что заменяет, `uninstall.sh` возвращает её, а `rice-snapshot` и `rice-restore` сохраняют и откатывают ваши собственные правки.

## Требования

- Fedora 44 (на других версиях Fedora может заработать, больше ничего не проверялось).
- Сборка Hyprland с **Lua-конфигом** (0.57+). Установщик подключает для неё COPR `sdegler/hyprland`.
- Видеокарта и драйвер, которые поддерживает Hyprland. Делалось на ноутбучной матрице 1920×1200.

## Установка

```bash
git clone https://github.com/cdmorozov/kiroshi-shell.git
cd kiroshi-shell
./install.sh --dry-run        # посмотреть, что будет сделано
./install.sh --all            # всё: пакеты, шрифты, конфиги, Firefox, VS Code, Spotify
```

Варианты поменьше:

```bash
./install.sh                          # только основной рабочий стол
./install.sh --firefox --vscode       # добавить нужные темы
./install.sh --no-packages            # зависимости уже стоят
```

Потом выйдите из сессии, выберите **Hyprland** в меню с шестерёнкой на экране входа и войдите.
Старые конфиги лежат в `~/.netrunner-backup-<дата>`, `./uninstall.sh` вернёт их.

## Клавиши

| Клавиши | Действие |
| --- | --- |
| `Super+D` / `Super+R` | меню приложений |
| `Super+Enter` / `Super+T` | терминал |
| `Super+Tab` | переключатель окон |
| `Super+E` | Yazi (файлы в терминале), `Super+Alt+E` Nautilus |
| `Super+W` / `Super+B` / `Super+A` | панели Wi-Fi / Bluetooth / звук |
| `Super+M` | плеер RADIOPORT |
| `Super+N` | история уведомлений, `Super+Shift+N` убрать всплывшие |
| `Super+Esc` | меню питания |
| `Super+L` | блокировка |
| `Super+I` | системные настройки |
| `Super+Shift+V` | история буфера обмена |
| `Super+Q` / `Super+F` / `Super+V` | закрыть / на весь экран / плавающее окно |
| `Super+1..0` | рабочие столы (`+Shift` переносит окно) |
| `Super+S` | скретчпад |
| `Super+Shift+M` | показать / спрятать Spotify (нужен `--spotify`) |
| `Print` | скриншот области в буфер |
| `Super+Shift+E` | аварийный выход на экран входа |

## Под себя

- **Обои**: поставьте в *Настройки GNOME > Внешний вид > Фон*. `wallpaper-sync` перенесёт выбор в hyprpaper и на экран блокировки.
- **Цвета**: все цвета оболочки в `~/.config/quickshell/Theme.qml`, рамки окон в `hyprland.lua`.
- **Шрифты**: Rajdhani для подписей, Tektur для текста с кириллицей, JetBrainsMono Nerd Font для кода. Меняются в `Theme.qml` и `kitty.conf`.
- **Мониторы**: `hl.monitor(...)` в `hyprland.lua`. Масштаб по умолчанию 1.
- **Снимки**: `rice-snapshot before-experiment`, а если результат не понравился, `rice-restore before-experiment`.

## Что где лежит

```
config/        всё, что попадает в ~/.config (hypr, quickshell, kitty, fish, ...)
bin/           скрипты, которые ставятся в ~/.local/bin
firefox/       userChrome.css, userContent.css, user.js
vscode/        цветовая тема «Night City HUD»
assets/        сгенерированные обои-заглушка
install.sh     установщик          uninstall.sh   возвращает копию
```

## Благодарности

- Вдохновлено интерфейсом Cyberpunk 2077, а также [CyberArch-Shell](https://github.com/ARCANGEL0/CyberArch-Shell) и ригами с r/unixporn.
- Построено на [Hyprland](https://hyprland.org), [Quickshell](https://quickshell.org), [Yazi](https://github.com/sxyazi/yazi), [Spicetify](https://spicetify.app).
- Шрифты установщик скачивает у авторов: Rajdhani и Tektur (SIL OFL, Google Fonts), JetBrainsMono Nerd Font.

## Оговорка

Это неофициальный фанатский проект. *Cyberpunk 2077*, *Edgerunners* и *Arasaka* принадлежат CD PROJEKT S.A. и
Studio Trigger. Файлов игры здесь нет: интерфейс написан с нуля, а эмблема в стиле Arasaka воссоздана фанатами.
Лицензия MIT, без гарантий. Прочитайте `install.sh` перед запуском: для пакетов он использует `sudo`.
