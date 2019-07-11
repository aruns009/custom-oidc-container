#!bin/sh
# openresty entrypoint

# create configuration from templates
envsubst < /tmpl/nginx.tmpl > /usr/local/openresty/nginx/conf/nginx.conf
envsubst < /tmpl/default.tmpl > /etc/nginx/conf.d/default.conf
envsubst < /tmpl/prometheus.tmpl > /etc/nginx/conf.d/prometheus.conf

# start nginx
openresty -g 'daemon off;'
