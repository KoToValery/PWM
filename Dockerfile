FROM python:3.11-alpine

# Копиране на Python скрипта
COPY pwm_HAOS.py /app/pwm_HAOS.py

WORKDIR /app

# Стартиране директно с Python
CMD ["python3", "-u", "pwm_HAOS.py"]
