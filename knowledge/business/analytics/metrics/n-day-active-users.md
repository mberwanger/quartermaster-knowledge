---
id: business.analytics.metric.n-day-active-users
title: N-day active users
description: Count pseudonymous users with at least one event whose engagement_time_msec parameter is greater than zero during the N-day reporting window.
type: Metric Definition
status: stable
domain: analytics
tags: [ga4, audience, active-users, metric, demo]
sources:
  - id: events
    resource: /knowledge/data/bigquery/ga4-obfuscated-sample-ecommerce/events.md
    title: GA4 events export
  - id: google-query
    resource: https://support.google.com/analytics/answer/9037342
    title: Sample queries for audiences based on BigQuery data
    author: team:google-analytics
  - id: okf-demo
    resource: https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/toolbox/mdcode/demo/okf/catalog/references/metrics/n_day_active_users.md
    title: Google Cloud OKF N-day active users example
    author: team:google-cloud
---

# Definition

**N-day active users** counts distinct `user_pseudo_id` values with at least one
event whose `engagement_time_msec` parameter is greater than zero during the N
days before an exclusive reporting end date.[^google-query]

# Grain and identity

The input grain is one GA4 event. The output is one audience count for the
requested window.

This demo counts `user_pseudo_id`, so it measures active pseudonymous devices or
browsers rather than authenticated people. A production definition that counts
customers should specify an approved identity-resolution policy.

# BigQuery SQL

`@end_date` is exclusive and `@active_days` must be positive:

```sql
SELECT
  COUNT(DISTINCT user_pseudo_id) AS n_day_active_users
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN
    FORMAT_DATE('%Y%m%d', DATE_SUB(@end_date, INTERVAL @active_days DAY))
    AND FORMAT_DATE('%Y%m%d', DATE_SUB(@end_date, INTERVAL 1 DAY))
  AND user_pseudo_id IS NOT NULL
  AND EXISTS (
    SELECT 1
    FROM UNNEST(event_params) AS event_parameter
    WHERE event_parameter.key = 'engagement_time_msec'
      AND event_parameter.value.int_value > 0
  );
```

# Caveats

- Changing N changes the metric and must be visible with the result.
- Obfuscation can affect continuity of identifiers in the public sample.
- This is an audience definition, not GA4's complete reporting-interface
  definition of the Active users metric.

[^google-query]: Google Analytics' audience-query example defines activity from a positive `engagement_time_msec` event parameter.
