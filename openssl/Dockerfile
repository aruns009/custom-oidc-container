ARG ALPINE_VERSION=latest

FROM alpine:${ALPINE_VERSION}

ENV NAME "localhost"
ENV CERT "localhost"

RUN apk add --update openssl \
  && rm -rf /var/cache/apk/* \
  && mkdir -p "/certs"

VOLUME ["/certs"]

ENTRYPOINT printf "[SAN]\nsubjectAltName=DNS:${NAME}\n" >> /etc/ssl/openssl.cnf \
  && openssl req \
    -x509 \
    -sha256 \
    -newkey rsa:2048 \
    -keyout "/certs/${CERT}.key" \
    -out "/certs/${CERT}.crt" \
    -days 356 \
    -nodes \
    -subj "/C=GB/ST=SURREY/L=GUILDFORD/O=BAE SYSTEMS APPLIED INTELLIGENCE/OU=IS GROUP/CN=${NAME}" \
    -reqexts SAN \
    -extensions SAN \
    -config /etc/ssl/openssl.cnf
