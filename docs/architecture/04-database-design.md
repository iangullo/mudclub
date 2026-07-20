# MudClub Architecture Handbook
## 04. Database Design

Version: 1.0
Status: Approved

---

# Purpose

This document describes the principles that guide the persistence of business information within MudClub.

Rather than prescribing a specific database implementation, it defines the architectural philosophy used when modelling data and relationships.

The database should faithfully represent the business domain while remaining maintainable, extensible and understandable.

---

# Domain Before Database

The database exists to support the domain model.

Business concepts should never be introduced solely because they simplify database implementation.

Likewise, implementation shortcuts should not compromise the clarity of the domain.

The Domain Model therefore remains the authoritative source from which the database design evolves.

---

# Stable Identity

Entities representing long-lived organisational concepts should possess stable identities.

Examples include:

- Person
- Club
- Facility
- Season

Identifiers should remain independent of mutable business information such as names, email addresses or telephone numbers.

---

# Relationships are First-Class Concepts

Many important business concepts are relationships rather than standalone entities.

Examples include:

- Membership
- Team Assignment
- Coaching Assignment
- Registrations

These relationships possess their own lifecycle and business rules.

Whenever a relationship contains business meaning, it should generally be represented explicitly rather than as a simple join table.

---

# Time Matters

Time is a fundamental characteristic of the MudClub domain.

Relationships frequently evolve throughout the lifetime of a club.

Examples include:

- memberships beginning and ending;
- coaches changing teams;
- players progressing through age groups;
- facilities becoming unavailable;
- seasonal registrations.

Whenever practical, these changes should be represented by creating or closing relationships rather than overwriting historical information.

---

# History over State

MudClub should prefer preserving historical information over storing only the current state.

For example, instead of recording only a player's current team, the system should preserve every assignment throughout that player's participation in the club.

Historical information enables:

- reporting;
- auditing;
- statistics;
- organisational continuity;
- long-term player development.

---

# Explicit Relationships

Business relationships should remain explicit.

For example:

```
Person

↓

Membership

↓

Assignment

↓

Team
```

is preferable to storing:

```
person.team_id
```

because it better represents the business reality and naturally accommodates history.

---

# Composition over Duplication

Information should be stored once whenever practical.

Examples include:

- contact details belonging to Person;
- organisational settings belonging to Club;
- facility information shared across activities.

Business modules should reference shared concepts rather than duplicate them.

---

# Configuration over Specialisation

MudClub should favour configurable behaviour over sport-specific database structures.

Examples include:

- player positions;
- scoring systems;
- court dimensions;
- statistics definitions.

Sport-specific behaviour should be governed by configuration parameters rather than dedicated tables.

---

# Referential Integrity

Relationships between entities should be enforced by the database whenever possible.

Foreign keys and appropriate constraints should protect the integrity of organisational information.

Application code should complement, rather than replace, database integrity.

---

# Validation

Business validation belongs within the domain.

The database should enforce structural correctness.

The application should enforce business correctness.

Examples include:

Database:

- foreign keys;
- uniqueness constraints;
- required fields.

Application:

- eligibility;
- admissions;
- roster limits;
- competition rules.

---

# Soft Deletion

Soft deletion should be used sparingly.

Where historical information has business value, relationships should normally be closed rather than deleted.

Deletion should generally be reserved for:

- accidental data entry;
- incomplete workflows;
- administrative correction.

---

# JSON and Structured Data

Structured database columns such as JSONB provide valuable flexibility for configurable information.

Examples include:

- club settings;
- sport configurations;
- UI preferences.

Core business relationships should not be hidden within unstructured JSON data.

Relationships requiring querying, validation or historical tracking should remain explicitly modelled.

---

# Performance

Performance considerations should influence implementation without compromising the conceptual model.

Optimisation techniques such as caching, denormalisation or materialised views may be introduced when justified.

These techniques should remain implementation details rather than defining characteristics of the domain.

---

# Evolution

The persistence model should evolve incrementally.

Schema migrations should clarify the domain while preserving existing information whenever practical.

Refactoring should prioritise conceptual improvements over structural reorganisation.

---

# Conclusion

The MudClub database should faithfully represent the participation of people within amateur sports organisations.

Identity, relationships and history are considered first-class concepts.

The persistence model exists to support the domain rather than define it.

---

## Related Documents

- 03 Domain Model
- 05 Application Architecture
- 06 Architecture Philosophy