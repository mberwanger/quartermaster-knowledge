---
id: skills.growth.write-a-record
title: Write a record
description: Capture a decision as a record that survives being read in a year, including the option that was rejected. Use when a choice has been made that somebody will otherwise relitigate.
type: skill
status: active
provenance: decided
skill:
  name: write-a-record
  allowed-tools: [Read, Grep, Glob, Write]
---

# Write a record

A record exists so the same argument is not had twice. It is written once and
superseded rather than edited, which is what makes it worth trusting: it says
what was believed at the time, not what is convenient now.

## Before writing

Establish that a decision was actually made. A record of a preference nobody
committed to is noise, and it will be cited later as though it were binding.

Find what it supersedes. If an earlier record covers the same ground, this one
names it in `supersedes` and the older one is left exactly as it is.

## The four sections

**Context.** What was true, and what problem that caused. Written so a reader who
was not there can follow it without asking anyone.

**Decision.** What was decided, in one or two sentences. Not the reasoning yet.

**Why.** The reasoning, and — this is the part that earns the document — **the
option that was rejected and what was wrong with it**. Everything else can be
reconstructed from the code. This cannot.

**Consequences.** What is now true, what becomes harder, and what this rules out.

## Rules

Write it in the past tense of a decision that has already happened. A record
phrased as a proposal will be read as one.

Do not edit a merged record to change what it says. Write a new one, set
`supersedes`, and let the old one stand. The wrong claim in an old record is
evidence about how the team thought; erasing it destroys the only reason to keep
records at all.

Keep it short. A record nobody finishes is a record nobody cites.
