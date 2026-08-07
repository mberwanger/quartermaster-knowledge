---
id: engineering.commit-messages
title: Commit messages say why
description: A commit message explains why the change was made, because the diff already shows what changed. The subject is a sentence, the body is the reasoning, and the rejected alternative belongs there too.
type: concept
status: active
provenance: decided
---

# Commit messages say why

The diff already shows what changed. A message that restates it adds nothing and
costs a reader the time it takes to work that out.

Write the reason. What was true before, what problem that caused, and why this
change rather than the other one you considered. The rejected alternative is the
part nobody can reconstruct later, and it is the part that stops the same
argument being had again in six months.

## Shape

A subject line that reads as a sentence, lowercase after the type prefix, no
trailing period. Under seventy characters.

```
fix(api): stop retrying a request the server already rejected
```

Then a blank line, then prose. Paragraphs, not bullets: a list of changes is the
diff again. If the change is genuinely trivial, the subject alone is enough and
padding it out is worse than leaving it.

## What not to do

Do not write "various fixes", "cleanup", or "address feedback". Six months later
those are indistinguishable from an empty message, and the person reading them is
usually you.

Do not describe the process. "Ran the linter, fixed the errors it found" is what
you did; the message should say what is now true that was not before.
