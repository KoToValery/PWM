# Отстраняване на проблеми

## Инсталация на Addon

### Addon не се появява в списъка

**Проблем:** След клониране на repo, addon не се вижда в Home Assistant.

**Решение:**

1. Проверете пътя на addons папката:
   ```bash
   # За HAOS Supervised на Debian:
   ls -la /usr/share/hassio/addons/local/
   
   # Трябва да видите папка pwm_led/
   ```

2. Проверете дали файловете са на правилното място:
   ```bash
   ls -la /usr/share/hassio/addons/local/pwm_led/
   # Трябва да видите: config.yaml, Dockerfile, pwm_HAOS.py, run.sh
   ```

3. Рестартирайте Supervisor:
   ```bash
   ha supervisor restart
   ```

4. В Home Assistant: Settings → Add-ons → "⋮" → "Check for updates"

### Build грешка при инсталация

**Проблем:** `Can't install ... 403 Forbidden` или `denied`

**Причина:** Опит за изтегляне на Docker image от registry, който не съществува.

**Решение:** Уверете се, че `config.yaml` и `config.json` **НЕ** съдържат `image:` поле. Home Assistant трябва да build-не локално.

### Build отнема много време

**Нормално:** Първият build може да отнеме 2-5 минути на Raspberry Pi 5.

**Проверка на прогреса:**
```bash
# Проверете Docker build логове
docker ps -a | grep pwm
ha addons logs pwm_led
```

## PWM Daemon

### Daemon не се стартира

**Проверка:**
```bash
sudo systemctl status pwm-daemon
```

**Ако не е активен:**
```bash
sudo journalctl -u pwm-daemon -n 50
```

**Чести причини:**

1. **PWM не е конфигуриран в config.txt**
   ```bash
   # Проверете
   grep pwm /boot/firmware/config.txt
   
   # Трябва да видите:
   # dtoverlay=pwm,pin=12,func=4
   ```

2. **Системата не е рестартирана след промяна в config.txt**
   ```bash
   sudo reboot
   ```

3. **PWM устройството не съществува**
   ```bash
   ls -la /sys/class/pwm/
   # Трябва да видите pwmchip0, pwmchip2 или pwmchip3
   ```

### Daemon работи, но API не отговаря

**Проверка:**
```bash
# Проверете дали слуша на порт 9000
netstat -tuln | grep 9000
# или
ss -tuln | grep 9000

# Трябва да видите:
# tcp   0   0 0.0.0.0:9000   0.0.0.0:*   LISTEN
```

**Тест на API:**
```bash
curl http://localhost:9000/status
# Очакван отговор: {"status": "ok", "pwm": {}}
```

**Ако не работи:**
```bash
# Рестартирайте daemon
sudo systemctl restart pwm-daemon

# Проверете firewall (ако има)
sudo iptables -L -n | grep 9000
```

## Addon

### Addon не може да се свърже с daemon

**Грешка в логовете:** `Cannot connect to pwm-daemon!`

**Проверки:**

1. **Daemon работи ли?**
   ```bash
   sudo systemctl status pwm-daemon
   ```

2. **host_network активирано ли е?**
   - Проверете `config.yaml`: трябва да има `host_network: true`

3. **Правилен ли е host и port?**
   - В addon конфигурацията: `daemon_host: "127.0.0.1"`, `daemon_port: 9000`

4. **Тест от контейнера:**
   ```bash
   # Влезте в addon контейнера
   docker exec -it addon_pwm_led /bin/sh
   
   # Тествайте връзката
   wget -O- http://127.0.0.1:9000/status
   ```

### PWM не работи

**Addon стартира, но PWM не се включва**

**Проверки:**

1. **Проверете логовете на addon:**
   - Home Assistant → Add-ons → PWM LED Controller → Logs

2. **Проверете логовете на daemon:**
   ```bash
   sudo journalctl -u pwm-daemon -f
   ```

3. **Тествайте API ръчно:**
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

4. **Проверете физическата връзка:**
   - GPIO 12 е Pin 32 на 40-pin header
   - Проверете с мултиметър или осцилоскоп

5. **Проверете дали GPIO е правилно конфигуриран:**
   ```bash
   sudo cat /sys/kernel/debug/pinctrl/1f000d0000.gpio-pinctrl-rp1/pinmux-pins | grep "pin 12"
   # Трябва да видите: pin 12 (gpio12): ... function pwm0
   ```

## Общи проблеми

### Permission denied

**В daemon логовете:** `Permission denied writing to /sys/class/pwm/...`

**Решение:** Daemon трябва да работи с root права (systemd service го прави автоматично).

### GPIO pin already in use

**Грешка:** GPIO пинът вече се използва

**Решение:**
```bash
# Проверете какво използва GPIO
cat /sys/kernel/debug/gpio | grep gpio-12

# Деактивирайте конфликтни устройства или изберете друг GPIO пин
```

### Addon не се стартира след рестарт

**Проверка:**
```bash
# Проверете дали daemon е активиран за autostart
sudo systemctl is-enabled pwm-daemon
# Трябва да върне: enabled

# Ако не е:
sudo systemctl enable pwm-daemon
```

## Полезни команди

```bash
# Daemon
sudo systemctl status pwm-daemon        # Статус
sudo systemctl restart pwm-daemon       # Рестарт
sudo journalctl -u pwm-daemon -f        # Логове в реално време
sudo journalctl -u pwm-daemon -n 100    # Последни 100 реда

# API тестове
curl http://localhost:9000/status       # Общ статус
curl http://localhost:9000/status/12    # Статус на GPIO 12

# Home Assistant
ha addons                               # Списък с addons
ha addons info pwm_led                  # Информация за addon
ha addons logs pwm_led                  # Логове на addon
ha addons restart pwm_led               # Рестарт на addon

# Docker
docker ps | grep pwm                    # Работещи контейнери
docker logs addon_pwm_led               # Логове на контейнера

# GPIO/PWM
ls -la /sys/class/pwm/                  # PWM устройства
cat /sys/kernel/debug/gpio              # GPIO статус
```

## Все още имате проблеми?

1. Съберете информация:
   ```bash
   # Създайте debug log
   {
     echo "=== System Info ==="
     uname -a
     echo ""
     echo "=== PWM Daemon Status ==="
     sudo systemctl status pwm-daemon
     echo ""
     echo "=== PWM Daemon Logs ==="
     sudo journalctl -u pwm-daemon -n 50
     echo ""
     echo "=== PWM Devices ==="
     ls -la /sys/class/pwm/
     echo ""
     echo "=== GPIO 12 Status ==="
     sudo cat /sys/kernel/debug/pinctrl/1f000d0000.gpio-pinctrl-rp1/pinmux-pins | grep "pin 12"
     echo ""
     echo "=== API Test ==="
     curl http://localhost:9000/status
   } > pwm_debug.log 2>&1
   
   cat pwm_debug.log
   ```

2. Отворете issue в GitHub: https://github.com/KoToValery/PWM/issues
3. Прикачете `pwm_debug.log` файла
