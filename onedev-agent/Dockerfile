ARG UPSTREAM_DIGEST=sha256:82d6ad0e5ae1d8a9e7ad4612bb4a6c5195d96224b2b6b76b666d97f6f60faced
FROM 1dev/agent@${UPSTREAM_DIGEST}

RUN apt-get update \
    && apt-get install -y --no-install-recommends jq \
    && rm -rf /var/lib/apt/lists/*

COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD ["/run.sh"]
