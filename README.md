# quartermaster-knowledge

A worked example of a [Quartermaster](https://github.com/mberwanger/quartermaster)
knowledge store. It exists to be pulled into a real repository so you can see
what arrives, where it lands, and what changes when you select something
different.

The content is deliberately ordinary — commit messages, import grouping, how to
read a diff. The point is not the advice. The point is watching one bundle
produce different results in two repositories because they asked for different
things.

## What is in here

The repository root *is* the store. There is no `store/` directory, because
there is nothing else in this repository to keep separate from.

```
bundle.yaml          what is a document, what travels, what may become a rule
meta/
  frontmatter.schema.json   the schema this store holds itself to
  rulesets.yaml             named selections of documents
engineering/         conventions, skills, and agents
writing/             documentation conventions
records/             decisions, written once and superseded rather than edited
```

## Using it

```bash
qm init --source oci://ghcr.io/mberwanger/quartermaster-knowledge:latest \
        --ruleset go-service
```

That writes `.quartermaster.yaml`, materializes the rules your harness expects,
puts the knowledge tree on disk, and installs the hooks that keep it current.
`qm status` shows what you got and what it costs.

Pick a different ruleset and you get a different repository:

| Ruleset | For |
|---|---|
| `baseline` | Everything. One resident rule |
| `go-service` | A Go service. Adds an import convention scoped to `**/*.go` |
| `authoring` | A docs repository. Adds a writing convention scoped to `**/*.md` |

Skills and agents are opted into by name rather than by ruleset, because a skill
costs context in every session and an agent grants a capability:

```yaml
bundles:
  - source: oci://ghcr.io/mberwanger/quartermaster-knowledge:latest
    rulesets: [go-service]
    skills: [skills.review-a-diff]
    agents: [agents.doc-reviewer]
```

## The four ways a document reaches an agent

This is the thing worth understanding, and the store is arranged to show it.

**A rule** is pushed. It is in your context whether you asked or not, so it is
paid for in every session. A document becomes one by being named in a ruleset —
there is no rule type, and the same document can be a rule in one repository and
merely readable in another.

**A scoped rule** is pushed only when it is relevant. `engineering.go-imports`
declares `scope: ["**/*.go"]`, so it costs nothing until a Go file is open.

**A skill** is loaded on demand. Its description is resident so an agent knows it
exists; the body is read when the work matches. Skills are directories, and the
files beside `skill.md` travel with them.

**Knowledge** is on disk and read when needed. It costs no context at all. Most
of a store should be this.

## What does not travel

A document marked `visibility: restricted` is validated here and never enters a
bundle — not the catalog, not the tree, not even a directory listing.

That is a **propagation** control, not an access control. Anyone who can read
this repository can read it, and this repository is public. What it prevents is
content being copied onto every machine that runs `qm sync`. If something
genuinely needs protecting, it does not belong in a markdown file in git.

## Contributing

Every change is a pull request, and CI validates frontmatter, unique ids,
supersede links, and that the listings are current. Run `qm bundle index` and
commit the result if it changes anything.

A document written by an agent stays `status: draft` until a person merges it.
Draft documents still travel in the bundle and are still readable; they just
never become rules.

## Releasing

Tag it. `v*` builds the bundle and pushes it to
`ghcr.io/mberwanger/quartermaster-knowledge`, tagged with the version and with
`latest`.

The artifact is addressed by content digest, and the digest deliberately excludes
the commit, so two builds of identical content agree even from different commits.
Republishing unchanged content does not churn the registry.

**One-time setup:** GHCR packages are private when first pushed. After the first
publish, make the package public in its settings, or `qm init` will need
credentials to pull it.