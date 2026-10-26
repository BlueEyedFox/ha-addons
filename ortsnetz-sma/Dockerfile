FROM python:3.13-alpine

ARG UPSTREAM_COMMIT=6e6087bf14e159709efaf3e416a843bfa7603b33

RUN apk add --no-cache curl jq

ADD https://raw.githubusercontent.com/thomaslehmann1234/datenerfassung-ortsnetz-auslastung/${UPSTREAM_COMMIT}/sma-shm2-ortsnetz-auslastung/ortsnetz-sma-shm2.py /app/ortsnetz-sma-shm2.py

COPY addon.py /app/addon.py
COPY run.sh /run.sh
RUN chmod +x /run.sh

ENTRYPOINT ["/run.sh"]
