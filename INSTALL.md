# Пълна инсталация - PWM LED Controller v3.0

## Преглед

Този addon използва daemon архитектура за управление на Hardware PWM:

1. **PWM Daemon** - Работи на хост системата с root права
2. **HAOS Addon** - Комуникира с daemon чрез HTTP API

---

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

Запазете (Ctrl+O, Enter, Ctrl+X) и рестартирайте:

```bash
sudo reboot
```

### Стъпка 2: Инсталация на PWM Daemon (една команда!)

След рестарт, изпълнете:

```bash
curl -sSL https://raw.githubusercontent.com/KoToValery/PWM/main/quick-install.sh | sudo bash
```

Това ще:
- Изтегли необходимите файлове от GitHub
- Инсталира daemon в `/usr/local/bin/`
- Създаде systemd service
- Стартира daemon автоматично

### Стъпка 3: Проверка на Daemon

```bash
# Проверете статус
sudo systemctl status pwm-daemon

# Тест на API
curl http://localhost:9000/status
```

Очакван отговор:
```json
{"status": "ok", "pwm": {}}
```

### Стъпка 4: Инсталация на HAOS Addon от GitHub

**Метод 1: Добавяне на Repository (Препоръчително)**

1. Отворете Home Assistant
2. Settings → Add-ons → Add-on Store
3. Кликнете на трите точки "⋮" (горе дясно)
4. Изберете "Repositories"
5. Добавете URL: `https://github.com/KoToValery/PWM`
6. Кликнете "Add"
7. Затворете прозореца
8. Refresh страницата или "Check for updates"
9. Намерете "PWM LED Controller" в списъка
10. Кликнете → Install
11. Изчакайте build-а (2-3 минути)

**Метод 2: Локална инсталация (за Supervised)**

Ако горният метод не работи:

```bash
# Клонирайте repo в local addons папката
cd /usr/share/hassio/addons/local/
sudo git clone https://github.com/KoToValery/PWM.git pwm_led
```

След това в Home Assistant:
1. Settings → Add-ons
2. Кликнете "⋮" → "Check for updates"
3. Намерете "PWM LED Controller" в "Local add-ons"
4. Install

### Стъпка 5: Конфигурация на Addon

След инсталация, отворете addon-а и конфигурирайте:

```yaml
gpio_pin: 12
duty_cycle: 60
frequency: 26000
auto_start: true
daemon_host: "127.0.0.1"
daemon_port: 9000
```

### Стъпка 6: Стартиране

1. Save
2. Start
3. Проверете логовете - трябва да видите:
   ```
   ✓ Connected to pwm-daemon at http://127.0.0.1:9000
   ✓ PWM initialized: GPIO12, 26000Hz
   ✓ Duty cycle set to 60%
   ✓ PWM enabled
   ✓ PWM started automatically
   ```

---

## 🎉 Готово!

PWM контролерът работи!

---

## 🧪 Тестване

Можете да тествате daemon директно:

```bash
curl -sSL https://raw.githubusercontent.com/KoToValery/PWM/main/host-daemon/test_api.sh -o test_api.sh
chmod +x test_api.sh
./test_api.sh
```

---

## 🐛 Отстраняване на проблеми

### Addon не се появява в списъка

**Решение:**
1. Проверете дали repository URL е правилен
2. Refresh страницата на Add-on Store
3. Проверете Settings → System → Logs за грешки

### Build грешка при инсталация

**Ако видите грешка при build:**

1. Проверете логовете: Settings → System → Logs
2. Опитайте локална инсталация (Метод 2)
3. Уверете се, че имате интернет връзка

### Daemon не се стартира

```bash
sudo journalctl -u pwm-daemon -n 50
```

Проверете дали config.txt е правилно конфигуриран и системата е рестартирана.

### Addon не може да се свърже

```bash
# Проверете daemon
sudo systemctl status pwm-daemon

# Проверете порта
netstat -tuln | grep 9000

# Рестартирайте daemon
sudo systemctl restart pwm-daemon
```

### PWM не работи

1. Проверете физическата връзка
2. Проверете дали GPIO 12 е правилно свързан
3. Тествайте с мултиметър или осцилоскоп
4. Проверете логовете:
   ```bash
   sudo journalctl -u pwm-daemon -f
   ```

### Преинсталация на daemon

```bash
# Деинсталирай
sudo systemctl stop pwm-daemon
sudo systemctl disable pwm-daemon
sudo rm /etc/systemd/system/pwm-daemon.service
sudo rm /usr/local/bin/pwm_daemon.py
sudo systemctl daemon-reload

# Инсталирай отново
curl -sSL https://raw.githubusercontent.com/KoToValery/PWM/main/quick-install.sh | sudo bash
```

---

## 📚 Допълнителна документация

- [Пълна документация](README.md)
- [Daemon документация](host-daemon/README.md)
- [Troubleshooting Guide](TROUBLESHOOTING.md)
- [Changelog](CHANGELOG.md)

---

## 🔧 Полезни команди

```bash
# Daemon управление
sudo systemctl status pwm-daemon      # Статус
sudo systemctl restart pwm-daemon     # Рестарт
sudo journalctl -u pwm-daemon -f      # Логове

# API тестове
curl http://localhost:9000/status     # Общ статус

# Инициализация на PWM
curl -X POST http://localhost:9000/init \
  -H "Content-Type: application/json" \
  -d '{"gpio_pin": 12, "frequency": 26000}'

# Настройка на duty cycle
curl -X POST http://localhost:9000/duty \
  -H "Content-Type: application/json" \
  -d '{"gpio_pin": 12, "duty_cycle": 75}'

# Включване
curl -X POST http://localhost:9000/enable \
  -H "Content-Type: application/json" \
  -d '{"gpio_pin": 12}'

# Статус на GPIO 12
curl http://localhost:9000/status/12
```

---

## 🗑️ Деинсталация

### Daemon

```bash
sudo systemctl stop pwm-daemon
sudo systemctl disable pwm-daemon
sudo rm /etc/systemd/system/pwm-daemon.service
sudo rm /usr/local/bin/pwm_daemon.py
sudo systemctl daemon-reload
```

### Addon

Home Assistant → Settings → Add-ons → PWM LED Controller → Uninstall

---

## 📞 Поддръжка

- GitHub: https://github.com/KoToValery/PWM
- Issues: https://github.com/KoToValery/PWM/issues
- Discussions: https://github.com/KoToValery/PWM/discussions
