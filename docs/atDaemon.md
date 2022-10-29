# at_daemon

## What is at_daemon?

at_daemon is designed to be a local proxy that serves the at_client over
websockets which can be accessed by client-side rendered (CSR) web applications.

## Components

### at_daemon_cli

A cli server for at_daemon.

### at_daemon_desktop

A desktop version of the at_daemon server, designed for consumer use.

### at_daemon_core

The core functionality of the at_daemon server.

### at_daemon_client

A client that allows web applications to interact with the local
at_daemon server.

## Sequence Diagram

```mermaid
sequenceDiagram
	actor alice
	participant client
	participant daemon
	participant secondary
	participant web server
	note right of client: a client-side web app
	alice->>daemon: Onboard as @alice using at_onboarding_flutter
	daemon->secondary: Onboarding flow
	web server->>client: Load page with daemon onboarding
	alice->>client: Enter '@alice'
	client->>client: Generate New Symmetric Session Key
	client->>daemon: Request new daemon session for '@alice' (SYN)
	daemon->>alice: Prompt to start a session
	alice->>daemon: Accept session request
	note over client,daemon: Begin create session
	daemon->>client: [unique session id, daemon public key] (SYN-ACK)
	client->>daemon: [session id, client session key] encrypted with daemon public key (ACK)
	daemon->>daemon: decrypt client session key
	daemon->>client: ok
	note over client,daemon: End create session
	client->>daemon: verb
	daemon->>secondary: handle verb
	secondary->>daemon: verb result
	daemon->>client: verb result
```