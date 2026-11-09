FROM python:3.13-alpine

ARG UPSTREAM_COMMIT=03b91eab2f386f30f023a1f459b6d9e10703772e

RUN apk add --no-cache curl jq

ADD https://raw.githubusercontent.com/thomaslehmann1234/datenerfassung-ortsnetz-auslastung/${UPSTREAM_COMMIT}/sma-shm2-ortsnetz-auslastung/ortsnetz-sma-shm2.py /app/ortsnetz-sma-shm2.py

COPY addon.py /app/addon.py
COPY run.sh /run.sh
RUN chmod +x /run.sh

ENTRYPOINT ["/run.sh"]
