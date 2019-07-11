ARG OPENRESTY_VERSION="alpine"
FROM openresty/openresty:${OPENRESTY_VERSION}

# used to escape dollar symbols in nginx configuration templates
ENV DOLLAR $

# default env variables
ENV LUA_SSL_TRUSTED_CERTIFICATE /etc/ssl/certs/ca-certificates.crt
ENV REDIRECT_URI https://ingress/my-app/redirect_uri
ENV DISCOVERY_URI https://identity-provider/.well-known/openid-configuration
ENV CLIENT_ID client
ENV CLIENT_SECRET changeme
ENV SESSION_SECRET arandomthirtytwocharacterstring!
ENV SSL_VERIFY yes
ENV LOGOUT_PATH logoutpath
ENV LOGOUT_REDIRECT_URI https://identity-provider/auth/realms/MSS/protocol/openid-connect/logout?redirect_uri=logoutredirecturl
ENV LOGOUT_WITH_ID_TOKEN_HINT false
ENV ERROR_LOG_LEVEL error

# server and metrics ports
EXPOSE 443 9145

# default certificates
COPY tls.crt /usr/local/openresty/nginx/ssl/
COPY tls.key /usr/local/openresty/nginx/ssl/

# nginx templates
COPY *.tmpl /tmpl/

# entrypoint substitutes env vars in templates files
COPY docker-entrypoint.sh /

# to use opm in the alpine image, you must also install the curl and perl packages
# clean out default html from /usr/local/openresty/nginx/html
# copies ca-certificates to k8s service account so that lua_ssl_trusted_certificate can be defaulted
RUN apk add --no-cache curl perl gettext && \
    opm install zmartzone/lua-resty-openidc && \
    opm install knyar/nginx-lua-prometheus && \
    rm -rf /usr/local/openresty/nginx/html && \
    mkdir -p /usr/local/openresty/nginx/ssl && \
    chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]