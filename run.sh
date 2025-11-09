#!/usr/bin/with-contenv bashio

bashio::log.info "Starting PWM LED Controller..."

# Run the Python script
python3 /pwm_HAOS.py
