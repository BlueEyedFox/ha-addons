ARG ONEDEV_VERSION=17.0.2
FROM 1dev/server:${ONEDEV_VERSION}

RUN apt-get update \
    && apt-get install -y --no-install-recommends jq \
    && rm -rf /var/lib/apt/lists/*

COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD ["/run.sh"]
