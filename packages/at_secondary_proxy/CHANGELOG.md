# at_secondary_proxy CHANGELOG

## 2.3.1

- fix: reduce the secondary address cache TTL from the 1-hour default to 1
  minute, using the new configurable `cacheDuration` param on
  `CacheableSecondaryAddressFinder`. Limits how long the proxy can keep
  routing to a stale secondary address after an atSign is reset.

## 2.3.0

- feat: arg parsing

## 2.2.0

- feat: bridge inbound WebSocket connections (path `/ws`, ALPN
  `http/1.1`) to upstream atServers. The bridge mirrors the existing
  TCP `SecondaryConnectionBridge`: it writes `@` to the client on
  connect, waits for `from:<atSign>\n`, looks up the upstream
  atServer, opens a WebSocket to it, and forwards frames
  bidirectionally preserving text/binary frame type.

## 2.1.0

- feat: enable proxy service to handle http GET requests

## 2.0.2

- fix: use different SecurityContexts for (1) the bound server socket
  (2) creation of new client sockets to the atServers

## 2.0.1

- fix: do not request clients to present an SSL cert as it is not required

## 2.0.0

- Added direct proxy resolution to atSign lookups and forward to Secondary
only after seeing `from:` verb
- Added configuration of proxy redirection and upstream from commandline
arguments
- Added Bind port option for containered proxy
- Added Docker and Docker Swarm configuration examples along with production
crontab examples to cycle service

## 1.0.1

- Added usage instructions to README - Configuration, Execution, Connecting
from an AtClient
- Copied in
[certs from the at_virtual_environment package](https://github.com/atsign-foundation/at_server/tree/trunk/at_virtual_environment/ve_base/contents/atsign/secondary/base/certs)
in the at_server repo

## 1.0.0

- Initial version.
