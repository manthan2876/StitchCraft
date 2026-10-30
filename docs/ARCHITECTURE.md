# StitchCraft architecture

## System overview

StitchCraft is organized as three deployable clients/services:

```text
Flutter mobile app ─┐
                    ├──> Express API ───> Supabase PostgreSQL
React web dashboard ─┘          └───────> external storage/services
```

The API is the source of truth for shared shop data. Clients should not
duplicate authorization or business rules. The mobile application may cache
data locally for offline workflows, but synchronized writes must be accepted
and validated by the API.

## Backend boundaries

- `config/`: database, Supabase, and CORS configuration.
- `middleware/`: cross-cutting request concerns such as authentication and
  error handling.
- `routes/`: HTTP route registration and API surface.
- `controllers/`: request parsing, response formatting, and orchestration.
- `services/`: reusable business operations.
- `models/`: persistence schemas and indexes.

New business rules should live in services when they are shared or non-trivial.
Controllers should validate request inputs, call the appropriate service, and
return consistent error responses.

## Client boundaries

The web dashboard groups UI by pages, features, services, and shared context.
The mobile app groups UI and state under `lib/features`, with shared concerns
under `lib/core`. Keep API calls and persistence adapters separate from widgets
so the same behavior can be tested without rendering the full application.

## Data and secrets

The repository includes templates, not production credentials. Local values
belong in ignored environment files. Firebase platform configuration,
application signing keys, and generated Firebase configuration files are
ignored. Rotate a credential immediately if it is ever committed.

## Deployment

The backend and web application can be deployed independently. Keep
environment-variable names documented in the relevant module README and
configure CORS, API URLs, database access, and authentication secrets per
environment.

## Change guidance

When a change crosses modules:

1. Define or update the API contract first.
2. Update backend validation, authorization, persistence, and error handling.
3. Update each client integration and its loading/error states.
4. Add or update tests and documentation.
5. Run the module checks and the CI-equivalent checks that apply.
