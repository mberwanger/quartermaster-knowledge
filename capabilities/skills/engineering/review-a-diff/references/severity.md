# Severity

Not everything found is worth saying, and saying everything is how a review gets
ignored.

**Blocking.** The change is incorrect, loses data, breaks an interface somebody
depends on, or introduces a security hole. State the failing case.

**Worth fixing now.** Correct but will be expensive to change later: a leaking
abstraction, a name that will be wrong in a month, a missing test on the branch
most likely to break.

**Mention once.** Style not covered by a linter, a simpler alternative, a
question about intent. Say it once and drop it if the author disagrees.

**Do not say.** Anything a formatter owns. Anything you would not have raised if
somebody else had written it. Anything you cannot point at.
