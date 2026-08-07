---
id: growth.markdown
title: Documentation is written for someone deciding whether to keep reading
description: Lead with what the document establishes rather than what it covers. Short sentences, no filler headings, and code examples that run. Applies to any markdown in the repository.
type: concept
status: stable
scope: ["**/*.md"]
---

# Documentation is written for someone deciding whether to keep reading

Open with what the document establishes, not what area it is about. "Tokens are
exchanged at the STS, not the gateway" tells a reader whether to continue.
"Overview of the token exchange flow" does not.

## Rules that survive contact

**One idea per paragraph, and put it first.** The reader may stop after the first
sentence, so make that the one that matters.

**No heading that introduces the next heading.** An "Introduction" that says what
the following sections contain is a table of contents written in prose.

**Examples must run.** A snippet that was never executed is a claim, and it will
be wrong within two releases. Copy it from something that worked.

**Cut adjectives about the software.** "Robust", "seamless", and "powerful"
describe a feeling rather than a behavior, and a reader cannot check them.

## Length

Shorter than you think. A document that says one thing well is read; a document
that says nine things is skimmed and then not trusted, because the reader has no
way to know which of the nine were checked.
