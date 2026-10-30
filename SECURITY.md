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

### Firebase credentials

Firebase configuration files containing project API keys must remain local and
must not be committed:

- `stitchcraft-mobile/lib/firebase_options.dart`
- `stitchcraft-mobile/android/app/google-services.json`
- `stitchcraft-mobile/ios/Runner/GoogleService-Info.plist`

Use the tracked `.example` templates for local setup. If a Firebase key is
reported by GitHub secret scanning, the project owner must rotate or revoke
the key in Google/Firebase, restrict replacement keys to the required
applications and APIs, and then resolve the corresponding GitHub alert. Removing
the file alone does not invalidate a key that may already have been exposed.
