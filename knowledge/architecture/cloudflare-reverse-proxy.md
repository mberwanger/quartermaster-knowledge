---
id: architecture.cloudflare-reverse-proxy
title: Proxy web traffic through Cloudflare without exposing the origin
description: Reference architecture and rollout for placing Cloudflare in front of a web origin with strict TLS, trusted forwarding headers, origin restrictions, caching, and observability.
type: Architecture Guide
status: stable
domain: architecture
tags: [cloudflare, reverse-proxy, dns, tls, waf, cdn, security]
sources:
  - id: proxy-status
    resource: https://developers.cloudflare.com/dns/proxy-status/
    title: Cloudflare DNS proxy status
    author: team:cloudflare
  - id: strict-tls
    resource: https://developers.cloudflare.com/ssl/origin-configuration/ssl-modes/full-strict/
    title: Full strict SSL/TLS mode
    author: team:cloudflare
  - id: origin-security
    resource: https://developers.cloudflare.com/fundamentals/security/protect-your-origin-server/
    title: Protect your origin server
    author: team:cloudflare
  - id: visitor-ip
    resource: https://developers.cloudflare.com/support/troubleshooting/restoring-visitor-ips/restoring-original-visitor-ips/
    title: Restore original visitor IPs
    author: team:cloudflare
  - id: rate-limits
    resource: https://developers.cloudflare.com/waf/rate-limiting-rules/
    title: Cloudflare rate limiting rules
    author: team:cloudflare
---

# Proxy web traffic through Cloudflare without exposing the origin

Cloudflare's proxied DNS records place its network between visitors and the
origin. Cloudflare terminates the visitor connection, applies edge controls, and
opens a separate connection to the origin.[^proxy-status]

```text
visitor
  │ HTTPS
  ▼
Cloudflare edge
  DNS proxy · TLS · DDoS · WAF · rate limits · cache
  │ HTTPS with origin certificate validation
  ▼
origin ingress
  trusted proxy parsing · application routing
  │
  ▼
web application
```

This is the edge portion of the
[web and analytics topology](/knowledge/architecture/web-and-analytics-platform.md).

# Proxy only web records

Enable the Cloudflare proxy—the orange-cloud state—for `A`, `AAAA`, or `CNAME`
records serving HTTP or HTTPS. A proxied lookup returns Cloudflare addresses;
DNS-only records expose the configured origin and bypass Cloudflare's HTTP
security, caching, and analytics.[^proxy-status]

Keep non-HTTP records such as mail routing and domain-verification records
DNS-only. Confirm whether a third-party webhook, certificate check, or SaaS
provider requires direct address visibility before proxying its hostname.

# Encrypt and authenticate the origin connection

Use **Full (strict)** TLS. The origin must listen on HTTPS and present an
unexpired certificate whose name matches the origin hostname, issued by a public
CA or Cloudflare Origin CA.[^strict-tls]

Do not use Flexible mode for an HTTPS application. It leaves the Cloudflare-to-
origin leg unencrypted and commonly creates redirect loops when the application
forces HTTPS.

For stronger origin authentication, use Authenticated Origin Pulls or another
mutual-authentication mechanism in addition to network allowlisting. TLS
encryption alone does not prove that every request reaching a public origin
came through the intended Cloudflare zone.

# Prevent direct-origin bypass

Once proxied traffic is healthy:

1. allow inbound web traffic from Cloudflare's published address ranges or
   dedicated egress addresses;
2. allow explicit health-check, administration, or partner paths separately;
3. block other public traffic to the origin;
4. audit DNS-only records that reveal the origin address; and
5. rotate an origin address that was previously public when practical.

Cloudflare recommends proxying web records and restricting the origin so an
attacker cannot bypass edge controls by using a historical or leaked
address.[^origin-security]

Keep allowlists synchronized with Cloudflare's published ranges. Accidentally
blocking those ranges blocks every proxied visitor.

