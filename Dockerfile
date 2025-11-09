ARG BUILD_FROM
FROM ${BUILD_FROM}

# Копиране на файловете
COPY pwm_HAOS.py /pwm_HAOS.py
COPY run.sh /run.sh

RUN chmod a+x /run.sh

CMD ["/run.sh"]
