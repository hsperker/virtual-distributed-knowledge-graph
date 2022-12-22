ARG TRINO_VERSION=403

FROM trinodb/trino:${TRINO_VERSION}

USER root:root
RUN \
    apt-get update && \
    apt-get -y -q install uuid-runtime gettext

COPY --chown=trino:trino docker/etc /etc/trino
COPY template setup.sh /tmp/

RUN chmod 0777 /tmp/setup.sh

USER trino:trino

CMD ["/tmp/setup.sh"]