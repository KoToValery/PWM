# PWM LED Controller за Home Assistant OS

Addon за управление на LED светлини или вентилатори чрез **Hardware PWM** на GPIO пинове за Raspberry Pi 5.

**Поддържа високи честоти до 100 kHz** - идеално за 4-pin PWM вентилатори (25-26 kHz).

## 🚀 Бърза инсталация

### Стъпка 1: Конфигурация на config.txt

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

### Стъпка 2: Инсталация на PWM Daemon (една команда!)

```bash
curl -sSL https://raw.githubusercontent.com/KoToValery/PWM/main/quick-install.sh | sudo bash
```

### Стъпка 3: Инсталация на HAOS Addon

1. Home Assistant → Settings → Add-ons → Add-on Store
2. Кликнете "⋮" → "Repositories"
3. Добавете: `https://github.com/KoToValery/PWM`
4. Намерете "PWM LED Controller" → Install
5. Configure → Start

## ✨ Особености

- 🎯 **Hardware PWM** - До 100 kHz честота
- 🔧 **26 kHz за вентилатори** - Стандартна честота за 4-pin PWM вентилатори
- 🏗️ **Daemon архитектура** - Чисто разделение на отговорности
- 🔒 **Сигурност** - Addon без hardware привилегии
- 📡 **HTTP REST API** - Лесна интеграция
- 🔄 **Множество канали** - Поддръжка за няколко GPIO пинове

## 🏗️ Архитектура

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
```

## ⚙️ Конфигурация

```yaml
gpio_pin: 12          # GPIO пин (12, 13, 18, 19 за Hardware PWM)
duty_cycle: 60        # 0-100%
frequency: 26000      # Hz (1000-100000)
auto_start: true      # Автоматично стартиране
```

## 📖 Документация

- [Пълна инсталация](INSTALL.md)
- [Daemon документация](host-daemon/README.md)
- [Changelog](CHANGELOG.md)

## 🔧 Hardware PWM пинове на Raspberry Pi 5

| GPIO Pin | PWM Channel | Забележка |
|----------|-------------|-----------|
| GPIO 12  | PWM0        | ✓ Препоръчан |
| GPIO 13  | PWM1        | ✓ Алтернативен |
| GPIO 18  | PWM0        | ✓ Алтернативен |
| GPIO 19  | PWM1        | ✓ Алтернативен |

## 📡 REST API

### Примери

```bash
# Инициализация
curl -X POST http://localhost:9000/init \
  -H "Content-Type: application/json" \
  -d '{"gpio_pin": 12, "frequency": 26000}'

# Duty cycle
curl -X POST http://localhost:9000/duty \
  -H "Content-Type: application/json" \
  -d '{"gpio_pin": 12, "duty_cycle": 75}'

# Включване
curl -X POST http://localhost:9000/enable \
  -H "Content-Type: application/json" \
  -d '{"gpio_pin": 12}'

# Статус
curl http://localhost:9000/status/12
```

## 🐛 Отстраняване на проблеми

### Daemon не се стартира

```bash
sudo journalctl -u pwm-daemon -n 50
```

### Addon не може да се свърже

```bash
sudo systemctl status pwm-daemon
sudo systemctl restart pwm-daemon
```

### Тестване на API

```bash
curl -sSL https://raw.githubusercontent.com/KoToValery/PWM/main/host-daemon/test_api.sh -o test_api.sh
chmod +x test_api.sh
./test_api.sh
```

## 📝 Лиценз

MIT License

---

**Забележка:** Този addon изисква Raspberry Pi 5 с Home Assistant OS Supervised на Debian.
