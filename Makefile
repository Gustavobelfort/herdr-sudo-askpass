# One entry point for humans, agents and CI. Each target only needs the tool
# it names; `nix develop` provides all of them.
SH := askpass.sh prompt.sh install-shim.sh test/test.sh

.PHONY: check test lint fmt fmt-check actions-lint

check: lint fmt-check test

test:
	bash test/test.sh

lint:
	shellcheck $(SH)

fmt:
	shfmt -i 2 -ci -w $(SH)

fmt-check:
	shfmt -i 2 -ci -d $(SH)

# Audits the GitHub workflows for injection, unpinned actions and excess
# permissions. Needs network for its online audits; CI runs it.
actions-lint:
	zizmor .github/workflows
