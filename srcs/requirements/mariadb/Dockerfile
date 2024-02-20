FROM alpine:3.19.0

RUN apk add mariadb mariadb-client
COPY tools/inception-mariadb.sh /usr/local/bin

ENTRYPOINT ["inception-mariadb.sh"]
