SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

MAKEFLAGS += --no-print-directory

SVU_VERSION := v3.2.3
SVU := go run github.com/caarlos0/svu/v3@$(SVU_VERSION)

.PHONY: help # Print this help message.
help:
	@grep -E '^\.PHONY: [a-zA-Z0-9_-]+ .*?# .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = "(: |#)"}; {printf "%-30s %s\n", $$2, $$3}'

.PHONY: release # Tag and push the next version inferred from commits.
release:
	@CURRENT_VERSION=$$($(SVU) current) && \
	VERSION=$$($(SVU) next) && \
	echo "Current version: $$CURRENT_VERSION" && \
	echo "Next version:    $$VERSION" && \
	echo "" && \
	read -p "Proceed? [y/N] " confirm && [ "$$confirm" = "y" ] && \
	git tag -a "$$VERSION" -m "Release $$VERSION" && \
	git push origin "$$VERSION"

.PHONY: release-patch # Tag and push a patch release.
release-patch:
	@$(MAKE) release-version RELEASE_KIND=patch

.PHONY: release-minor # Tag and push a minor release.
release-minor:
	@$(MAKE) release-version RELEASE_KIND=minor

.PHONY: release-major # Tag and push a major release.
release-major:
	@$(MAKE) release-version RELEASE_KIND=major

.PHONY: release-version
release-version:
	@CURRENT_VERSION=$$($(SVU) current) && \
	VERSION=$$($(SVU) $(RELEASE_KIND)) && \
	echo "Current version: $$CURRENT_VERSION" && \
	echo "Next version:    $$VERSION" && \
	git tag -a "$$VERSION" -m "Release $$VERSION" && \
	git push origin "$$VERSION"

.PHONY: version # Show the current and next inferred version.
version:
	@CURRENT_VERSION=$$($(SVU) current) && \
	NEXT_VERSION=$$($(SVU) next) && \
	echo "Current: $$CURRENT_VERSION" && \
	echo "Next:    $$NEXT_VERSION"
