---
id: engineering.go-best-practices
title: Go design keeps ownership and failure explicit
description: High-value Go practices for interfaces, errors, context, concurrency, and tests that keep behavior understandable as a service grows.
type: concept
status: stable
domain: engineering
tags: [go, design, testing, concurrency]
---

# Go design keeps ownership and failure explicit

Good Go code makes dependencies, failure, cancellation, and lifecycle ownership
visible. Prefer straightforward control flow and concrete types until an
abstraction has a demonstrated caller.

## Keep interfaces small and consumer-owned

Define an interface where it is consumed, not beside the implementation. Include
only the methods that consumer needs; one- and two-method interfaces are easy to
implement, test, and replace. Return concrete types from constructors unless
hiding the implementation is part of the API contract.

Accept interfaces to describe required behavior and return concrete values to
preserve available behavior. Do not create an interface solely to mock a type.

## Make errors part of the control flow

Handle errors where there is enough context to decide what they mean. Otherwise,
wrap them with a specific operation using `%w` and return them. Use
`errors.Is` and `errors.As` for decisions so wrapping does not break callers.

Reserve panic for violated process invariants, not expected input, network, or
storage failures. Log an error once at the boundary that owns the request; logging
and returning the same error produces duplicate, context-poor events.

## Propagate context without storing it

Pass `context.Context` as the first parameter of request-scoped operations. Carry
the caller's context through database, network, and blocking calls so deadlines
and cancellation stop the full operation. Do not replace it with
`context.Background()` in the middle of a call chain.

Do not store a context in a long-lived struct. Derive child contexts for bounded
work, call the returned cancel function, and use context values only for
request-scoped metadata rather than optional function parameters.

## Give concurrency one owner

The code that starts a goroutine owns its shutdown and must be able to explain
when it exits. Bound concurrency, propagate cancellation, and collect every
goroutine's error. An unbounded goroutine per item only moves backpressure into
memory and scheduling.

The sender owns closing a channel. Receivers should not close channels they did
not create, and channels should communicate ownership or coordination rather
than replace ordinary synchronous calls. Run race-sensitive tests with
`go test -race ./...`.

## Test behavior at stable boundaries

Write focused tests around observable behavior, including failure and
cancellation paths. Prefer small fakes that implement consumer-owned interfaces
over frameworks that duplicate implementation details.

Use table-driven tests when cases share setup and assertions; use separate tests
when naming the scenario makes the contract clearer. Keep integration tests for
boundaries such as SQL, HTTP, serialization, and filesystem behavior, where an
in-memory substitute can hide the failures that matter.
