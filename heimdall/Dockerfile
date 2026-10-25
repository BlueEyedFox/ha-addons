ARG HEIMDALL_VERSION=2.8.3
FROM linuxserver/heimdall:${HEIMDALL_VERSION}

RUN apk add --no-cache jq

COPY run.sh /run.sh
RUN chmod +x /run.sh

ENTRYPOINT ["/run.sh"]
