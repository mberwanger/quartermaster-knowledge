---
id: skills.data.query-a-warehouse
title: Query a warehouse safely
description: Explore an unfamiliar warehouse without running something that scans a petabyte. Use before writing a query against a table you have not queried before.
type: skill
status: stable
skill:
  name: query-a-warehouse
  allowed-tools: [Read, Grep, Bash]
---

# Query a warehouse safely

The cost of a query is decided before you run it, and an exploratory `SELECT *`
against a partitioned table is the most expensive thing most people do by
accident.

## Order

1. **Find the partition key.** Every large table has one. A query that does not
   filter on it reads everything.
2. **Check the table size** before the first real query, not after.
3. **Sample first.** `LIMIT` does not reduce what is scanned; a partition filter
   does.
4. **Then write the query.**

## Rules

Always filter on the partition column, even when exploring, even when it makes
the result less interesting. An unfiltered exploratory query is the one that
shows up on the bill.

Prefer a `WHERE` on the partition to a `LIMIT` on the result. The first reduces
what is read; the second only reduces what is returned.

Never `SELECT *` on a wide columnar table. Columnar storage means the columns you
name are the columns you pay for.

If a query has been running for more than a minute and you did not expect it to,
cancel it. It is not about to finish.
