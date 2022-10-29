<img width=250px src="https://atsign.dev/assets/img/@platform_logo_grey.svg?sanitize=true" alt="AtPlatform logo, grey, svg">

## at_secondary_proxy

**_at_secondary_proxy_** acts as a TCP reverse proxy for connections from clients to
secondary servers, where the clients are limited in the ports they can connect to - for
example if they are behind a firewall which limits the ports that outgoing connections
can connect to using an allow-list or block-list or both

### Usage:
* Configuration
  * The 'certs' subdirectory here contains certs for 'vip.ve.atsign.zone'
    This will allow you to run the proxy on your local machine, serving up SecureSockets
    for 'vip.ve.atsign.zone'
  * You need an entry like this in your local machine's 'hosts' file: `127.0.0.1 vip.ve.atsign.zone`
* Execution
  * `bin/main.dart <domain of the atRoot server> <port for this atsign to listen on>`
  * e.g. if running on your local machine, proxying to AtSign's production root server
     at **_root.atsign.org_**, and listening locally on port 8443
  * `bin/main.dart root.atsign.org 8443`
* Connecting from an AtClient
  * The AtClient libraries allow you to set rootDomain and rootPort. Usually these are left at
    the default values of `root.atsign.org` and `64` respectively.
  * By convention, if you set rootDomain to 'proxy:<proxy domain>', then when your client looks up
    the address of an atSign's remote secondary, then rather than getting the actual secondary
    address, it will receive <proxy domain>:<rootPort> instead
  * So ... if for example you are running the proxy locally as outlined above, then you will need
    to set rootDomain and rootPort in your client code to `proxy:vip.ve.atsign.zone` and `8443`
    respectively.
  * NB: As of today July 7, this convention is honoured by the Java libs but not yet by the published
    Dart libs. However, the convention **_is_** honoured by [this branch of the at_lookup repo](https://github.com/atsign-foundation/at_libraries/tree/gkc_add_reverse_proxy_support_to_find_secondary)

### Contributions welcome!

[![gitHub license](https://img.shields.io/badge/license-BSD3-blue.svg)](../LICENSE)

All of our software is open with intent. We welcome contributions - we want pull requests, and we want
to hear about issues. See also [CONTRIBUTING.md](../CONTRIBUTING.md)

## What's here / changelog
### May 21 2022
Initial version of at_secondary_proxy
