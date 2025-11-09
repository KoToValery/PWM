ARG BUILD_FROM
FROM ${BUILD_FROM}

# Инсталиране на Python ако не е налично
RUN apk add --no-cache python3 py3-pip || true

# Копиране на файловете
COPY pwm_HAOS.py /pwm_HAOS.py
COPY run.sh /run.sh

RUN chmod +x /run.sh

CMD ["/run.sh"]
