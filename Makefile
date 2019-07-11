# Makefile
# provides helper targets to run docker-compose commands

# all targets are phony
# https://www.gnu.org/software/make/manual/html_node/Phony-Targets.html
.PHONY: certs-build certs rm rmi clean down build up logs

# default 'make' command uses docker-compose.yaml to build, up -d and logs -f
.DEFAULT_GOAL := logs

# certificate directory
CERTS :=

# build openssl image used to create self-signed certs
certs-build:
	docker build --build-arg HTTP_PROXY -t openssl ./openssl

# generate self-signed certificates
certs: certs-build
	@if [ ! -f $(CURDIR)/localhost/localhost.crt ] || [ ! -f $(CURDIR)/localhost/localhost.key ]; then \
		docker run --rm -v $(CURDIR)/localhost:/certs openssl; \
	fi
	@if [ ! -f $(CURDIR)/nginx-oidc/tls.crt ] || [ ! -f $(CURDIR)/nginx-oidc/tls.key ]; then \
		docker run --rm -v $(CURDIR)/nginx-oidc:/certs -e "NAME=nginx-oidc" -e "CERT=tls" openssl; \
	fi
	@if [ ! -f $(CURDIR)/nginx-rs/tls.crt ] || [ ! -f $(CURDIR)/nginx-rs/tls.key ]; then \
		docker run --rm -v $(CURDIR)/nginx-rs:/certs -e "NAME=nginx-rs" -e "CERT=tls" openssl; \
	fi

# remove all containers
rm:
	docker ps -aq | xargs -r docker rm -f

# remove all images
rmi:
	docker images -aq | xargs -r docker rmi -f

# remove all containers, images and volumes
clean: rm rmi

# kill and remove containers and volumes
down:
	docker-compose down -v

# build images
build: certs
	docker-compose build

# run containers in background
up: build
	docker-compose up -d

# follow logs
logs: up
	docker-compose logs -f
