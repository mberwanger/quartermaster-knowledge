---
id: skills.growth.draft-release-notes
title: Draft release notes
description: Turn a set of merged changes into notes a customer can act on, organized by what changed for them rather than by what was merged. Use when preparing a release.
type: skill
status: stable
skill:
  name: draft-release-notes
  allowed-tools: [Read, Grep, Glob, Bash]
---

# Draft release notes

Release notes are read by somebody deciding whether this release affects them.
Organize by what changed for them, not by what was merged.

## Gather

Read the commits since the last tag, and the pull requests behind them. The
commit subjects are the raw material; they are not the notes.

## Sort into three

**Changed for you.** New behavior, changed defaults, anything that alters what a
user sees. This section is the reason the document exists.

**You must act.** Breaking changes, removed options, migrations. Say what breaks,
and say what to do about it in the same sentence.

**Fixed.** Bugs somebody reported. One line each, describing the symptom rather
than the patch, because the symptom is what a reader will recognize.

Internal refactoring goes in none of them. If nothing a user can observe changed,
it does not belong in notes a user reads.

## Write

Lead each entry with the effect, not the mechanism. "Exports now include archived
records" beats "Fixed a filter in the export path."

State the version something changed in. Somebody two releases behind is the main
audience for a release note.
