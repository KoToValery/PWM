# Конфигурация на хост системата

## ⚠️ ВАЖНО - Версия 2.0+

**Добра новина!** От версия 2.0.0 нататък, този addon използва pigpio daemon и **НЕ изисква** промени в `/boot/firmware/config.txt`!

Вече не е необходимо да:
- Редактирате config.txt
- Добавяте device tree overlays
- Рестартирате системата
- Конфигурирате hardware PWM

## Какво е необходимо

### Само pigpio addon

Единственото изискване е да имате инсталиран и работещ **pigpio addon**.

### Инсталация на pigpio addon

**Метод 1: От Home Assistant Add-on Store (препоръчително)**

1. Отидете в Home Assistant → Settings → Add-ons → Add-on Store
2. Кликнете на трите точки (⋮) в горния десен ъгъл
3. Изберете "Repositories"
4. Добавете: `https://github.com/hassio-addons/repository`
5. Намерете и инсталирайте **"pigpio"** addon
6. Отидете в pigpio addon страницата
7. Натиснете "Start"
8. Активирайте "Start on boot"
9. (Опционално) Активирайте "Watchdog"

**Метод 2: Ръчна инсталация на хост системата**

Ако предпочитате да инсталирате pigpio директно на Debian хост системата:

```bash
# Инсталация
sudo apt-get update
sudo apt-get install pigpio

# Стартиране
sudo systemctl enable pigpiod
sudo systemctl start pigpiod

# Проверка
sudo systemctl status pigpiod
```

### Проверка на pigpio

След инсталация, проверете дали pigpio daemon работи:

```bash
# Проверка на процеса
ps aux | grep pigpiod

# Проверка на порта
netstat -an | grep 8888

# Или
ss -tuln | grep 8888
```

Очакван изход:
```
tcp        0      0 0.0.0.0:8888            0.0.0.0:*               LISTEN
```

## Миграция от версия 1.x

Ако сте използвали версия 1.x с hardware PWM:

### Стъпка 1: Инсталирайте pigpio addon
Следвайте инструкциите по-горе.

### Стъпка 2: Обновете PWM LED Controller
Обновете до версия 2.0.0 или по-нова.

### Стъпка 3: (Опционално) Почистете config.txt

Ако сте добавили PWM overlay в `/boot/firmware/config.txt`, можете да го премахнете:

```bash
sudo nano /boot/firmware/config.txt
```

Премахнете редовете:
```bash
# Тези редове вече не са необходими
dtoverlay=pwm,pin=12,func=4
# или
dtoverlay=pwm-2chan,pin=12,func=4,pin2=13,func2=4
```

Запазете и рестартирайте (опционално).

## Предимства на новия подход

✓ **Без промени в config.txt** - Не е нужно да редактирате системни файлове  
✓ **Без рестарт** - Работи веднага след инсталация  
✓ **Всички GPIO пинове** - Не само hardware PWM пинове  
✓ **По-сигурно** - Не изисква full_access права  
✓ **По-лесно** - Само инсталирайте pigpio addon  
✓ **Множество канали** - Използвайте колкото искате GPIO пинове  

## Отстраняване на проблеми

### pigpio addon не се стартира

**Решение:**
1. Проверете логовете на pigpio addon
2. Уверете се, че нямате конфликт с друг GPIO процес
3. Рестартирайте хост системата ако е необходимо

### Connection refused от PWM addon

**Решение:**
1. Уверете се, че pigpio addon е стартиран
2. Проверете дали pigpiod слуша на порт 8888
3. Рестартирайте pigpio addon
4. Рестартирайте PWM LED Controller addon

### GPIO pin не работи

**Решение:**
1. Проверете физическата връзка
2. Тествайте с различен GPIO пин
3. Проверете дали пинът не се използва от друго устройство
4. Проверете логовете на pigpio addon

## Полезни команди

### Проверка на pigpio статус

```bash
# Статус на daemon
sudo systemctl status pigpiod

# Проверка на порта
netstat -tuln | grep 8888

# Проверка на процеса
ps aux | grep pigpiod

# Проверка на GPIO статус
cat /sys/kernel/debug/gpio
```

### Ръчно тестване на GPIO с pigpio

```bash
# Инсталирайте pigpio utils
sudo apt-get install pigpio-tools

# Тест на GPIO 12 - включване
pigs w 12 1

# Тест на GPIO 12 - изключване
pigs w 12 0

# PWM на GPIO 12 - 50% duty cycle
pigs p 12 128
```

## Допълнителна информация

- [pigpio документация](http://abyz.me.uk/rpi/pigpio/)
- [pigpio Python библиотека](http://abyz.me.uk/rpi/pigpio/python.html)
- [Home Assistant pigpio addon](https://github.com/hassio-addons/addon-pigpio)

## Стар подход (версия 1.x) - Архивирано

<details>
<summary>Кликнете за информация за стария hardware PWM подход</summary>

### Стар метод - Hardware PWM чрез sysfs (НЕ СЕ ПРЕПОРЪЧВА)

Този метод вече не се използва във версия 2.0+.

```bash
# Редактиране на config.txt
sudo nano /boot/firmware/config.txt

# Добавяне на overlay
dtoverlay=pwm,pin=12,func=4

# Рестарт
sudo reboot
```

**Проблеми със стария подход:**
- Изисква full_access права
- Изисква промени в системни файлове
- Изисква рестарт на системата
- Работи само с hardware PWM пинове
- Read-only filesystem проблеми в контейнери

</details>
