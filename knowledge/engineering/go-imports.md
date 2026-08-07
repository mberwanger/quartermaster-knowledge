---
id: engineering.go-imports
title: Go imports group in three blocks
description: Standard library, third party, then our own modules, separated by blank lines and enforced by gci rather than by review. Configured once per repository in .golangci.yml.
type: concept
status: stable
scope: ["**/*.go"]
---

# Go imports group in three blocks

Standard library first, third-party second, our own modules last, each block
separated by a blank line.

```go
import (
	"context"
	"fmt"

	"go.uber.org/zap"
	"google.golang.org/grpc"

	"github.com/example/service/internal/config"
)
```

## Why it is worth configuring

The grouping is not the point. Having a formatter decide it is the point,
because import order is the kind of thing that generates review comments
forever, produces diff noise when two people disagree, and is never worth a
conversation.

## How

`gci` in `.golangci.yml`, with the last section naming your module prefixes:

```yaml
formatters:
  enable:
    - gci
  settings:
    gci:
      sections:
        - standard
        - default
        - prefix(github.com/example)
```

Run `golangci-lint fmt ./...` and it rewrites the blocks. Add every prefix your
organization publishes under, not only the main one, or modules from the same
team land in the third-party block and look external.

## Scope

This document declares `scope: ["**/*.go"]`, so it loads only when Go files are
open. That is the difference between a rule that costs context in every session
and one that costs nothing until it is relevant.
