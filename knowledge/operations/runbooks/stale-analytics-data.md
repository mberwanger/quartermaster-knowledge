---
id: operations.runbook.stale-analytics-data
title: Recover stale analytical data
description: Diagnose and safely recover an analytical dataset or metric that has missed its freshness objective without duplicating or silently losing data.
type: Runbook
status: stable
domain: operations
tags: [runbook, analytics, data-quality, freshness, pipelines]
sources:
  - id: topology
    resource: /knowledge/architecture/web-and-analytics-platform.md
    title: Web and analytics platform topology
---

# Recover stale analytical data

Use this runbook when a dataset, model, dashboard, or metric has not advanced by
its expected freshness deadline.

# Safety

- Mark affected outputs stale before consumers make decisions from them.
- Do not report a successful job as proof of complete data.
- Do not rerun a non-idempotent load until its write and deduplication behavior
  is understood.
- Do not delete partial output before preserving evidence and identifying a
  safe replay point.
- Keep business definitions fixed during recovery; changing a metric is not a
  freshness repair.

# Confirm impact

Establish:

- last complete source interval;
- last complete published interval;
- expected freshness objective and current delay;
- affected tables, models, metrics, dashboards, and downstream exports;
- whether data is missing, partial, duplicated, invalid, or merely delayed; and
- decisions or automated processes currently consuming the output.

Communicate the last known complete interval, not just “the pipeline is delayed.”

# Locate the stale boundary

Walk the analytical flow from source to consumer:

1. source system produced the expected records;
2. extraction or event delivery received them;
3. raw landing data is complete;
4. transformations ran against the intended interval;
5. quality and reconciliation checks passed;
6. semantic models or metrics refreshed; and
7. caches, dashboards, and exports observed the new version.

Compare freshness at every boundary. The first boundary that did not advance is
the likely recovery point; downstream failures are usually consequences.

# Diagnose common causes

Check for:

- source outage or changed source schema;
- expired credentials or denied permissions;
- scheduler, orchestration, or worker failure;
- late or out-of-order events beyond the accepted watermark;
- partition, timezone, or date-boundary mistakes;
- partial writes reported as successful;
- duplicate delivery without idempotent processing;
- failed data-quality or reconciliation checks;
- semantic model failure after raw data succeeded; and
- stale dashboard or query cache after the warehouse recovered.

# Plan the replay

Before backfilling, define:

- exact source interval and target partitions;
- idempotency or deduplication key;
- whether existing partial output is replaced, merged, or quarantined;
- expected record counts or control totals;
- downstream models that must be rebuilt in dependency order; and
- how consumers remain protected from partial results.

Use the smallest interval that restores correctness. A full-history rebuild
creates more risk and delays verification unless the failure invalidated history.

# Recover

1. Stop or isolate the failing scheduled path if it can race the repair.
2. Restore the source, credential, schema contract, or processing capacity.
3. Replay the bounded interval into an isolated or idempotent target.
4. Run completeness, uniqueness, validity, and reconciliation checks.
5. Rebuild downstream models in dependency order.
6. Refresh caches and exports only after authoritative checks pass.
7. Resume scheduling and observe the next normal interval.

# Verify recovery

Recovery requires:

- source and published watermarks at the expected interval;
- no unexplained gaps or duplicates;
- control totals reconciled within documented tolerance;
- critical metrics calculated from the repaired partitions;
- downstream dashboards and exports showing the same data version; and
- the next scheduled run succeeding without manual intervention.

# Follow-up

Record the stale interval, affected decisions, detection delay, and repair. Add
or improve freshness, volume, schema, lineage, and reconciliation checks at the
boundary where the failure first became observable.

# Escalation

Escalate with:

- dataset, model, and metric identifiers;
- expected and actual freshness;
- last complete and first incomplete intervals;
- first stale boundary in the data flow;
- source and target control totals;
- replay plan and idempotency strategy;
- affected consumers; and
- access or decision required from the receiving owner.
