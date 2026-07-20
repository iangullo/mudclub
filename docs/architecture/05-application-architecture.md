# MudClub Architecture Handbook
## 05. Application Architecture

Version: 1.0
Status: Approved

---

# Purpose

This document describes the conceptual architecture of the MudClub application.

Its objective is to explain how user interactions are translated into business operations while preserving a clear separation of responsibilities throughout the system.

The application architecture exists to execute the domain model defined by the preceding chapters of this handbook.

---

# Architectural Principles

MudClub follows a layered architecture that separates user interaction, business orchestration, domain knowledge and technical infrastructure.

Each layer has a clearly defined responsibility.

Dependencies should always point towards the domain.

Business rules should never depend upon presentation or infrastructure technologies.

---

# Architectural Overview

```
                    Users
                       │
             User Experience Layer
                       │
            Application Services
                       │
              Business Domains
                       │
                Persistence Layer
                       │
                 Infrastructure
```

Each layer collaborates with the layer immediately beneath it while respecting the responsibilities defined throughout the architecture.

---

# User Experience Layer

The User Experience layer provides the interface through which users interact with MudClub.

Examples include:

- web pages;
- dashboards;
- forms;
- mobile interfaces;
- administrative consoles.

Its responsibilities include:

- presenting information;
- collecting user input;
- navigation;
- accessibility;
- user feedback.

The User Experience layer should contain no business rules.

---

# Application Services

Application Services coordinate business workflows.

They translate user intentions into domain operations.

Typical responsibilities include:

- processing registrations;
- approving admissions;
- creating memberships;
- assigning members to teams;
- scheduling training sessions;
- registering competition results.

Application Services orchestrate multiple business domains while remaining independent of user interface technologies.

They should contain workflow logic but not domain rules.

---

# Business Domains

Business Domains own the business knowledge of the platform.

Examples include:

- Core;
- Coaching;
- Competition;
- Registrations;
- Finance;
- Communications.

Each domain defines:

- business concepts;
- business rules;
- invariants;
- domain services.

Domains collaborate through explicit services rather than by modifying each other's internal state.

---

# Persistence Layer

The Persistence layer stores and retrieves business information.

Its implementation should remain transparent to the business domains.

Persistence is responsible for:

- repositories;
- database interaction;
- transactions;
- query optimisation.

Business concepts should not be shaped by persistence concerns.

---

# Infrastructure

Infrastructure provides technical capabilities required by the platform.

Examples include:

- authentication;
- email delivery;
- background jobs;
- file storage;
- caching;
- logging;
- monitoring.

Infrastructure supports the application but does not define the business.

---

# Collaboration Between Modules

Functional modules collaborate through application services.

For example:

```
Coach

↓

Coaching Interface

↓

Assign Player

↓

Membership Service

↓

Competition Service

↓

Persistence
```

The Coaching module does not directly manipulate membership data.

Instead, it requests operations owned by the appropriate business domain.

This approach preserves clear ownership while encouraging collaboration.

---

# Business Workflows

Most user operations involve multiple domains.

Examples include:

## Player Registration

```
Registration

↓

Admissions

↓

Membership

↓

Assignment

↓

Team
```

## Season Transition

```
Season Closed

↓

Membership Review

↓

Team Creation

↓

Assignments

↓

Competition Setup
```

Application Services coordinate these workflows without assuming ownership of the underlying business rules.

---

# Architectural Boundaries

Business domains own business knowledge.

Application Services own workflows.

Infrastructure owns technical capabilities.

The User Experience layer owns interaction with users.

Maintaining these boundaries reduces coupling and improves long-term maintainability.

---

# Incremental Evolution

MudClub currently implements many responsibilities using traditional Rails models and controllers.

MudClub 2.0 will progressively introduce clearer application services and stronger business boundaries without abandoning Rails conventions.

This evolution should remain incremental and preserve existing functionality whenever practical.

---

# Conclusion

The application architecture exists to execute the business domain.

User interactions become workflows.

Workflows coordinate business domains.

Business domains preserve organisational knowledge.

Infrastructure provides technical capabilities.

Each layer contributes a single responsibility while collaborating to model the participation of people within amateur sports organisations.

---

## Related Documents

- 03 Domain Model
- 04 Database Design
- 06 Architecture Philosophy
- 07 Module Boundaries