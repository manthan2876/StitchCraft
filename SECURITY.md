# Security policy

## Supported versions

| Version | Supported |
| --- | --- |
| `main` | Yes |
| Older releases | Best effort |

## Reporting a vulnerability

Do not report security vulnerabilities in public issues. Use GitHub Private Vulnerability Reporting for this repository, or contact the project owner through a private channel with:

- a short description and affected component;
- reproduction steps or a proof of concept;
- impact and attack vector;
- suggested mitigation, if known.

Please allow time for investigation and coordinated disclosure. Do not include real customer data, production credentials, or secrets in a report.

## Security expectations

- **Secrets & Credentials**: Store secrets only in local ignored files (`.env`) or deployment secret managers.
- **Server-Side Authorization**: Validate and authorize every API request server-side, scoping queries to the authenticated user's active `shopId`.
- **Validation**: Enforce two-tier validation on all inputs (middleware and schema/table validators).
- **ReDoS Prevention**: Use bounded, linear (non-backtracking) regular expressions to prevent Regular Expression Denial of Service (ReDoS). Always enforce length bounds on user inputs before matching.
- **Rate Limiting**: Protect endpoints against abuse with rate limiters across API, Auth, Upload, and Destructive actions.
- **Dependency Health**: Keep dependencies updated; Dependabot and CodeQL run automatically via GitHub Actions.
- **Token Handling**: Avoid storing raw session credentials in unmanaged browser storage; rely on managed Supabase Auth session lifecycles.
- **Credential Rotation**: Rotate credentials immediately if they are ever exposed.

### Firebase credentials

Firebase configuration files containing project API keys must remain local and must not be committed:

- `stitchcraft-mobile/lib/firebase_options.dart`
- `stitchcraft-mobile/android/app/google-services.json`
- `stitchcraft-mobile/ios/Runner/GoogleService-Info.plist`

Use the local setup documentation for platform configuration. If a Firebase key is reported by GitHub secret scanning, the project owner must rotate or revoke the key in Google/Firebase, restrict replacement keys to the required applications and APIs, and then resolve the corresponding GitHub alert. Removing the file alone does not invalidate a key that may already have been exposed. Historical Firebase secret alerts also require external key rotation or revocation by the project owner. They cannot be resolved by code changes alone; do not attempt to dismiss an alert without first invalidating the affected key in Google/Firebase.

After a security fix is merged, re-run CodeQL and review each alert against the current source before dismissing a stale or false-positive result. Record the alert number, the affected query or endpoint, and the validation evidence in the tracking issue.
