---
id: engineering.nextjs-best-practices
title: Next.js keeps server work on the server
description: Durable App Router practices for component boundaries, data access, caching, mutations, errors, security, performance, and testing.
type: concept
status: stable
domain: engineering
tags: [nextjs, react, app-router, typescript, web]
sources:
  - id: components
    resource: https://nextjs.org/docs/app/getting-started/server-and-client-components
    title: Server and Client Components
    author: team:nextjs
  - id: fetching
    resource: https://nextjs.org/docs/app/getting-started/fetching-data
    title: Fetching data
    author: team:nextjs
  - id: caching
    resource: https://nextjs.org/docs/app/getting-started/caching
    title: Cache Components
    author: team:nextjs
  - id: actions
    resource: https://nextjs.org/docs/app/guides/server-actions
    title: Server Actions
    author: team:nextjs
  - id: errors
    resource: https://nextjs.org/docs/app/getting-started/error-handling
    title: Error handling
    author: team:nextjs
  - id: images
    resource: https://nextjs.org/docs/app/api-reference/components/image
    title: Image component
    author: team:nextjs
---

# Next.js keeps server work on the server

Use the App Router as a server-first architecture. Add browser JavaScript only
where interaction requires it, and make data freshness and mutation behavior
visible at the call site.

## Keep client boundaries narrow

Components are Server Components unless a file declares `"use client"`.
Fetch data, read secrets, and assemble mostly static UI on the server. Move only
interactive leaves—forms, browser APIs, event handlers, and stateful widgets—
behind a client boundary.[^components]

Do not mark an entire layout or page as a Client Component to support one
interactive child. Props crossing the boundary must be serializable, and
server-only modules must never be imported into client code.

## Fetch near the component that owns the data

Read data in Server Components or a server-only data-access module. Start
independent requests together instead of creating a sequential request
waterfall, and use `Suspense` or `loading.tsx` where streamed content improves
the experience.[^fetching]

Do not call an internal Route Handler from a Server Component merely to reach
the same application's database. That adds an HTTP hop without creating a real
boundary. Route Handlers are appropriate for external clients, webhooks, and
protocol-level endpoints.

## Make caching intentional

Do not assume a request is cached because it uses `fetch`, or dynamic because it
reads a database. Choose freshness according to the data's contract.

When Cache Components are enabled, place `"use cache"` at the smallest useful
function or component boundary and declare `cacheLife` in that same scope so
freshness is reviewable without tracing defaults.[^caching] Tag data when
mutations need targeted invalidation; avoid broad path invalidation when a
stable cache tag expresses the dependency.

Never cache authorization decisions, per-user secrets, or request-specific
state in a shared cache.

## Treat Server Actions as public mutation endpoints

Validate every input and perform authentication and authorization inside each
Server Action. A hidden button is not an authorization boundary. Keep actions
small: parse input, call domain logic, persist, and invalidate the affected
cache or path.[^actions]

Use `updateTag` when the action requires read-your-own-writes, `revalidateTag`
for stale-while-revalidate behavior, and `revalidatePath` when invalidation is
truly route-specific. Do not rely on multiple client-triggered Server Actions
running in parallel; coordinate parallel mutation work inside one server
operation.

## Design loading, empty, not-found, and error states

Use `loading.tsx` for route-level pending UI and local `Suspense` boundaries for
slower subsections. Return expected failures—validation, conflicts, and missing
permissions—as explicit results the UI can render. Throw unexpected failures so
the nearest `error.tsx` boundary can recover and observability can capture the
fault.[^errors]

Use `notFound()` and `not-found.tsx` for absent resources rather than rendering
a successful page with an error message.

## Keep secrets and privileged code server-only

Environment variables are server-only unless prefixed with `NEXT_PUBLIC_`;
public variables are embedded into the browser bundle at build time. Import
`server-only` from modules that access credentials or privileged backends so an
accidental client import fails during development.

Authorize access where data is read or changed. Redirects, navigation guards,
and middleware can improve user experience, but they do not replace checks in
the data-access and mutation boundaries.

## Use framework primitives before custom infrastructure

Use `next/link` for application navigation, `next/image` for responsive image
loading and sizing, and the Metadata API for route metadata. Configure remote
image hosts narrowly; do not allow arbitrary optimization targets.[^images]

Measure client bundle growth before adding a client-only library. Prefer server
rendering and platform APIs when they meet the requirement.

## Keep domain logic independent and test stable boundaries

Keep business rules in ordinary TypeScript modules rather than embedding them
inside pages, Route Handlers, or Server Actions. Unit test those modules without
booting Next.js. Add integration tests around data access, actions, and Route
Handlers, then cover critical navigation and mutation flows end to end.

Test both the rendered result and the security boundary: unauthenticated,
unauthorized, invalid, stale, and conflicting requests matter as much as the
successful path.

[^components]: Next.js guidance for composing Server and Client Components.
[^fetching]: Next.js guidance for server-side data fetching, parallel requests, and streaming.
[^caching]: Next.js Cache Components guidance for explicit cache scopes and lifetimes.
[^actions]: Next.js Server Actions guidance for mutations and revalidation.
[^errors]: Next.js guidance for expected errors, exceptions, and route error boundaries.
[^images]: Next.js Image component documentation and remote image configuration.
