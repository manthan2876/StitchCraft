# Contributing to StitchCraft

Thanks for helping improve StitchCraft.

## Before you start

- Read the [development guide](./docs/DEVELOPMENT.md).
- Check existing issues and pull requests before starting substantial work.
- For security vulnerabilities, follow [SECURITY.md](./SECURITY.md) instead of
  opening a public issue.

## Development setup

Follow the root and module-specific READMEs. Keep credentials in local
environment files or approved secret managers. Never commit `.env` files,
Firebase platform configuration, signing keys, tokens, customer data, or
generated build output.

## Validation

Run the checks relevant to your changes:

```bash
(cd stitchcraft-backend && npm install && node --check server.js)
(cd stitchcraft-frontend && npm ci && npm run lint && npm run build)
(cd stitchcraft-mobile && flutter pub get && flutter analyze && flutter test)
```

## Pull requests

Use the pull request template, describe configuration or migration requirements,
and include the exact validation commands you ran. Keep changes focused and
update documentation when behavior or setup changes.

## Code of conduct

Please communicate respectfully and constructively. Harassment, discrimination,
and personal attacks are not acceptable.
