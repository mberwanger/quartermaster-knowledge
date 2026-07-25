---
id: skills.review-a-diff
title: Review a diff
description: Read a change the way a reviewer would, in a fixed order, and report only what you can point at in the code. Use before opening a pull request, or when asked to review one.
type: skill
status: active
provenance: decided
skill:
  name: review-a-diff
  allowed-tools: [Read, Grep, Glob, Bash]
---

# Review a diff

Read the change in a fixed order. The order matters because the first thing you
look at anchors everything after it, and starting from the implementation makes
you review whether the code does what it does rather than whether it should.

## Order

1. **The commit message or PR description.** What was this meant to achieve?
2. **The tests.** What does the author believe the new behavior is? A change with
   no test is not automatically wrong, but it is a question worth asking.
3. **The interface.** Signatures, exported names, config keys. These are the
   expensive things to change later.
4. **The implementation**, last.

## What to report

Only what you can point at. A finding is a file, a line, and a concrete
consequence: given this input, this happens, and it is wrong because of that.

If you cannot construct the failing case, you have a preference rather than a
finding. Say so, or say nothing.

See [severity](references/severity.md) for what is worth blocking on.

## What not to do

Do not restate the diff. Do not comment on formatting a linter owns. Do not
approve: a person decides, and the job here is to make that decision better
informed than it would have been.
