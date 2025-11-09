# PWM LED Controller за Home Assistant OS

**Версия 3.0** - Архитектура с PWM Daemon

Addon за управление на LED светлини или вентилатори чрез Hardware PWM на GPIO пинове за Raspberry Pi 5.

## Архитектура

```
Raspberry Pi OS (Host)
├─ systemd service: pwm-daemon
│  ├─ Управлява /sys/class/pwm със root достъп
│  └─ Слуша на TCP порт 9000
│
HAOS Container (Supervisor)
├─ PWM LED Controller add-on
│  ├─ HTTP REST API към pwm-daemon:9000
│  └─ Няма нужда от хардуерни привилегии
│
Комуникация: HTTP REST API
```

## Предимства на този подход

✓ **Чисто разделение** - Daemon с root права, addon без привилегии  
✓ **Сигурност** - Addon няма директен достъп до hardware  
✓ **Стабилност** - Daemon работи независимо от HAOS  
✓ **Множество клиенти** - Няколко addon-а могат да използват един daemon  
✓ **Лесна поддръжка** - Daemon и addon се обновяват независимо  
✓ **26 kHz PWM** - Hardware PWM за вентилатори  

## Инсталация

### Част 1: PWM Daemon на хост системата

**Стъпка 1: Конфигурация на config.txt**

Редактирайте `/boot/firmware/config.txt`:

```bash
sudo nano /boot/firmware/config.txt
```

Добавете в края:

```bash
# Hardware PWM на GPIO12
dtoverlay=pwm,pin=12,func=4
```

Запазете и рестартирайте:

```bash
sudo reboot
```

**Стъпка 2: Инсталация на daemon**

```bash
# Копирайте файловете от host-daemon/
cd host-daemon/

# Направете install скрипта изпълним
chmod +x install.sh

# Стартирайте инсталацията
sudo ./install.sh
```

**Стъпка 3: Проверка на daemon**

```bash
# Проверете статус
sudo systemctl status pwm-daemon

# Проверете логове
sudo journalctl -u pwm-daemon -f

# Тест на API
curl http://localhost:9000/status
```

Очакван отговор:
```json
{"status": "ok", "pwm": {}}
```

### Част 2: HAOS Addon

**Стъпка 1: Инсталация**

1. Копирайте папката на addon в `/addons/pwm_led/`
2. Home Assistant → Settings → Add-ons
3. "Check for updates"
4. Инсталирайте "PWM LED Controller"

**Стъпка 2: Конфигурация**

```yaml
gpio_pin: 12
duty_cycle: 60
frequency: 26000
auto_start: true
daemon_host: "127.0.0.1"
daemon_port: 9000
```

**Стъпка 3: Стартиране**

1. Save → Start
2. Проверете логовете

## Конфигурация

### Опции на addon

- **gpio_pin** (1-27): GPIO пин номер (по подразбиране: 12)
  - Hardware PWM пинове: 12, 13, 18, 19
- **duty_cycle** (0-100): Процент на PWM сигнала (по подразбиране: 50)
- **frequency** (1000-100000): Честота в Hz (по подразбиране: 26000)
- **auto_start** (true/false): Автоматично стартиране (по подразбиране: true)
- **daemon_host** (string): IP адрес на daemon (по подразбиране: "127.0.0.1")
- **daemon_port** (int): Порт на daemon (по подразбиране: 9000)

### Примери

**4-pin PWM вентилатор:**
```yaml
gpio_pin: 12
duty_cycle: 60
frequency: 25000
auto_start: true
```

**LED лента:**
```yaml
gpio_pin: 13
duty_cycle: 80
frequency: 1000
auto_start: true
```

## PWM Daemon API

### Endpoints

**POST /init** - Инициализация на PWM
```bash
curl -X POST http://localhost:9000/init \
  -H "Content-Type: application/json" \
  -d '{"gpio_pin": 12, "frequency": 26000}'
```

**POST /duty** - Настройка на duty cycle
```bash
curl -X POST http://localhost:9000/duty \
  -H "Content-Type: application/json" \
  -d '{"gpio_pin": 12, "duty_cycle": 75}'
```

**POST /enable** - Включване на PWM
```bash
curl -X POST http://localhost:9000/enable \
  -H "Content-Type: application/json" \
  -d '{"gpio_pin": 12}'
```

**POST /disable** - Изключване на PWM
```bash
curl -X POST http://localhost:9000/disable \
  -H "Content-Type: application/json" \
  -d '{"gpio_pin": 12}'
```

**GET /status** - Статус на всички PWM
```bash
curl http://localhost:9000/status
```

**GET /status/{pin}** - Статус на конкретен GPIO
```bash
curl http://localhost:9000/status/12
```

## Отстраняване на проблеми

### Daemon не се стартира

**Проверка:**
```bash
sudo systemctl status pwm-daemon
sudo journalctl -u pwm-daemon -n 50
```

**Решение:**
1. Проверете дали config.txt е правилно конфигуриран
2. Рестартирайте системата
3. Проверете дали `/sys/class/pwm/` съществува

### Addon не може да се свърже с daemon

**Грешка:** `Cannot connect to pwm-daemon!`

**Решение:**
1. Проверете дали daemon работи: `sudo systemctl status pwm-daemon`
2. Проверете дали порт 9000 е отворен: `netstat -tuln | grep 9000`
3. Проверете `host_network: true` в config.yaml
4. Рестартирайте daemon: `sudo systemctl restart pwm-daemon`

### PWM не работи

**Решение:**
1. Проверете логовете на daemon: `sudo journalctl -u pwm-daemon -f`
2. Тествайте API ръчно с curl
3. Проверете физическата връзка
4. Проверете дали GPIO пинът поддържа Hardware PWM

### Permission denied в daemon

**Решение:**
- Daemon трябва да работи с root права (systemd service го прави автоматично)
- Проверете: `ps aux | grep pwm_daemon`

## Управление на daemon

```bash
# Статус
sudo systemctl status pwm-daemon

# Стартиране
sudo systemctl start pwm-daemon

# Спиране
sudo systemctl stop pwm-daemon

# Рестарт
sudo systemctl restart pwm-daemon

# Логове
sudo journalctl -u pwm-daemon -f

# Деактивиране на autostart
sudo systemctl disable pwm-daemon

# Активиране на autostart
sudo systemctl enable pwm-daemon
```

## Деинсталация

**Daemon:**
```bash
sudo systemctl stop pwm-daemon
sudo systemctl disable pwm-daemon
sudo rm /etc/systemd/system/pwm-daemon.service
sudo rm /usr/local/bin/pwm_daemon.py
sudo systemctl daemon-reload
```

**Addon:**
- Home Assistant → Settings → Add-ons → PWM LED Controller → Uninstall

## Технически детайли

- **Daemon:** Python 3 HTTP сървър
- **API:** REST JSON
- **PWM:** Hardware PWM чрез sysfs
- **Честота:** 1 kHz - 100 kHz
- **Duty Cycle:** 0-100%
- **Порт:** 9000 (конфигурируем)

## Поддържани платформи

- Raspberry Pi 5 (aarch64)
- Home Assistant OS Supervised на Debian

## Лиценз

MIT
