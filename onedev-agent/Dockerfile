ARG UPSTREAM_DIGEST=sha256:fde2da2ed9540c4e17d18cd33b6ccd26b31622051efb8113bea3542837b653d6
FROM 1dev/agent@${UPSTREAM_DIGEST}

RUN apt-get update \
    && apt-get install -y --no-install-recommends jq \
    && rm -rf /var/lib/apt/lists/*

COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD ["/run.sh"]
