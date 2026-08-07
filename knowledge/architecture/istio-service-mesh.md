---
id: architecture.istio-service-mesh
title: Istio adds a policy and telemetry layer to service traffic
description: Reference architecture for Istio control and data planes, sidecar and ambient modes, waypoints, identity, authorization, traffic policy, and ownership.
type: Architecture Guide
status: stable
domain: architecture
tags: [istio, kubernetes, service-mesh, envoy, networking, security]
sources:
  - id: architecture
    resource: https://istio.io/latest/docs/ops/deployment/architecture/
    title: Istio architecture
    author: team:istio
  - id: ambient
    resource: https://istio.io/latest/docs/ambient/architecture/
    title: Istio ambient architecture
    author: team:istio
  - id: waypoints
    resource: https://istio.io/latest/docs/ambient/usage/waypoint/
    title: Configure waypoint proxies
    author: team:istio
  - id: security
    resource: https://istio.io/latest/docs/concepts/security/
    title: Istio security
    author: team:istio
---

# Istio adds a policy and telemetry layer to service traffic

Istio observes and controls service traffic without becoming the source of truth
for application identity, authorization intent, or business correctness. It adds
a control plane and one of two data-plane shapes to Kubernetes networking.

```text
                         istiod control plane
                discovery · certificates · configuration
                           │             │
              ┌────────────┘             └────────────┐
              ▼                                       ▼
sidecar mode                                  ambient mode
Envoy beside each workload                    ztunnel on each node
L4 and L7 per workload                        L4 secure overlay
                                                      │
                                                      ▼
                                             optional waypoint
                                             destination L7 policy
```

North-south traffic enters through a separately deployed gateway rather than
ztunnel or an application sidecar. Use
[Lock down ingress through an Istio gateway](/knowledge/architecture/istio-ingress-gateway.md)
for the public exposure, TLS, route, and authorization boundary.

# Control plane

`istiod` translates Kubernetes, Gateway API, and Istio configuration into
workload identity, service discovery, traffic, and policy configuration. Data
planes continue forwarding with their last accepted configuration during a
short control-plane interruption, but they do not receive new endpoints,
certificates, or policy until communication recovers.[^architecture]

Control-plane health and data-plane configuration convergence are separate
signals. A healthy `istiod` does not prove that every proxy accepted the intended
configuration.

# Sidecar data plane

Sidecar mode places an Envoy proxy beside each enrolled workload. The proxy can
enforce Layer 4 and Layer 7 policy and emit HTTP-aware telemetry for traffic it
intercepts.

Sidecars couple proxy lifecycle and resource cost to application pods. Injection
state, startup ordering, proxy readiness, and per-pod configuration therefore
become part of workload operations.

# Ambient data plane

Ambient mode separates Layer 4 and Layer 7 processing:

- **ztunnel** runs per node and provides transparent Layer 4 connectivity,
  workload identity, mutual TLS, and Layer 4 authorization.
- **waypoint proxies** are optional destination-oriented Envoy deployments for
  HTTP routing, Layer 7 authorization, retries, timeouts, and HTTP
  observability.[^ambient]

Layer 7 policy attached to a waypoint is not enforced merely because ztunnel is
present. A service requiring header-, method-, or route-aware behavior must be
enrolled through the appropriate waypoint with compatible `targetRefs` or
Gateway API attachment.[^waypoints]

# Identity and authorization

Istio workload identity and mutual TLS authenticate the workloads on a
connection. Authentication answers who the peer is; `AuthorizationPolicy`
decides whether that identity may perform the requested operation.[^security]

Application authorization remains necessary for users, tenants, object
ownership, and business actions. Mesh policy should enforce coarse
service-to-service boundaries and provide defense in depth, not duplicate every
domain rule.

Start authorization changes in audit or narrowly scoped modes where possible.
Test both allowed and denied paths from representative source identities.

# Traffic policy

Define timeouts, retries, connection pools, circuit breaking, and outlier
detection according to the operation:

- retry only idempotent or explicitly deduplicated operations;
- keep retry budgets below the caller's total deadline;
- avoid retries at several layers amplifying one dependency failure;
- distinguish connection, request, and application timeouts; and
- test failover with realistic partial failures rather than only stopped pods.

Traffic shifting is not a deployment strategy by itself. The application still
needs compatible schemas, idempotent behavior, and an observable rollback path.

# Observability

Mesh telemetry explains transport and request behavior at the proxy boundary.
Application telemetry explains domain outcomes and internal work. Preserve
trace context across both.

Sidecar and waypoint proxies provide Layer 7 metrics when HTTP traffic is
recognized. Ambient traffic using ztunnel alone provides Layer 4 telemetry; do
not interpret missing HTTP dimensions as missing traffic.

Dashboards and objectives must identify their reporter and data-plane mode.
Changing from sidecars to ambient mode can change metric labels, scrape targets,
and trace shape even when user behavior is unchanged.

# Ownership boundaries

Platform owners are responsible for:

- control-plane and data-plane lifecycle;
- mesh-wide defaults and certificate health;
- policy validation and safe rollout mechanisms;
- proxy resource budgets; and
- mesh telemetry availability.

Service owners are responsible for:

- explicit enrollment and waypoint attachment;
- service-specific authorization and traffic policy;
- application deadlines, idempotency, and error handling; and
- verifying user-visible behavior after mesh changes.

# Debugging order

Do not begin with Envoy configuration when the pod is unscheduled or the Service
has no endpoints. Follow the
[Kubernetes workload debugging runbook](/knowledge/operations/runbooks/debug-kubernetes-workload.md):

1. workload and pod health;
2. direct application listener;
3. Service selector, ports, and EndpointSlices;
4. DNS and base cluster networking;
5. mesh enrollment and traffic interception;
6. proxy configuration and policy; and
7. external ingress or egress.

[^architecture]: Istio documentation for the control plane and sidecar-based data plane.
[^ambient]: Istio documentation for ztunnel and waypoint responsibilities in ambient mode.
[^waypoints]: Istio guidance for destination-oriented waypoint processing and Layer 7 features.
[^security]: Istio security concepts for workload identity, mutual TLS, and authorization.
