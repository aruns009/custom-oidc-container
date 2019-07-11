# Custom-NGINX-OIDC Service

Welcome to the Custom-NGINX OpenID Connect Service repository.

This repository contains two base images intended to be extended by public facing web applications and APIs. It
provides a preconfigured Custom-NGINX server.

## Web Applications

Web applications simply start from the `nginx-oidc` image and copy files to be served to
`/usr/local/openresty/nginx/html/` into a folder with the same name as path on which the application is hosted.

For example an application that produces build output to `./my/app/build` and is hosted on `/my-app` should do the
following:

```
FROM lego.docker.engineering.csu.local:12345/nginx-openidc:1.2.0
COPY ./my/app/build/ /usr/local/openresty/nginx/html/my-app/
```

### Environment variables

By default the following environment variables are used by the `nginx-oidc` image:

| VARIABLE | DESCRIPTION | DEFAULT |
| :------- | :---------- | :------ |
| REDIRECT_URI | OpenID Connect callback URI | https://ingress/my-app/redirect_uri |
| DISCOVERY_URI | OpenID Connect Identity Provider discovery URI | https://identity-provider/.well-known/openid-configuration |
| CLIENT_ID | OpenID Connect client identifier | client |
| CLIENT_SECRET | OpenID Connect client secret | changeme |
| SESSION_SECRET | Session secret used to encrypt cookies | arandomthirtytwocharacterstring! |
| SSL_VERIFY | Verify Identity Provider's certificate | yes |
| LOGOUT_PATH | OpenID Connect logout path | logoutpath |
| LOGOUT_REDIRECT_URI | OpenID Connect redirect URI after logout | https://identity-provider/auth/realms/MSS/protocol/openid-connect/logout?redirect_uri=logoutredirecturl |
| LOGOUT_WITH_ID_TOKEN_HINT | Verify Token to pass with logout URI | false |
| ERROR_LOG_LEVEL | Set the error log level for the nginx container. Values could be - debug,info,notice,warn,error,crit,alert,emerg | error |

These default values __will not work__ and should be overridden by your application like so:

```
docker run \
  -e REDIRECT_URI="https://mss.baesystems.com/example/redirect_uri" \
  -e DISCOVERY_URI="https://mss.baesystems.com/auth/realms/MSS/.well-known/openid-configuration" \
  -e CLIENT_ID="lego" \
  -e CLIENT_SECRET="secret" \
  -e SESSION_SECRET="anothersecret" \
  -e LOGOUT_PATH="logoutpath" \
  -e LOGOUT_REDIRECT_URI="https://mss.baesystems.com/auth/realms/MSS/protocol/openid-connect/logout?redirect_uri=logoutredirecturl" \
  -e LOGOUT_WITH_ID_TOKEN_HINT="false" \
  example.docker.engineering.csu.local:12345/example
```

## RESTful API

APIs should be hosted behind the `nginx-rs` image. This image ensures clients are authenticated (send valid session
cookie). Clients not presenting a valid session cookie will recieve 401 Unauthorized. Valid requests are parsed and
the `Authorization` header is set to a bearer token using the session cookie `access_token`.

### Environment variables

By default the following environment variables are used by the `nginx-rs` image:

| VARIABLE | DESCRIPTION | DEFAULT |
| :------- | :---------- | :------ |
| PROXY_PASS | Reverse proxy pass URI (protected upstream service) | http://localhost |
| DISCOVERY_URI | OpenID Connect Identity Provider discovery URI | https://identity-provider/.well-known/openid-configuration |
| CLIENT_ID | OpenID Connect client identifier | client |
| CLIENT_SECRET | OpenID Connect client secret | changeme |
| SESSION_SECRET | Session secret used to encrypt cookies | arandomthirtytwocharacterstring! |
| SSL_VERIFY | Verify Identity Provider's certificate | yes |
| ERROR_LOG_LEVEL | Set the error log level for the nginx container. Values could be - debug,info,notice,warn,error,crit,alert,emerg | error |

These default values __will not work__ and should be overridden by your application like so:

```
docker run \
  -e PROXY_PASS="http://localhost:8080" \
  -e DISCOVERY_URI="https://mss.baesystems.com/auth/realms/MSS/.well-known/openid-configuration" \
  -e CLIENT_ID="lego" \
  -e CLIENT_SECRET="secret" \
  -e SESSION_SECRET="anothersecret" \
  lego.docker.engineering.csu.local:12345/nginx-rs:1.2.0
```

## Certificates

This base images comes with default certificates:

* `/usr/local/openresty/nginx/ssl/tls.crt`
* `/usr/local/openresty/nginx/ssl/tls.key`

These should be overriden using volumes like so:

```
docker run \
  -v ./my/certs/tls.crt:/usr/local/openresty/nginx/ssl/tls.crt \
  -v ./my/certs/tls.key:/usr/local/openresty/nginx/ssl/tls.key \
  ...
```

When in Kuberentes the application should request a certificate from cert-manager:

```
apiVersion: certmanager.k8s.io/v1alpha1
kind: Certificate
metadata:
  name: example
spec:
  secretName: example-tls
  issuerRef:
    name: kube-ca-issuer
    kind: ClusterIssuer
  commonName: example.example-namespace.svc.cluster.local
  organization:
  - BAE SYSTEMS
  dnsNames:
  - example.example-namespace.svc.cluster.local
  - example.example-namespace
```

This will create a secret called `example-tls` containing `tls.crt` and `tls.key` that can be mounted to
`/usr/local/openresty/nginx/ssl/` overrwriting the defaults like so:

```
spec:
  containers:
    - name: "example"
      image: "example.docker.engineering.csu.local:12345/example:1.1.0
      volumeMounts:
        - name: tls
          mountPath: "/usr/local/openresty/nginx/ssl/"
          readOnly: true
  volumes:
    - name: tls
      secret:
        secretName: example-tls
```

## Monitoring

To configure Prometheus to scrape metrics apply the following annotations to your Kubernetes Service:

```
annotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "9145"
```

### Getting Started

Start development environment and login.

```
vagrant up && vagrant ssh
```

### Development Server

Make docker containers, install dependencies and start:

```
make
```

Visit https://localhost/

Click the login button in the landing page and you will be redirected to the LEGO identity provider to login, once logged in you will be redirected back to the test page.
