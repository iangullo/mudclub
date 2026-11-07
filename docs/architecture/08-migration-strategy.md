# MudClub Architecture Handbook
## 08. Migration Strategy

Version: 1.2
Status: Approved

---

# Purpose

This document defines the strategy for evolving MudClub from the current 1.x implementation towards the architecture described throughout this handbook.

The objective is evolutionary improvement rather than replacement.

MudClub 2.0 should emerge through a sequence of controlled refactorings that preserve functionality while progressively clarifying the domain.

---

# Migration Principles
The migration of modules will be broadly aligned with this dependency graph where any future additional modules use the services provided by these main modules.
```
Core
   │
   ├───────────────┐
   │               │
People      Organization
   │               │
   └──────┬────────┘
          │
   Participation
          │
          │
     Calendar
      /     \
Training  Competition
```

## Introduce before replacing

New concepts should be introduced alongside the existing implementation. Existing models should gradually delegate responsibilities to the new domain rather than being rewritten wholesale.

## Preserve compatibility

Adapters and compatibility layers are acceptable during the migration and should be removed only once the new model has fully replaced the old one.

## Refactor responsibilities, not entities

The migration focuses primarily on moving business responsibilities between aggregates rather than replacing the aggregates themselves.

## Testing artefacts evolve alongside production code.

Fixtures, tests and supporting helpers should be migrated when the corresponding bounded context is migrated, avoiding large-scale mechanical reorganisations unrelated to functional changes.

---

# Migration Phases

## Phase 1
Architecture Review ✅

Objectives:
- establish the ubiquitous language;
- define module boundaries;
- document architectural philosophy;
- identify long-term direction.

Deliverables:

- Architecture Handbook.

Status:

Completed.

## Phase 2
Domain Discovery & Workbook ✅

Objectives:
- Explore the amateur sports domain.
- Validate the ubiquitous language.
- Define the Core concepts.
- Produce the Domain Workbook.

Deliverables:
- Domain Workbook.

Status:

Completed

---

## Phase 3
Core Review & Classification ✅

Objectives:
- Review every Core model.
- Classify models into bounded contexts.
- Identify responsibilities to migrate.
- Validate the People and Accounts domains.

Deliverables:
- People review
- Accounts review
- Coaching profile review
- Facility review

Status:

Completed.
---

## Phase 4
Participation Refactoring 🚧

Objectives:
1. Implement Registration.
2. Implement Membership.
3. Implement Assignment.
4. Gradually migrate existing models to consume Participation.
5. Preserve compatibility throughout.

```
Registration
      │
      ▼
Membership
      │
      ▼
Assignment
      │
      ├── Player
      ├── Coach
      ├── Team
      ├── Competition
      └── Permissions
```

Existing functionality should continue operating throughout this phase.

---

## Phase 5
Module Refactoring

Progressively introduce the new architecture into the existing application.

Typical sequence:
```
Coaching
    │
    ▼
Competition
    │
    ▼
Scheduling
    │
    ▼
Communications
    │
    ▼
Finance (proposed)
    │
    ▼
Medical (future)
...
```

Each module should progressively adopt the Participation model introduced during Phase 4.

Existing functionality should continue operating throughout this phase.

---

## Phase 6
Cross-cutting Services

Examples include:

- Notifications.
- Search.
- Reporting.
- Auditing.
- Integrations.
- Background Jobs.
- API.

These services should build upon the stable domain established during previous phases.

---

# Coexistence Strategy

Old and new models may temporarily coexist.

Adapters may be introduced where required.

Temporary duplication is preferable to destabilising working functionality.

Compatibility layers should be removed once migration is complete.

---

# Migration Priorities

Highest priority:

- identity;
- participation;
- memberships;
- registrations.

Lower priority:

- scheduling;
- reporting;
- integrations.

The order reflects architectural dependency rather than implementation difficulty.

---

# Measuring Progress

Migration success should be measured by:

- improved domain clarity;
- reduced coupling;
- improved testability;
- stable user experience;
- incremental delivery of business value.

---

# Conclusion

MudClub 2.0 is not a new application.

It is the next stage in the evolution of MudClub.

The migration strategy exists to preserve accumulated knowledge while progressively improving the architecture.

---

## Related Documents

- 03 Domain Model
- 05 Application Architecture
- 06 Architecture Philosophy
- 07 Module Boundaries