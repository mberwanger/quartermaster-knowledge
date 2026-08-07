# quartermaster-knowledge

A worked example of a [Quartermaster](https://github.com/mberwanger/quartermaster)
bundle source. Pull it into a repository to see what arrives, where it lands,
and how selecting a different package changes the capabilities and rules that
Quartermaster materializes.

The content is deliberately ordinary: commit messages, import grouping, and how
to read a diff. The example shows how one bundle can serve repositories with
different profiles without duplicating its source documents.

## Terms

**Bundle source** is the repository content Quartermaster validates and builds.
This repository root is the bundle source.

**Knowledge** is retrievable content written to disk for an agent to read when
needed. It is not loaded automatically.

**Rule** is a knowledge document a selected package pushes into an agent's
instructions. There is no rule document type; the same document can be a rule in
one repository and retrievable knowledge in another.

**Skill** and **Agent** are capabilities. A skill loads instructions on demand;
an agent delegates work with its declared tools and permissions.

**Package** is a named profile of rules, skills, and agents. Packages contain
selections, not prose, and are the stable names consumer repositories choose.

**Bundle** is the built, content-addressed artifact distributed from a bundle
source.

## Source layout

```text
bundle.yaml                  document boundaries and rule eligibility
meta/
  frontmatter.schema.json   document metadata schema
  packages.yaml             named package profiles
knowledge/
  <domain>/                 ordinary retrievable knowledge
capabilities/
  skills/<domain>/<skill>/  skill documents and their assets
  agents/                   agent documents
```

Document IDs are stable identities and do not depend on these paths.

## Using it

```bash
qm init --source oci://ghcr.io/mberwanger/quartermaster-knowledge:latest \
        --package go-service
```

That writes `.quartermaster.yaml`, materializes the selected package's rules and
capabilities, puts the knowledge tree on disk, and installs hooks that keep it
current. `qm status` shows what resolved and what is always loaded.

The generated manifest uses `use` to select package profiles:

```yaml
bundles:
  - source: oci://ghcr.io/mberwanger/quartermaster-knowledge:latest
    use: [go-service]
```

The available packages are `engineering`, `go-service`, `data-engineering`, and
`growth`. Their current memberships are defined in `meta/packages.yaml`.

## How content reaches an agent

**A resident rule** is pushed into every session, so it always consumes context.
A document becomes one when a selected package names it without a path scope.

**A scoped rule** is pushed only when relevant. `engineering.go-imports`
declares `scope: ["**/*.go"]`, so it loads when a Go file is in scope.

**A skill** is loaded on demand. Its description tells the agent when the
capability applies; the body and files beside `skill.md` load together.

**An agent** is installed as a delegation capability with its declared tools,
model, and permission mode.

**Knowledge** remains retrievable on disk and consumes no context until read.
Most documents in a bundle source should be knowledge.

## What does not travel

A document marked `visibility: restricted` is validated here and never enters a
bundle: not the catalog, the knowledge tree, or a directory listing.

That is a propagation control, not access control. Anyone who can read this
public repository can read the source. The setting prevents content from being
copied onto machines that run `qm sync`; secrets do not belong in markdown in
git.

## Contributing

CI validates frontmatter, unique IDs, supersede links, current generated
indexes, and the built bundle. Run `qm bundle index --root .` after moving or
adding documents.

Agent-authored documents stay `status: draft` until reviewed. Draft documents
remain retrievable in the bundle but cannot become rules under this source's
eligibility gate.

## Releasing

A `v*` tag builds the bundle and pushes it to
`ghcr.io/mberwanger/quartermaster-knowledge` with the version and `latest` tags.

The artifact is addressed by content digest. The digest excludes the commit, so
builds of identical content agree even when produced from different commits.

GHCR packages are private when first pushed. After the first publish, make the
registry package public or consumers need credentials to pull it.
