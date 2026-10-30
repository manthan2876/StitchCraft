# Development guide

## Recommended workflow

1. Create a focused branch from `main`.
2. Make the smallest change that solves the issue.
3. Keep secrets, generated files, media, and local databases out of Git.
4. Update the relevant module README or documentation when behavior changes.
5. Run the checks for every module you touched.
6. Open a pull request using the repository template.

## Commit and pull request conventions

Use clear prefixes such as `feat:`, `fix:`, `docs:`, `test:`, `refactor:`,
`chore:`, or `ci:`. Keep pull requests focused and explain:

- what changed and why;
- which modules and user workflows are affected;
- required environment, database, or deployment changes;
- commands used to validate the change.

## Configuration

Use local `.env` files for backend and web configuration. For mobile
development, generate Firebase configuration with FlutterFire or copy the
example template and replace every placeholder. Never use production
credentials for local testing.

## Testing expectations

Backend changes should include request, service, or model coverage when the
behavior is testable. Frontend changes should pass lint and a production build.
Mobile changes should pass `flutter analyze` and `flutter test`. Changes that
alter API behavior should document the affected clients and compatibility
considerations.
