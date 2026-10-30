# Contributing to StitchCraft

Thanks for helping improve StitchCraft!

## Before you start

- Read the [development guide](./docs/DEVELOPMENT.md) and [architecture guide](./docs/ARCHITECTURE.md).
- Check existing issues and pull requests before starting substantial work.
- For security vulnerabilities, follow [SECURITY.md](./SECURITY.md) instead of opening a public issue.

## Development setup

Follow the root and module-specific READMEs. Keep credentials in local environment files (`.env`). Never commit `.env` files, Firebase platform configuration, signing keys, tokens, customer data, or generated build output.

## Validation

Before opening a pull request, ensure the tests and checks pass for every module you changed:

```bash
# Backend checks (tests + syntax check)
(cd stitchcraft-backend && npm ci && npm test && find . -name node_modules -prune -o -type f -name '*.js' -print0 | xargs -0 -n1 node --check)

# Frontend checks (lint + tests + production build)
(cd stitchcraft-frontend && npm ci && npm run lint && npm test && npm run build)

# Mobile checks (analysis + unit/widget tests)
(cd stitchcraft-mobile && cp .env.example .env && flutter pub get && flutter analyze && flutter test)
```

## Pull requests

1. Use the [pull request template](./.github/pull_request_template.md).
2. Reference the related issue (e.g. `Fixes #21` or `Closes #15`).
3. Describe what changed, the affected modules, and any migration or configuration requirements.
4. Include the exact validation commands you executed and their output.
5. Keep pull requests focused on a single feature, bugfix, or enhancement.

## Code of conduct

Please communicate respectfully and constructively. Harassment, discrimination, and personal attacks are not acceptable.
