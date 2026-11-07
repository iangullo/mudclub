# MudClub Domain Workbook
## 60. Sporting Period (Season)

Version: 0.3
Status: Mature Draft

---

# Purpose

A Sporting Period defines the temporal framework within which a club organises its sporting activities.

It establishes the calendar against which Teams, Competitions, Coaching programmes and other sporting operations are planned.

A Sporting Period does not describe sporting activity itself.

It defines when that activity occurs.

---

# Domain Narrative

Sport is inherently cyclical.

Each new Season is preceded by a period of organisational preparation.

Clubs receive registrations, evaluate applications, confirm memberships, appoint coaches and organise Teams before sporting activities begin.

The Season therefore represents the operational phase of the sporting cycle rather than the complete organisational process.

Although clubs possess a continuous organisational identity, their sporting activities naturally occur within distinct periods. The Sporting Period provides this organisational calendar.

It becomes the common temporal reference for all sporting operations:

- Training programmes are planned.

- Members take on new responsibilities.

---

# Current MudClub Implementation

MudClub 1.x already includes a Season model.

The current implementation assumes a globally defined list of Seasons shared by every club.

This approach has proven sufficient for a single-sport application.

MudClub 2.0 seeks to associate Sporting Periods with each Sporting Programme, allowing different sports to define independent calendars while preserving a common organisational model.

---

# Sporting Period People

Typical attributes include:

- Sporting Programme;
- Name;
- Description;
- Start Date;
- End Date;
- Status.

Examples include:

- 2026/27 Basketball Season
- 2027 Swimming Programme
- Summer 2027 Development Programme

---

# Sporting Period versus Club

A Club exists continuously.

Sporting Periods exist temporarily.

A Club organises many Sporting Periods throughout its lifetime.

Each Sporting Programme manages its own sequence of Sporting Periods.

---

# Sporting Period versus Team

Teams belong to one Sporting Period.

A Sporting Period may contain many Teams.

When a new Sporting Period begins, new Teams are normally created.

Historical Teams remain associated with the Sporting Period in which they participated.

---

# Sporting Period versus Competition

Competitions usually occur within one Sporting Period.

However, the Sporting Period exists independently from any Competition.

Recreational Teams, training programmes and development groups may exist without formal competitions.

---

# Lifecycle

```
Planned

↓

Open

↓

Active

↓

Completed

↓

Archived
```

The Sporting Period acts as the temporal boundary for many other domain concepts.

---

# Relationships

```
Club

↓

Sporting Programme

↓

Sporting Period

├───────────────┐
│               │
Teams      Competitions
│               │
│               │
Coaching     Calendar
```

---

# Time Awareness

Time is the defining characteristic of a Sporting Period.

Examples include:

- registration opening;
- team formation;
- competition calendars;
- coaching plans;
- season closure.

Most sporting activities occur within exactly one Sporting Period.

---

# Business Rules

Examples include:

- Every Sporting Period belongs to one Sporting Programme.
- Sporting Periods should not overlap unless explicitly permitted.
- Every Team belongs to one Sporting Period.
- Historical Sporting Periods should never be modified after completion.
- Sporting Periods may exist without formal competitions.

---

# Open Questions

## Multiple Active Sporting Periods

May a Sporting Programme maintain overlapping Sporting Periods?

Examples include:

- Winter League
- Summer Development Programme

---

## Fiscal Alignment

Should Sporting Periods align with financial years?

Or remain completely independent?

---

## Season Preparation

Which organisational activities should occur before a Sporting Period becomes Active?

Examples include:

- admissions;
- Team creation;
- competition registration;
- coach allocation.

---

## Cross-Period Participation

How should temporary participation across Sporting Periods be represented?

---

# Possible Implementation

The existing Season model may evolve into the Sporting Period model.

Ownership should migrate from a global definition to the Sporting Programme, allowing each sport within a club to maintain independent calendars.

---

# Initial Conclusions

The Sporting Period provides the temporal framework of the sporting domain.

It does not organise people.

It does not organise Teams.

Instead, it provides the calendar within which those concepts evolve.

Together with Membership, it forms one of the principal organisational axes of MudClub:

Membership provides organisational continuity.

Sporting Period provides sporting continuity.

---

## Related Documents

Workbook

- 30 Membership
- 40 Assignment
- 50 Team

Next Chapter

- 70 Coaching