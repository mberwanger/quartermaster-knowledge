---
id: architecture.istio-ingress-gateway
title: Lock down ingress through an Istio gateway
description: Reference architecture for exposing selected services through Istio with restricted network reachability, TLS, route governance, authorization, trusted client identity, and auditable rollout.
type: Architecture Guide
status: stable
domain: architecture
tags: [istio, ingress, gateway-api, kubernetes, tls, authorization, security]
sources:
  - id: ingress
    resource: https://istio.io/latest/docs/tasks/traffic-management/ingress/ingress-control/
    title: Ingress gateways
    author: team:istio
  - id: secure-ingress
    resource: https://istio.io/latest/docs/tasks/traffic-management/ingress/secure-ingress/
    title: Secure gateways
    author: team:istio
  - id: gateway-api
    resource: https://istio.io/latest/docs/tasks/traffic-management/ingress/gateway-api/
    title: Kubernetes Gateway API
    author: team:istio
  - id: ingress-authorization
    resource: https://istio.io/latest/docs/tasks/security/authorization/authz-ingress/
    title: Ingress access control
    author: team:istio
  - id: network-topology
    resource: https://istio.io/latest/docs/ops/configuration/traffic-management/network-topologies/
    title: Configuring gateway network topology
    author: team:istio
---

# Lock down ingress through an Istio gateway

An ingress gateway should be the only public path to selected application
services. It terminates or passes through TLS, applies edge routing and policy,
and forwards traffic into the mesh. It does not make an application safe merely
by sitting in front of it.

```text
internet
   │
   ▼
optional CDN, WAF, or external load balancer
   │ only approved ports and trusted proxy path
   ▼
Istio ingress gateway
TLS · host allowlist · authentication · authorization · limits
   │ authenticated and encrypted mesh traffic
   ▼
ClusterIP Service
   │
   ▼
application workload
```

When Cloudflare is the edge proxy, use the controls in
[Proxy web traffic through Cloudflare without exposing the origin](/knowledge/architecture/cloudflare-reverse-proxy.md)
as the outer layer. The Istio gateway remains the origin ingress and must reject
traffic that bypasses the intended edge path.

# Minimize the exposed surface

- Expose only required listener ports. Prefer HTTPS on 443; keep HTTP only for a
  deliberate redirect or validation flow.
- Do not expose Envoy administration, metrics, readiness, or debugging ports to
  public networks.
- Keep application Services private, normally `ClusterIP`, unless another
  reviewed access path is required.
- Restrict cloud firewall, security-group, and load-balancer reachability to the
  approved edge or client networks when the platform preserves that boundary.
- Run gateways in a dedicated namespace and service account with narrowly
  scoped permissions.
- Separate gateways when applications have materially different trust,
  ownership, compliance, or availability boundaries.

A Kubernetes `LoadBalancer` Service can create public infrastructure even when
the Gateway configuration has no useful route. Treat network exposure and Istio
routing as separate controls.

# Terminate TLS deliberately

Use a certificate whose names exactly cover the published hosts. Store private
keys in the gateway's supported credential mechanism, limit who can read or
replace them, automate renewal, and alert before expiry.[^secure-ingress]

Choose the TLS mode according to the identity boundary:

- terminate ordinary public HTTPS at the gateway with server TLS;
- require client certificates for controlled machine-to-machine entry where a
  managed client PKI exists;
- use TLS passthrough only when the backend must terminate TLS and gateway-level
  HTTP routing and policy are intentionally unavailable.

External TLS and mesh TLS are separate connections. After terminating public
TLS, use Istio mutual TLS and authorization for the gateway-to-workload hop.
Redirecting HTTP to HTTPS does not protect requests that can reach an
unrestricted HTTP backend through another path.

# Constrain hosts and route attachment

Declare exact hostnames where practical. A wildcard listener expands the set of
names that can reach the gateway and requires equally careful certificate,
route, and ownership controls.

With Kubernetes Gateway API:

- restrict `allowedRoutes.namespaces` to the same namespace or an explicit
  namespace selector;
- require route hostnames to intersect the listener hostname;
- grant cross-namespace backend access explicitly; and
- keep Gateway ownership separate from application route ownership.

Do not use `from: All` as a convenience default. It allows any permitted
namespace to attempt attaching a route to the shared gateway. Istio also
supports its own `Gateway` and `VirtualService` APIs; choose one governance model
per ingress path and validate attachments during deployment.[^gateway-api]

