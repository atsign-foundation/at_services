<!-- pyml disable-num-lines 4 md013,md033-->
<h1><a href="https://atsign.com#gh-light-mode-only">
   <img width=250px src="https://atsign.com/wp-content/uploads/2022/05/atsign-logo-horizontal-color2022.svg#gh-light-mode-only" alt="The Atsign Foundation"></a>
<a href="https://atsign.com#gh-dark-mode-only">
   <img width=250px src="https://atsign.com/wp-content/uploads/2023/08/atsign-logo-horizontal-reverse2022-Color.svg#gh-dark-mode-only" alt="The Atsign Foundation"></a></h1>

## at_secondary_proxy

**at_secondary_proxy** acts as a TCP reverse proxy for connections from
clients to secondary servers, where the clients are limited in the ports
they can connect to - for example if they are behind a firewall which limits
the ports that outgoing connections can connect to using an allow-list or
block-list or both.

### Usage

* Configuration
  * The 'certs' subdirectory here contains certs for 'vip.ve.atsign.zone'
  This will allow you to run the proxy on your local machine, serving up
  SecureSockets for 'vip.ve.atsign.zone'
  * You need an entry like this in your local machine's 'hosts' file:
  `127.0.0.1 vip.ve.atsign.zone`
  * The certs dirctory also needs to contain `cacert.pem` which contains
  the root CA public keys.
  * The certs directory can be remmaped if using a container using the
  `/atsign/certs` when using the included Dockerfile.
* Execution
  * Usage:

  ```sh
  bin/main.dart at_proxyserver <this proxies URL> \
  <upstream atDirectory URL> [proxy bind port]
  ```

  * e.g. if running on your local machine, proxying to AtSign's production
  root server at **_root.atsign.org_**, and listening locally on port 443
  * `bin/main.dart vip.ve.atsign.zone:443 root.atsign.org:64`
  * If you are running the process inside a container then you can bind
  the binary to a high port and have the container port map to the high
  port using the optional proxy bind port
* Connecting from an AtClient
  * The AtClient libraries allow you to set rootDomain and rootPort.
  Usually these are left at the default values of `root.atsign.org`
  and `64` respectively.
  * By convention, if you set rootDomain to `proxy:<proxy domain>`,
  then when your client looks up the address of an atSign's remote atServer,
  then rather than getting the actual atServer address, it will receive
  `<proxy domain>:<rootPort>` instead.
  * So ... if for example you are running the proxy locally as outlined above,
  then you will need to set rootDomain and rootPort in your client code to
  `proxy:vip.ve.atsign.zone` and `8443` respectively.
  * The other option is to set the root domain to the domain name of the proxy
  using the `--root-domain` flag of cli tools, this uses port 64. The proxy
  will act as a root directory but send all quiries to the proxy until a
  `from:` verb is received.
  * As of July 2023, this convention is honoured by both the Dart and Java
  atClient SDKs.

### Production usage

* The use of Docker Swarm means several instances of the container can be
running allowing updates without impact to service.
* The certificates need to be valid and kept up to date, this can be achieved
with `certbot` from LetsEncrypt.
* The containers will need to be cycled once in a while to pick up the new
certs.
* Exmaples of the cron entry and docker services stack can be found in the
tools directory.

### Contributions welcome

All of our software is open with intent. We welcome contributions - we want
pull requests, and we want to hear about issues. See also
[CONTRIBUTING.md](../../CONTRIBUTING.md)

## Change log

Changes are logged in the [CHANGELOG.md](CHANGELOG.md) file

## SLSA

The Docker images created from this repo have SLSA Build Level 3 attestations.

These can be verified using the
[slsa-verifier](https://github.com/slsa-framework/slsa-verifier) tool e.g.:

```sh
TAG="latest"
IMAGE="atsigncompany/at_proxyserver"
SHA=$(docker buildx imagetools inspect ${IMAGE}:${TAG} \
  --format "{{json .Manifest}}" | jq -r .digest)
slsa-verifier verify-image ${IMAGE}@${SHA} --source-uri \
  github.com/atsign-foundation/at_server
```
