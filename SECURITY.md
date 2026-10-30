# Security policy

## Supported versions

| Version | Supported |
| --- | --- |
| `main` | Yes |
| Older releases | Best effort |

## Reporting a vulnerability

Do not report security vulnerabilities in public issues. Use GitHub Private
Vulnerability Reporting for this repository, or contact the project owner
through a private channel with:

- a short description and affected component;
- reproduction steps or a proof of concept;
- impact and attack vector;
- suggested mitigation, if known.

Please allow time for investigation and coordinated disclosure. Do not include
real customer data, production credentials, or secrets in a report.

## Security expectations

- Store secrets only in local ignored files or deployment secret managers.
- Use strong, unique production secrets for JWT and database access.
- Validate and authorize every API request server-side.
- Keep dependencies updated; Dependabot and CodeQL run from GitHub Actions.
- Rotate credentials immediately if they are exposed.
