# MudClub Architecture Handbook
## 03. Domain Model

Version: 1.0
Status: Approved

---

# Purpose

The Domain Model defines the fundamental business concepts represented within MudClub and the relationships between them.

Its purpose is not to describe database tables or software classes, but to capture the operational reality of amateur sports organisations using a language that is meaningful to both technical and non-technical contributors.

The Domain Model forms the conceptual foundation upon which the remainder of the architecture is built.

---

# The Domain Narrative

MudClub models the participation of people within amateur sports organisations.

Participation is not a single event but an evolving relationship that develops over time.

A typical lifecycle is:

```
Person

↓

Registration Request

↓

Admissions Process

↓

Membership

↓

Assignments

↓

Sporting Activities

↓

History
```

Every significant concept within MudClub contributes to some stage of this narrative.

---

# Core Concepts

The Core contains the organisational concepts shared by every functional module.

These concepts define the identity of the organisation and remain relatively stable over time.

Core concepts include:

- Person
- Club
- Membership
- Season
- Facility
- Role
- Permissions

These concepts are intentionally independent of any particular sport.

---

# Participation

Participation is the central concept of the MudClub domain.

Rather than modelling isolated entities, MudClub models how people participate within organisations over time.

Participation includes:

- becoming a member;
- assuming organisational responsibilities;
- joining teams;
- coaching players;
- competing in sporting events;
- volunteering within the club.

Participation evolves naturally throughout a person's relationship with a club.

The architecture should preserve this evolution rather than simply representing the current state.

---

# People and Participation

People and participation are distinct concepts.

A Person represents identity.

Membership represents a person's formal relationship with a Club.

Assignments define how that member participates within the organisation.

Activities describe what participants actually do.

Separating these concepts reduces coupling and allows the platform to model increasingly complex organisational structures.

---

# Organisational Structure

The principal organisational concepts are:

## Club

The organisation.

---

## Person

The individual.

---

## Membership

The relationship between Person and Club.

---

## Season

The operational timeframe for sporting activities.

---

## Facility

Locations used by the organisation.

---

## Roles

Responsibilities performed by members.

---

# Sporting Structure

Sporting activities build upon the organisational concepts.

Important concepts include:

- Team
- Competition
- Match
- Training Session
- Drill
- Practice Plan

These concepts describe activities rather than organisational identity.

---

# Team

A Team represents a club's participation within a competition during a particular season.

Teams exist for a limited period of time.

Their composition naturally evolves between seasons.

A Team may contain:

- players;
- coaches;
- managers;
- supporting staff.

The Team therefore represents an organisational unit created for sporting participation rather than a permanent structure within the club.

---

# Registration

Registration represents a request to participate.

Registration begins an admissions workflow.

Successful completion of that workflow results in the creation of a Membership.

Registration and Membership are therefore separate concepts with different responsibilities.

---

# Time as a Domain Dimension

Time is an integral aspect of the MudClub domain.

Many business relationships evolve over time, including:

- memberships;
- team assignments;
- coaching responsibilities;
- competitions;
- seasons.

Where practical, the architecture should preserve the history of these relationships rather than overwriting previous states.

Historical information provides valuable organisational knowledge and supports accurate reporting.

---

# Functional Domains

MudClub currently identifies several major functional domains.

These include:

- Coaching
- Competition
- Registrations
- Finance
- Communications

Each functional domain builds upon the shared concepts provided by Core while owning its own specialised business rules.

---

# Domain Relationships

The following conceptual relationships define the platform.

```
Club
 │
 ├──────── Membership ──────── Person
 │               │
 │               │
 │          Assignments
 │               │
 │      ┌────────┴────────┐
 │      │                 │
 │ Coaching         Competition
 │      │                 │
 │ Training         Matches
 │      │                 │
 └────────────── Season ──────────────
```

This diagram intentionally represents conceptual ownership rather than implementation.

---

# Evolution of the Domain

The current MudClub implementation already contains many of these concepts.

MudClub 2.0 does not seek to replace the existing domain model but to clarify responsibilities, strengthen boundaries and better represent the lifecycle of participation within amateur sports organisations.

The domain model should continue evolving as additional modules are introduced.

---

# Conclusion

The MudClub domain is centred upon participation rather than isolated entities.

People, organisational relationships, sporting activities and time together define how clubs operate.

Understanding these concepts and their relationships is essential for maintaining a coherent architecture as the platform grows.

---

## Related Documents

- 02 Ubiquitous Language
- 04 Database Design
- 05 Application Architecture
- 07 Module Boundaries