---
id: architecture.web-and-analytics-platform
title: Web and analytics platform topology
description: Reference topology connecting browser traffic, application services, operational data, asynchronous processing, analytics, identity, and observability.
type: System Topology
status: stable
domain: architecture
tags: [architecture, topology, web, services, analytics, operations]
sources:
  - id: c4
    resource: https://c4model.com/diagrams/container
    title: C4 container diagram guidance
  - id: sre-monitoring
    resource: https://sre.google/sre-book/monitoring-distributed-systems/
    title: Monitoring distributed systems
    author: team:google-sre
---

# Web and analytics platform topology

This reference topology describes the boundaries common to a web product that
serves requests, changes operational state, emits events, and supports
analytical questions. A real system should replace each generic component with
its deployed name, owner, repository, and service objective.

# Topology

```text
users and external clients
          │
          ▼
edge: DNS · CDN · WAF · load balancing
          │
          ▼
web application
          │ authenticated application requests
          ▼
application API ───────────────► external providers
    │       │                         payments · messaging · identity
    │       │
    │       ├────────► cache
    │       │
    │       └────────► operational database
    │
    └───────────────► event transport
                             │
                             ▼
                     asynchronous workers
                             │
                             ▼
                    warehouse and models
                             │
                             ▼
                  dashboards · analysts · agents

identity, secrets, telemetry, and incident response cross every boundary
```

# Component responsibilities

## Edge

Terminates public traffic, applies coarse abuse controls, and routes requests.
It may cache public responses but must not become the only authorization layer.

## Web application

Renders user-facing routes and coordinates browser interaction. It may read
server-side data directly through an approved data-access boundary, but it does
not own shared business invariants merely because it renders them.

## Application API

Owns request validation, authorization, business operations, and durable side
effects. Synchronous requests should complete bounded work; long-running or
retryable work belongs on the event transport.

## Operational database and cache

The database is the source of truth for transactional state. The cache is an
optimization with explicit freshness and invalidation behavior, never an
independent authority.

## Event transport and workers

Events decouple committed operational changes from asynchronous effects.
Publish only after the authoritative state change can be identified. Consumers
must tolerate retries and duplicate delivery through idempotency or deduplication.

## Warehouse and semantic knowledge

The warehouse supports historical and cross-domain analysis. Structural
metadata explains available data; curated definitions explain what business
terms and metrics mean. Operational tables should not be queried as an
unmanaged substitute for an analytical model.

# Critical flows

## Interactive request

1. The edge accepts and routes a request.
2. The web application or API authenticates the caller.
3. The API authorizes the operation and validates input.
4. The database commits the state change.
5. The response reports the committed outcome.

Every hop needs a shared request or trace identifier.

## Asynchronous side effect

1. A committed state change produces an event with a stable event ID.
2. The transport delivers it at least once.
3. A worker performs an idempotent side effect.
4. Failed work retries with a limit and enters a visible dead-letter path.

## Analytical flow

1. Source changes arrive through an ingestion contract.
2. Transformations preserve lineage and enforce data-quality checks.
3. Models expose documented grain and dimensions.
4. Metric definitions bind business meaning to those models.
5. Consumers query bounded date ranges and approved definitions.

# Ownership and failure boundaries

Every deployed component should name:

- an owning team and escalation path;
- repository and deployment unit;
- upstream and downstream dependencies;
- service-level indicators and objectives;
- data classification and retention requirements; and
- rollback, replay, or recovery mechanism.

Monitor user-visible outcomes at boundaries rather than only internal health.
For request paths, start with latency, traffic, errors, and saturation.[^sre-monitoring]
For analytical paths, monitor freshness, completeness, validity, and
reconciliation against the source.

# Security boundaries

Authenticate identity at ingress and authorize again where protected data is
read or changed. Use short-lived workload identity between services where
possible. Secrets do not cross into browser bundles, logs, events, or analytical
exports.

Treat event payloads and warehouse tables as copies with their own access,
retention, and deletion obligations. A private operational field does not
become safe merely because it moved asynchronously.

# Change rules

Update the topology when a component, data authority, trust boundary, or
ownership boundary changes. Implementation details that do not alter a boundary
belong in component documentation rather than this system view.

[^sre-monitoring]: Google SRE guidance on monitoring distributed systems through user-relevant signals.
