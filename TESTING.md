# MudClub Testing Guidelines

- Use Minitest.
- Prefer fixtures over inline object creation.
- Test business behaviour rather than Rails internals.
- Do not test private methods.
- Organize tests into:
  - Validations
  - Scopes
  - Business behaviour
- Every new aggregate introduced in v2 must include tests.