# Default to denied application access

An open listener and a matching route are not sufficient authorization. Attach
Istio authorization to the ingress gateway or Gateway resource so only intended
hosts, paths, methods, source identities, or client networks are allowed.
Introducing an `ALLOW` policy causes requests that match no allow rule to be
denied; test that boundary explicitly.[^ingress-authorization]

Use stronger identity than source IP whenever possible:

- validated JWT claims for users and API clients;
- mutual TLS identities for managed machines;
- an external authorization provider for centralized policy where justified;
- application sessions and authorization for object- and tenant-level access.

IP allowlists are a coarse network control, not user authentication. They are
especially fragile for mobile clients, NAT, shared proxies, and changing
provider ranges.

# Trust client addresses only through a defined proxy chain

If a load balancer, CDN, or WAF precedes the Istio gateway, configure the exact
number of trusted proxies. Istio uses that topology to derive the trusted client
address from `X-Forwarded-For` and populate
`X-Envoy-External-Address`.[^network-topology]

Use:

- `remoteIpBlocks` when authorization relies on a trusted forwarded address or
  PROXY protocol; or
- `ipBlocks` when the original source address is preserved at the connection,
  such as a compatible `externalTrafficPolicy: Local` topology.

Do not accept a client-supplied forwarding header through an untrusted direct
path. Restrict direct gateway reachability to the proxies counted as trusted,
and test header behavior from both the approved path and a bypass attempt.

# Keep routing and resilience bounded

For each route, define:

- exact hosts, paths, and methods;
- request size and duration expectations;
- backend destination and port;
- timeout and idempotent retry behavior;
- failure response and observability; and
- rollback ownership.

Avoid broad catch-all routes to administrative or internal services. Do not
retry non-idempotent operations unless the application provides deduplication.
Rate limits and WAF rules at an outer edge reduce abuse; gateway and application
controls still enforce service- and tenant-specific limits.

# Restrict gateway-to-workload traffic

Use workload authorization and Kubernetes network policy as independent layers:

- permit the ingress gateway identity to call only intended workload ports;
- deny unrelated mesh identities from entering through protected internal
  interfaces;
- restrict gateway egress to routed backends and required infrastructure where
  the network implementation supports it; and
- keep application authorization active after the request crosses the gateway.

Avoid authorization based only on mutable headers. If an identity-aware proxy
adds identity headers, remove untrusted incoming values and accept the resulting
headers only from that authenticated proxy path.

# Observe both edge and application outcomes

Record:

- gateway request count, status, latency, host, route, and upstream;
- TLS handshake and certificate errors;
- authorization denials without sensitive credentials;
- trusted client address and request correlation identifier;
- gateway saturation, restarts, and configuration rejection; and
- application result and trace context.

An Envoy `503` can represent no healthy upstream, connection failure, reset, or
timeout. Correlate gateway response flags and upstream state with application
and Kubernetes evidence before assigning cause.

# Rollout and verification

1. Create the gateway without public DNS and verify configuration acceptance.
2. Install certificates and test host and SNI behavior.
3. Attach one explicit route to a non-sensitive backend.
4. Apply authentication and allow policies before publishing the endpoint.
5. Restrict route namespaces, gateway network reachability, and backend access.
6. Test allowed requests and deliberate failures: unknown host, plain HTTP,
   invalid token, disallowed path, spoofed forwarding header, and direct-origin
   access.
7. Shift a small traffic segment or low-risk hostname.
8. Monitor gateway, upstream, and application signals before full rollout.

Confirm that:

- only intended ports and hosts are reachable;
- TLS uses the expected certificate and client-authentication mode;
- unattached namespaces cannot publish routes;
- denied requests never reach the application;
- direct application and gateway-origin bypass paths are closed;
- gateway-to-workload traffic uses the intended mesh identity and encryption;
- forwarded client information is trustworthy; and
- rollback removes the route without exposing another access path.

[^secure-ingress]: Istio guidance for server TLS and mutual TLS at ingress gateways.
[^gateway-api]: Istio guidance for Kubernetes Gateway API listeners, routes, and generated gateways.
[^ingress-authorization]: Istio guidance for applying authorization and client-network controls at ingress.
[^network-topology]: Istio guidance for trusted proxies, forwarded addresses, and PROXY protocol.
