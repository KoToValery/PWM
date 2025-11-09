ARG BUILD_FROM
FROM ${BUILD_FROM}

# Копиране на Python скрипта
COPY pwm_HAOS.py /app/pwm_HAOS.py

# Копиране на s6 services
COPY rootfs /

# Права за изпълнение
RUN chmod a+x /etc/services.d/pwm/run && \
    chmod a+x /etc/services.d/pwm/finish

WORKDIR /app
