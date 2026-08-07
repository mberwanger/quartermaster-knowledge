---
id: analytics.ga4.dataset
title: GA4 obfuscated sample ecommerce dataset
description: Public BigQuery export data from an obfuscated Google Analytics 4 ecommerce implementation, suitable for learning event and audience analysis.
type: BigQuery Dataset
status: stable
resource: https://bigquery.googleapis.com/bigquery/v2/projects/bigquery-public-data/datasets/ga4_obfuscated_sample_ecommerce
domain: analytics
tags: [bigquery, ga4, ecommerce, public-data, demo]
sources:
  - id: google-demo
    resource: https://developers.google.com/analytics/bigquery/web-ecommerce-demo-dataset
    title: Google Analytics 4 ecommerce demo dataset
    author: team:google-analytics
  - id: okf-demo
    resource: https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/toolbox/mdcode/demo/okf/catalog/datasets/ga4_obfuscated_sample_ecommerce.md
    title: Google Cloud OKF GA4 dataset example
    author: team:google-cloud
---

# GA4 obfuscated sample ecommerce dataset

`bigquery-public-data.ga4_obfuscated_sample_ecommerce` is a public, obfuscated
Google Analytics 4 export based on the Google Merchandise Store.[^google-demo]
It provides three months of event data for practicing GA4 analysis without
access to a proprietary Analytics property.

The dataset contains daily `events_YYYYMMDD` tables represented in this bundle
as the [GA4 events export](./events.md). Each row is one collected event, with
user, device, traffic-source, ecommerce, item, and event-parameter data.

# Appropriate use

Use this dataset to demonstrate:

- querying GA4's nested and repeated export schema;
- defining audiences from events and engagement parameters;
- bounding wildcard-table scans with `_TABLE_SUFFIX`; and
- combining sourced table metadata with curated metric definitions.

The obfuscation can make internal consistency imperfect. Treat results as
learning examples, not production benchmarks or financial records.

[^google-demo]: Google Analytics documentation for the public GA4 ecommerce demo dataset.
