---
id: operations.runbook.debug-kubernetes-workload
title: Debug an unhealthy Kubernetes workload
description: Isolate scheduling, startup, runtime, Service, DNS, network-policy, and Istio failures without destroying the evidence needed to diagnose them.
type: Runbook
status: stable
domain: operations
tags: [runbook, kubernetes, istio, pods, services, networking]
sources:
  - id: pods
    resource: https://kubernetes.io/docs/tasks/debug/debug-application/debug-pods/
    title: Debug Pods
    author: team:kubernetes
  - id: running-pods
    resource: https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/
    title: Debug Running Pods
    author: team:kubernetes
  - id: services
    resource: https://kubernetes.io/docs/tasks/debug/debug-application/debug-service/
    title: Debug Services
    author: team:kubernetes
  - id: dns
    resource: https://kubernetes.io/docs/tasks/administer-cluster/dns-debugging-resolution/
    title: Debugging DNS resolution
    author: team:kubernetes
  - id: istio-ztunnel
    resource: https://istio.io/latest/docs/ambient/usage/troubleshoot-ztunnel/
    title: Troubleshoot connectivity issues with ztunnel
    author: team:istio
  - id: istio-waypoint
    resource: https://istio.io/latest/docs/ambient/usage/troubleshoot-waypoint/
    title: Troubleshoot issues with waypoints
    author: team:istio
---

# Debug an unhealthy Kubernetes workload

Use this runbook when a workload does not start, repeatedly restarts, fails
readiness, cannot be reached through a Service, or behaves differently after
joining an Istio mesh.

# Safety

- Confirm cluster, context, namespace, workload, and container before every
  command.
- Gather state, events, current logs, and previous-container logs before
  restarting or deleting anything.
- Do not edit a live managed Pod; change its controller or deployment source.
- Do not remove probes, resource limits, network policy, or mesh authorization
  as a permanent fix.
- Use ephemeral debug containers only under approved access and image policy.

# Establish scope

```bash
kubectl config current-context
kubectl -n <namespace> get deploy,sts,ds,pods,svc
kubectl -n <namespace> get events --sort-by=.metadata.creationTimestamp
```

Determine whether impact affects:

- one container, pod, node, version, or availability zone;
- every replica behind one Service;
- traffic only through the Service or ingress;
- only mesh-enrolled workloads; or
- multiple unrelated workloads, indicating a cluster or dependency issue.

# Check controller and rollout state

```bash
kubectl -n <namespace> describe deployment <deployment>
kubectl -n <namespace> rollout status deployment/<deployment>
kubectl -n <namespace> get rs -l <selector>
```

Confirm the desired image, replica counts, unavailable replicas, rollout
conditions, and owning ReplicaSet. A healthy old replica beside a failing new
replica is strong evidence for a release-specific failure, not proof of one.

# Check pod scheduling and startup

```bash
kubectl -n <namespace> get pod <pod> -o wide
kubectl -n <namespace> describe pod <pod>
kubectl -n <namespace> get pod <pod> -o yaml
```

Read conditions and events before logs.[^pods]

- **Pending:** inspect scheduling constraints, quota, volumes, image pull, node
  selectors, affinity, taints, and available resources.
- **Init failure:** inspect each init container in order.
- **CrashLoopBackOff:** inspect exit code, reason, current logs, and previous
  logs.
- **Running but not Ready:** inspect readiness gates, probe failures, sidecar
  readiness, and dependency startup assumptions.
- **Evicted or OOMKilled:** compare requests, limits, actual use, and node
  pressure before raising limits.

# Read logs without losing the previous failure

```bash
kubectl -n <namespace> logs <pod> -c <container> --since=30m
kubectl -n <namespace> logs <pod> -c <container> --previous
```

For multi-container pods, name the application, init, and proxy containers
explicitly. A sidecar's logs do not replace application logs.

# Verify the process and listener

If the image includes diagnostic tools:

```bash
kubectl -n <namespace> exec <pod> -c <container> -- <health-command>
```

For distroless or minimal images, use an approved ephemeral container instead
of rebuilding production images with a shell:

```bash
kubectl -n <namespace> debug -it <pod> --image=<approved-debug-image> --target=<container>
```

Verify the application listens on the expected address and port inside the pod.
A process listening only on loopback will not serve traffic through the pod IP.
Ephemeral containers share selected pod namespaces but do not recreate the
application's exact filesystem or security context.[^running-pods]

# Follow the Service path

```bash
kubectl -n <namespace> get service <service> -o yaml
kubectl -n <namespace> get endpointslice \
  -l kubernetes.io/service-name=<service> -o wide
kubectl -n <namespace> get pods -l <service-selector> --show-labels
```

Confirm:

- the Service selector matches intended ready pods;
- EndpointSlices contain those pod addresses;
- `port` and `targetPort` reach the actual listener; and
- readiness has not intentionally removed the pod from endpoints.[^services]

