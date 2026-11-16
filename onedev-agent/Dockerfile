ARG UPSTREAM_DIGEST=sha256:9401ecd64a30378dc665029f89069c53b271d5c0e0fa03f37de1f8f4424559e9
FROM 1dev/agent@${UPSTREAM_DIGEST}

RUN apt-get update \
    && apt-get install -y --no-install-recommends jq \
    && rm -rf /var/lib/apt/lists/*

COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD ["/run.sh"]
