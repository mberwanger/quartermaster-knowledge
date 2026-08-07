---
id: bigquery.table.bigquery-public-data.ga4_obfuscated_sample_ecommerce.events
title: GA4 events export
description: Daily sharded GA4 event export tables containing user interactions, event parameters, acquisition context, and ecommerce details.
type: BigQuery Table
status: stable
resource: https://bigquery.googleapis.com/bigquery/v2/projects/bigquery-public-data/datasets/ga4_obfuscated_sample_ecommerce/tables/events_*
domain: analytics
tags: [bigquery, ga4, events, audiences, sharded-tables, demo]
sources:
  - id: export-schema
    resource: https://support.google.com/analytics/answer/7029846
    title: BigQuery Export schema
    author: team:google-analytics
  - id: okf-demo
    resource: https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/toolbox/mdcode/demo/okf/catalog/tables/events_.md
    title: Google Cloud OKF GA4 events example
    author: team:google-cloud
---

# GA4 events export

The table family
`bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` contains one row
per collected GA4 event in daily tables named `events_YYYYMMDD`.[^export-schema]

# Fields used by this demo

| Field | BigQuery type | Meaning |
|---|---|---|
| `event_date` | `STRING` | Event date formatted as `YYYYMMDD` |
| `event_timestamp` | `INTEGER` | Event time in Unix microseconds |
| `event_name` | `STRING` | Collected event name |
| `event_params` | repeated `RECORD` | Event-specific key/value parameters |
| `event_params.key` | `STRING` | Parameter name |
| `event_params.value.int_value` | `INTEGER` | Integer parameter value |
| `user_id` | `STRING` | Signed-in user identifier when supplied |
| `user_pseudo_id` | `STRING` | Pseudonymous device or browser identifier |
| `ecommerce` | `RECORD` | Event-level ecommerce values |
| `items` | repeated `RECORD` | Item-level ecommerce values |

The complete export contains additional device, geography, acquisition, privacy,
user-property, and item fields. Consult the source schema before depending on a
field omitted here.

# Query safety

Always constrain `_TABLE_SUFFIX` when querying `events_*`. A date predicate on
`event_date` alone does not limit which wildcard tables BigQuery opens.

```sql
SELECT
  event_name,
  COUNT(*) AS event_count
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN @start_suffix AND @end_suffix
GROUP BY event_name
ORDER BY event_count DESC;
```

# Identity caveat

`user_id` is absent unless an implementation sends a signed-in identifier.
`user_pseudo_id` has broader coverage but represents a pseudonymous device or
browser, not necessarily a person. Every audience definition must state which
identity it counts.

[^export-schema]: Google Analytics Help documentation for the GA4 BigQuery export schema.
