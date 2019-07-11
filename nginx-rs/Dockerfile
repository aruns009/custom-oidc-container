ARG OPENRESTY_VERSION="alpine"
FROM openresty/openresty:${OPENRESTY_VERSION}

# used to escape dollar symbols in nginx configuration templates
ENV DOLLAR $

# default env vars
ENV LUA_SSL_TRUSTED_CERTIFICATE /etc/ssl/certs/ca-certificates.crt
ENV DISCOVERY_URI https://identity-provider/.well-known/openid-configuration
ENV CLIENT_ID client
ENV CLIENT_SECRET changeme
ENV SESSION_SECRET arandomthirtytwocharacterstring!
ENV SSL_VERIFY yes
ENV PROXY_PASS http://localhost
ENV ERROR_LOG_LEVEL error

# server port
EXPOSE 443

# default certificates
COPY tls.crt /usr/local/openresty/nginx/ssl/
COPY tls.key /usr/local/openresty/nginx/ssl/

# nginx templates
COPY *.tmpl /tmpl/

# entrypoint substitutes env vars in templates files
COPY docker-entrypoint.sh /

# to use opm in the alpine image, you must also install the curl and perl packages
# envsubst is used to template nginx configuration which is provided by gettext package
# clean out /usr/local/openresty/nginx/html and /var/cache/apk
# ensure docker-entrypoint.sh is executable
RUN apk add --no-cache curl perl gettext && \
    opm install zmartzone/lua-resty-openidc && \
    opm install knyar/nginx-lua-prometheus && \
    rm -rf /usr/local/openresty/nginx/html/* && \
    rm -rf /var/cache/apk/* && \
    chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