Test in order: application inside its pod, pod IP from another pod, Service
cluster IP, Service DNS name, ingress or gateway, then external DNS. The first
failing hop identifies the boundary to investigate.

# Check DNS and base networking

Resolve the fully qualified Service name from a pod in the affected namespace
and from another namespace. Cross-namespace callers need
`<service>.<namespace>` or the complete cluster domain.

If cluster DNS fails broadly, inspect CoreDNS pods, logs, Service, and
EndpointSlices before changing application configuration.[^dns]

Inspect namespace and workload `NetworkPolicy` in both directions. A policy can
allow DNS but deny the application port, or allow ingress while denying an
egress dependency.

# Add Istio only after Kubernetes fundamentals work

Determine the data-plane mode and enrollment:

- sidecar mode: application pod includes an Istio proxy container;
- ambient mode: namespace or workload uses ztunnel, optionally with a waypoint;
- unenrolled: traffic should follow base Kubernetes networking.

Start with:

```bash
istioctl analyze
istioctl proxy-status
```

For sidecars or waypoint proxies, inspect effective listeners, routes, clusters,
endpoints, and secrets with `istioctl proxy-config`. Compare the proxy's view of
the destination with the Kubernetes Service and EndpointSlices.

For ambient mode, use:

```bash
istioctl ztunnel-config workloads
istioctl ztunnel-config services
```

Confirm source and destination workloads are discovered, have expected
certificates, and use the intended waypoint.[^istio-ztunnel] If Layer 4 traffic
works but HTTP routing or authorization does not, verify the destination's
waypoint enrollment, Gateway labels, `targetRefs`, proxy status, access logs,
and effective Envoy configuration.[^istio-waypoint]

Do not assume a connectivity failure is mutual TLS. Distinguish:

- no route or endpoint;
- connection refused or timeout;
- TLS identity or certificate failure;
- Layer 4 authorization denial;
- Layer 7 authorization denial;
- route mismatch; and
- upstream application error.

# Check ingress from the inside out

If direct Service traffic works but external traffic fails, inspect the ingress
path described in
[Lock down ingress through an Istio gateway](/knowledge/architecture/istio-ingress-gateway.md).

```bash
kubectl -n <gateway-namespace> get gateway,httproute
kubectl -n <gateway-namespace> describe gateway <gateway>
kubectl -n <route-namespace> describe httproute <route>
kubectl -n <gateway-namespace> get pods,service
```

For Istio `Gateway` and `VirtualService` resources, inspect those resource types
instead. Confirm:

- the external load balancer reaches only intended gateway ports;
- listener and route status report accepted, programmed, and resolved
  references as applicable;
- the request's DNS name, SNI, `Host` header, listener hostname, and route
  hostname agree;
- the certificate secret exists in the required namespace and the gateway
  accepted it;
- ingress authorization allows the intended identity, path, and method;
- trusted-proxy configuration matches the actual proxy hops; and
- the selected backend Service has healthy EndpointSlices.

Test with an explicit hostname and TLS SNI rather than only the load balancer
address. Distinguish an unknown-host or no-route response from an upstream
connection failure. Check gateway access logs, response flags, effective route
configuration, and backend logs using the same request identifier.

# Mitigate

Choose the smallest reversible mitigation:

- roll back the failing workload version;
- correct selector, port, probe, or configuration through the deployment
  source;
- restore a dependency or credential;
- shift traffic away from an unhealthy subset;
- repair the specific NetworkPolicy or Istio policy attachment; or
- temporarily scale a healthy version while retaining failing evidence.

Avoid deleting all failing pods at once. A restart may hide the signal and
replace debuggable failures with identical new failures.

# Verify recovery

Verify:

- controller rollout and desired replicas are healthy;
- pods remain Ready across probe intervals;
- Service EndpointSlices contain the expected replicas;
- DNS and direct Service requests succeed from representative namespaces;
- allowed mesh traffic succeeds and denied traffic remains denied;
- latency and error rate recover without new saturation; and
- the next deployment or reschedule does not recreate the failure.

# Escalation

Escalate with:

- cluster, namespace, workload, pod, node, image, and rollout version;
- first failing hop in the request path;
- pod conditions, events, exit reason, and current and previous logs;
- Service, selector, ports, and EndpointSlice summary;
- relevant NetworkPolicy;
- Istio mode, enrollment, waypoint, proxy status, and policy attachment; and
- mitigations attempted and their measured effect.

[^pods]: Kubernetes guidance for triaging pod state and events.
[^running-pods]: Kubernetes guidance for exec, ephemeral containers, and advanced pod debugging.
[^services]: Kubernetes guidance for checking selectors, ports, and EndpointSlices.
[^dns]: Kubernetes guidance for testing Service DNS and CoreDNS.
[^istio-ztunnel]: Istio guidance for inspecting ambient workload discovery, certificates, and ztunnel traffic.
[^istio-waypoint]: Istio guidance for waypoint enrollment, status, logs, and Envoy configuration.