# Trust forwarding headers only from the proxy

The origin network sees Cloudflare addresses rather than visitor addresses.
Cloudflare supplies the visitor address in `CF-Connecting-IP` and extends
`X-Forwarded-For`.[^visitor-ip]

Configure the origin framework or load balancer to trust those headers only when
the direct peer is an approved Cloudflare address or authenticated origin
connection. A publicly reachable client can spoof forwarding headers if the
origin trusts them without validating the proxy hop.

Use:

- the restored visitor address for security logs and carefully designed abuse
  controls;
- `CF-Ray` to correlate an origin request with Cloudflare logs; and
- the forwarded scheme and host when constructing redirects and absolute URLs.

Do not use source IP as the sole user identity or authorization decision. NAT,
privacy relays, mobile networks, and IPv6 rotation make it an unstable identity.

# Separate edge controls from application controls

Use Cloudflare WAF and rate-limiting rules to reduce abusive traffic before it
reaches the origin. Choose counting characteristics deliberately; IP-based
limits can penalize many users behind the same NAT, and edge enforcement can
allow a small excess during propagation.[^rate-limits]

Keep authentication, authorization, input validation, idempotency, and
business-specific quotas in the application. Edge controls reduce load and
attack surface; they do not replace correctness or tenant isolation.

# Cache only responses with an explicit contract

Cache immutable static assets aggressively with content-hashed names. For HTML,
API responses, and server-rendered output, define:

- whether the response is public, private, or uncacheable;
- which path, query, cookie, and header values change the representation;
- freshness and stale-serving behavior;
- targeted purge or versioning strategy; and
- whether the origin and Cloudflare can cache the same response safely.

Do not cache authenticated or personalized responses with a shared cache key.
Avoid “cache everything” rules until cookies, authorization headers, and error
responses have explicit exclusions.

# Rollout

1. Inventory hostnames, origin addresses, certificates, redirects, ports,
   webhooks, and health checks.
2. Install and verify the origin certificate.
3. Set Full (strict) TLS before enforcing origin-only Cloudflare traffic.
4. Configure trusted proxy ranges and visitor-IP logging.
5. Enable proxying for one low-risk hostname or traffic segment.
6. Verify redirects, cookies, uploads, streaming, WebSockets, cache headers,
   visitor IPs, and external callbacks.
7. Apply WAF and rate limits in observe or low-impact modes before blocking.
8. Restrict direct-origin access only after proxied health is proven.
9. Monitor edge status codes, origin status codes, cache status, latency,
   request volume, and saturation through the rollout.

# Verification

Confirm:

- public DNS returns Cloudflare rather than origin addresses;
- visitor-to-edge and edge-to-origin TLS both validate;
- direct origin requests are rejected except for documented exceptions;
- logs contain a trustworthy visitor address and Cloudflare request identifier;
- dynamic and authenticated responses are not shared incorrectly;
- cache hits and misses match policy;
- WAF and rate limits do not block expected traffic; and
- the origin can distinguish application failures from Cloudflare `52x` errors.

# Rollback

Prefer reverting the specific WAF, cache, redirect, or origin restriction that
caused impact while keeping the proxy in place. Switching a record to DNS-only
exposes the origin, removes edge protection, and depends on DNS propagation; use
it only when the origin is intentionally safe for direct public traffic.

After rollback, verify both visitor reachability and origin exposure. Preserve
the Cloudflare rule change, certificate state, DNS state, and request IDs needed
for follow-up.

[^proxy-status]: Cloudflare documentation describing proxied and DNS-only records.
[^strict-tls]: Cloudflare requirements for certificate-validated Full (strict) origin TLS.
[^origin-security]: Cloudflare guidance for restricting and protecting a public origin.
[^visitor-ip]: Cloudflare guidance for restoring original visitor addresses at an origin.
[^rate-limits]: Cloudflare documentation on rate-limiting behavior and plan-dependent controls.
