# MudClub Domain Workbook
## 10. Identity

Version: 1.0
Status: Approved

---

# Purpose

Identity forms the foundation of the MudClub domain.

Before a person can become a member, a coach can lead a team, or a club can participate in a competition, the system must first know **who or what exists**.

Identity is concerned with recognising entities independently of the relationships they may establish throughout their lifetime.

Identity answers one fundamental question:

> **Who (or what) exists?**

Identity owns information whose meaning does not depend upon participation.

Identity survives across multiple Memberships, Seasons and Assignments.

Participation, responsibilities and activities are deliberately excluded from this chapter.

---

# Domain Narrative

An amateur sports club is fundamentally a community of people and organisations.

Some are individuals.

Some are organisations.

Some are places.

Some are governing bodies.

Each possesses an identity that exists independently from the role they may later perform.

A child remains the same person regardless of how many clubs they join.

A sports hall remains the same facility regardless of who books it.

A club remains the same organisation regardless of the teams it fields each sporting period.

Identity therefore exists independently from participation.

---

# Current MudClub Implementation

MudClub 1.x already contains several identity concepts.

Current models include:

- Person
- Club
- Parent
- Location

The redesign seeks to clarify the responsibilities of these models rather than replacing them.

Several implementation decisions already align well with the proposed architecture.

Others remain under discussion.

---

# Design Principles

Identity should be:

- stable;
- unique;
- independent of business activities;
- independent of permissions;
- independent of sporting disciplines.

Identity should change infrequently.

Relationships surrounding that identity are expected to evolve.

---

# Identity Concepts

## Person

Represents a natural person.

A Person owns personal information that identifies an individual.

Examples include:

- name;
- date of birth;
- contact information;
- government identifiers;
- photographs.

A Person does **not** own:

- memberships;
- teams;
- coaching responsibilities;
- permissions.

Those belong elsewhere.

### Open Discussion

#### Families and Guardians

**Question**

How should families and guardians be represented?

**Current implementation**

Today a dedicated model (Parent, probably to be renamed) exists to identify a child's guardians.

**Discussion**

Seems like a good fit for the purpose. Some thought should go into how to handle them better - guardianship is just one of the many roles a person can have but only in relation to other specific people.

Question

Should identity verification become part of the Core module?

Current implementation

Completely unmanaged

Discussion

It should be a must for some roles, but not others - e.g. verifying identity of an 8 year old child that their parents are registering to practice a sport is a bit much.

## Club

Represents an amateur sports organisation.

A Club owns organisational identity.

Examples include:

- legal name;
- branding;
- contact information;
- organisational settings;
- supported sports.

A Club is expected to become one of the central identities within MudClub.

### Open Discussion

#### Club Contact Information

**Question**

Should a Club itself possess an associated Person record for contact information, or should both classes share common identity infrastructure?

**Current implementation**

`Club` and `Person` currently share several attributes (such as names and contact details), but no common modules or concerns.

**Discussion**

Both natural persons and organisations possess contact information and other identifying attributes. This suggests that part of their implementation may eventually be shared through common modules, concerns or value objects, while preserving their distinct responsibilities within the domain.

In some contexts, a club may also have an associated legal representative or even constitute a legal entity in its own right. This suggests that introducing a broader `LegalEntity` concept may become appropriate as the domain evolves, although the need for such an abstraction should emerge from business requirements rather than implementation convenience.

## Organisation

Future versions of MudClub may support organisational identities beyond sports clubs.

Examples include:

- federations;
- leagues;
- municipalities;
- schools;
- sponsors.

Whether these should inherit from a common organisational concept remains an open question.

### Open Discussion

#### Organisation models

**Question**

Should organisations inherit from a common Organisation model?

**Current implementation**

In Mudclub 1.x, only Club exists to reflect organizations and in a purely relational way (associating ot each club, coaches, teams, etc.).

**Discussion**

That may be the case to pave the way for the addition of other Organisations different from Clubs. Otherwise it just adds a layer without a clear reason behind it.

#### External organisations

**Question**

How should external organisations such as federations be incorporated?

**Current implementation**

Not considered at all.

**Discussion**

We'll probably leave that for a 3.0 version, it encompasses further than the amateur club approach we have taken until now, but open to re-assess as we progress.

## Facility

Represents a physical place.

Examples include:

- sports halls;
- courts;
- swimming pools;
- meeting rooms;
- clubhouses.

Facilities possess identities independently from bookings or activities.

### Open Discussion

#### Facilities and Addresses

**Question**

Should addresses become identities or value objects?

**Current implementation**

Addresses today are only kept as a text field attribute of Person objects or gmaps urls of Location objects, used to identify Facilities (implictly by binding locations to clubs/sporting periods/teams).

**Discussion**

It seems reasonable to evolve the current Location model and use it to store both Person and facilities. We would have to carefully manage deduplication mechanisms when entering a new address.

---

# Identity versus Participation

One of the principal architectural decisions of MudClub is the separation between identity and participation.

Identity answers:

> Who exists?

Participation answers:

> How are they involved?

Examples:

```
Person

↓

Membership

↓

Assignment

↓

Activity
```

Each concept introduces a new business relationship without changing the underlying identity.

---

# Business Responsibilities

Identity owns:

- recognition;
- contact information;
- permanent characteristics;
- stable identifiers.

Identity deliberately avoids owning:

- memberships;
- registrations;
- assignments;
- sporting activities;
- permissions.

---

# Lifecycle

Identity evolves slowly.

Typical lifecycle:

```
Created

↓

Verified

↓

Updated

↓

Archived
```

Unlike participation, identity rarely possesses complex business workflows.

---

# Relationships

Identity provides the foundation upon which the remainder of the platform is built.

Typical relationships include:

```
Person

↓

Registration

↓

Membership

↓

Assignment

↓

Training Session

↓

Competition
```

The identity itself remains unchanged while the surrounding relationships evolve.

---

# Business Rules

Examples include:

- every identity possesses a unique identifier;
- duplicate identities should be avoided whenever practical;
- identity should not be inferred from participation;
- contact information belongs to identity whenever possible.

---

# Possible Implementation

Identity will probably become one of the Core bounded contexts.

Candidate models include:

- Person
- Club
- Facility

Further abstraction should only be introduced if supported by genuine business requirements.

The implementation should preserve Rails conventions while expressing the domain clearly.

---

# Initial Conclusions

Identity is intentionally small.

Its purpose is not to describe participation.

Its purpose is to provide a stable foundation upon which participation can be modelled.

As the workbook evolves, Identity should remain one of the least volatile areas of the domain.

---

## Related Documents

Architecture Handbook

- 02 Ubiquitous Language
- 03 Domain Model
- 07 Module Boundaries

Next Workbook Chapter

- 20 Registration