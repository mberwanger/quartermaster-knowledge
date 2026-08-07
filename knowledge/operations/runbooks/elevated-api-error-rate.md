---
id: operations.runbook.elevated-api-error-rate
title: Respond to an elevated API error rate
description: Stabilize and diagnose a user-facing API when failures rise above its service objective across routes, regions, versions, or dependencies.
type: Runbook
status: stable
domain: operations
tags: [runbook, api, incidents, reliability, observability]
sources:
  - id: topology
    resource: /knowledge/architecture/web-and-analytics-platform.md
    title: Web and analytics platform topology
  - id: incident-response
    resource: https://sre.google/workbook/incident-response/
    title: Incident response
    author: team:google-sre
---

# Respond to an elevated API error rate

Use this runbook when the user-visible API error ratio breaches its objective or
is rising fast enough to exhaust the error budget.

# Safety

- Stabilize users before searching for a perfect root cause.
- Assign one incident lead and one communication owner.
- Do not restart every instance simultaneously.
- Do not disable authentication, authorization, validation, or audit controls
  to reduce errors.
- Preserve timestamps, deployment versions, traces, logs, and mitigation
  actions for later analysis.

# Confirm and scope

Confirm the alert against a second signal, then establish:

- affected routes and operations;
- status codes or failure classes;
- regions, tenants, devices, or traffic segments;
- first observed time and rate of change;
- current and previous deployment versions;
- latency and saturation alongside the error rate; and
- whether synthetic checks and real-user outcomes agree.

Declare an incident when impact is material or ownership is unclear. Keep a
timestamped action log from the first mitigation.[^incident-response]

# Identify the failing boundary

Follow a representative failed request through the
[system topology](/knowledge/architecture/web-and-analytics-platform.md):

1. edge routing and rejection;
2. web or API process;
3. operational database or cache;
4. downstream service or external provider; and
5. asynchronous work incorrectly blocking the synchronous path.

Compare successful and failed traces. Determine whether failure is local to one
route, instance, region, dependency, or release.

# Check recent change and capacity

Correlate the start of impact with:

- application or configuration deployment;
- feature-flag or routing change;
- schema or data migration;
- certificate, secret, or credential rotation;
- dependency incident;
- traffic increase; and
- exhaustion of connections, threads, memory, CPU, queue depth, or rate limits.

Correlation is evidence for a mitigation, not proof of root cause.

# Mitigate

Choose the smallest reversible action that reduces user impact:

- roll back or disable the implicated change;
- shift traffic away from an unhealthy region or version;
- shed optional work while preserving core operations;
- reduce concurrency when a dependency is saturated;
- restore a known-good credential or configuration through the normal secret
  path; or
- apply a documented dependency fallback.

Change one major variable at a time when impact allows. Record who approved the
action, when it began, and the metric expected to improve.

# Verify recovery

Do not close the incident when the graph first turns downward. Verify:

- error rate and latency remain within objective for a representative window;
- all routes, regions, and important customer segments recovered;
- saturation and queue depth are draining rather than accumulating elsewhere;
- synthetic and real-user signals agree; and
- the mitigation did not disable a security or correctness control.

# Follow-up

Capture the causal chain, detection gap, user impact, and why the mitigation
worked. Assign corrective work for prevention, faster detection, safer rollback,
and any temporary mitigation still active.

# Escalation

Escalate with:

- incident start and current impact;
- affected routes, regions, and versions;
- error classes and representative trace IDs;
- recent changes and dependency status;
- capacity signals;
- mitigations attempted and their measured effect; and
- the decision or access needed from the receiving owner.

[^incident-response]: Google SRE guidance on clear command, communication, and operational control during incidents.
