# MudClub Architecture Handbook
## 07. Module Boundaries

Version: 1.1
Status: Approved

---

# Purpose

This document defines the functional modules that compose MudClub and establishes the ownership boundaries between them.

The objective is to ensure that every significant business concept has a clear architectural owner while enabling collaboration between modules through well-defined workflows.

Modules exist to encapsulate business knowledge rather than technical implementation.

---

# Guiding Principles

Every module should:

- own a coherent business capability;
- expose clear services to other modules;
- avoid direct ownership of concepts belonging elsewhere;
- collaborate through explicit workflows;
- evolve independently whenever practical.

Permissions determine who may invoke a business operation.

Modules determine where that operation is implemented.

These concerns must remain independent.

---

# Architectural Overview

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

Core provides the shared organisational concepts used throughout the platform.

Every other module builds upon Core without redefining its concepts.

---

# The Core Module

Core represents the organisational foundation of MudClub.

It owns concepts that remain valid regardless of sport or activity.

## Identity

Responsible for:

- Person
- Club
- Facility
- Organisation settings

Identity answers:

> Who participates?

---

## Participation

Responsible for:

- Registration
- Membership
- Assignments
- Roles

Participation answers:

> How does someone belong and contribute?

---

## Organisation

Responsible for:

- Season
- Permissions
- Organisational structure
- Shared configuration

Organisation answers:

> Where and when does participation occur?

---

# Registrations

Registrations manages the admission of prospective members.

It owns:

- registration requests;
- admissions workflows;
- supporting documentation;
- waiting lists;
- communication during the admissions process.

A successful registration typically results in the creation of a Membership owned by Core.

Registrations therefore collaborates closely with Participation while remaining responsible for the admission process itself.

---

# Coaching

The Coaching module owns player development.

It manages:

- practice plans;
- drills;
- training sessions;
- attendance;
- coaching observations;
- player development.

Coaching does not own memberships or team composition.

Instead, it consumes those concepts through services exposed by Core and Competition.

---

# Competition

Competition owns organised sporting participation.

It is responsible for:

- competitions;
- teams;
- fixtures;
- matches;
- standings;
- sporting statistics.

A Team represents a club's participation in a competition during a particular season.

Team composition is achieved through Assignments owned by Core rather than by embedding membership information directly within Competition.

---

# Finance

Finance manages the financial commitments associated with club participation.

Examples include:

- subscriptions;
- invoices;
- payments;
- sponsorship;
- budgeting.

Finance references Memberships but does not own them.

---

# Communications

Communications manages the distribution of information throughout the organisation.

Examples include:

- announcements;
- notifications;
- newsletters;
- messaging.

Communications consumes information from other modules without assuming ownership of their business rules.

---

# Facilities

Facilities manages physical resources used by the club.

Examples include:

- sports halls;
- courts;
- meeting rooms;
- equipment;
- reservations.

Facilities provides scheduling capabilities that may be used by Coaching, Competition and other modules.

---

# Sport Configuration

Sport is not considered a primary business module.

Instead, sport defines configuration that influences the behaviour of other modules.

Examples include:

- player positions;
- scoring rules;
- tactical boards;
- statistics;
- competition formats.

The long-term objective is for support for new sports to be introduced primarily through configuration rather than specialised implementations.

---

# Time

Time is a cross-cutting concern shared across all modules.

Many concepts possess a defined lifecycle.

Examples include:

- memberships;
- assignments;
- teams;
- seasons;
- registrations;
- competitions.

Modules should preserve these lifecycles rather than modelling only the current state.

---

# Collaboration Between Modules

Modules collaborate through Application Services.

Example:

```
Registration Request

↓

Admissions Workflow

↓

Membership Created

↓

Player Assigned

↓

Training Session

↓

Competition
```

Each module contributes its own business knowledge while preserving ownership of its internal rules.

---

# Ownership Summary

| Module | Owns |
|----------|------|
| Core | Identity, participation and organisation |
| Registrations | Admission workflows |
| Coaching | Player development |
| Competition | Sporting participation |
| Finance | Financial commitments |
| Communications | Organisational communication |
| Facilities | Physical resources |
| Sport | Behavioural configuration |

---

# Evolution

The current MudClub implementation already contains many of these concepts.

MudClub 2.0 will progressively strengthen module boundaries while preserving the successful aspects of the existing application.

New functionality should reinforce these boundaries rather than introduce additional coupling.

---

# Conclusion

Modules are defined by ownership of business knowledge.

They collaborate through shared workflows while preserving clear responsibilities.

This separation enables MudClub to evolve into a modular platform capable of supporting diverse amateur sports organisations without compromising conceptual integrity.

---

## Related Documents

- 03 Domain Model
- 05 Application Architecture
- 06 Architecture Philosophy
- 08 Migration Strategy