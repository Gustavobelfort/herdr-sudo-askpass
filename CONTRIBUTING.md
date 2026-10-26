# Contributing

Issues and pull requests are welcome. Before opening a PR:

1. `nix develop` (or install shellcheck, shfmt and make yourself).
2. `make check` passes.
3. Behaviour changes come with a case in `test/test.sh`.
4. User-visible changes get a line in `CHANGELOG.md` under Unreleased.

Read [AGENTS.md](AGENTS.md) for the rules the code follows, especially around
where the password may go. That file is also what coding agents read, so
agent-assisted PRs are fine as long as a human reviewed them.
