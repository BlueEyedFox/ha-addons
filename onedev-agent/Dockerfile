ARG UPSTREAM_DIGEST=sha256:31a895eef1b54f020b551a3521157083287660a2b54b6a635283ba4dc06e6bcd
FROM 1dev/agent@${UPSTREAM_DIGEST}

RUN apt-get update \
    && apt-get install -y --no-install-recommends jq \
    && rm -rf /var/lib/apt/lists/*

COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD ["/run.sh"]
