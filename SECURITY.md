# Security policy

This plugin handles sudo passwords. Please report vulnerabilities privately
through [GitHub security advisories](https://github.com/Gustavobelfort/herdr-sudo-askpass/security/advisories/new),
not in public issues. You should get a reply within a week.

In scope: the password leaking (to disk, logs, argv, environment, other
users), the prompt being bypassable or answered without the human, or sudo
hanging indefinitely. The threat model is in [docs/design.md](docs/design.md#threat-model).

Only the latest release is supported.
