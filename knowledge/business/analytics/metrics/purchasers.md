---
id: business.analytics.metric.purchasers
title: Purchasers
description: Count pseudonymous users who emitted at least one purchase or in_app_purchase event during the reporting window.
type: Metric Definition
status: stable
domain: analytics
tags: [ga4, audience, purchasers, metric, demo]
sources:
  - id: events
    resource: /knowledge/data/bigquery/ga4-obfuscated-sample-ecommerce/events.md
    title: GA4 events export
  - id: google-query
    resource: https://support.google.com/analytics/answer/9037342
    title: Sample queries for audiences based on BigQuery data
    author: team:google-analytics
  - id: okf-demo
    resource: https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/toolbox/mdcode/demo/okf/catalog/references/metrics/purchasers.md
    title: Google Cloud OKF purchasers example
    author: team:google-cloud
---

# Definition

**Purchasers** counts distinct `user_pseudo_id` values that emitted at least one
`purchase` or `in_app_purchase` event during the reporting window.[^google-query]

# Grain and identity

The input grain is one GA4 event. The output is one audience count for the
requested date range. Multiple purchase events from the same
`user_pseudo_id` count once.

This demo uses pseudonymous identity. It does not merge devices or guarantee
that a browser identifier represents exactly one person.

# BigQuery SQL

The suffix parameters are inclusive and use `YYYYMMDD`:

```sql
SELECT
  COUNT(DISTINCT user_pseudo_id) AS purchasers
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN @start_suffix AND @end_suffix
  AND event_name IN ('purchase', 'in_app_purchase')
  AND user_pseudo_id IS NOT NULL;
```

# Caveats

- This is an event-based audience, not recognized revenue.
- Duplicate events do not change the audience count but can affect transaction
  metrics derived from the same source.
- Obfuscation can affect identity continuity in the public sample.

[^google-query]: Google Analytics' audience-query example defines purchasers from `purchase` and `in_app_purchase` events.
