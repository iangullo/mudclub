# MudClub Domain Workbook
## 00. Introduction

Version: 1.1
Status: Approved

---

# Purpose

The Domain Workbook accompanies the MudClub Architecture Handbook.

Where the Architecture Handbook records architectural decisions, the Domain Workbook records the exploration that leads to those decisions.

Its purpose is to analyse the business domain of amateur sports organisations before implementation begins.

Documents within this workbook are expected to evolve, be revised and occasionally be discarded as the understanding of the domain improves.

---

# Relationship with the Architecture Handbook

The Architecture Handbook describes the accepted architecture.

The Domain Workbook explores candidate models.

A concept should normally progress through the following lifecycle:

```
Observation

↓

Discussion

↓

Domain Model

↓

Architecture Decision

↓

Implementation
```

Consequently, the workbook may contain multiple alternative proposals for the same problem.

---

# Goals

The workbook seeks to answer questions such as:

- How do amateur sports organisations actually operate?
- Which concepts are fundamental?
- Which concepts are merely implementation details?
- What business rules govern these concepts?
- How do concepts evolve over time?
- Which workflows connect them?

---

# Modelling Principles

The workbook follows several principles.

## The domain comes first.

Technology should never determine the shape of the model.

## Reality is preferred over convenience.

The model should reflect how clubs actually work rather than how software is easiest to implement.

## Concepts should reflect the language used by clubs.

Whenever possible, the workbook adopts the terminology naturally used by club administrators, coaches and volunteers.

Technical terminology should only appear when it improves understanding.

## Relationships deserve equal attention.

Many of the most important concepts are relationships rather than entities.

The workbook should analyse both.

## Time matters.

Business concepts evolve.

Understanding these lifecycles is often more important than understanding their attributes.

## Multiple solutions may coexist.

The workbook is intentionally exploratory.

Alternative designs may be documented before a preferred approach emerges.

---

# Standard Chapter Structure

Each chapter should attempt to answer the same questions.

## Purpose

Why does this concept exist?

## Domain Narrative

How would a club describe this concept?

## Responsibilities

What business knowledge does it own?


## Lifecycle

How does it evolve over time?

## Relationships

Which other concepts interact with it?

## Business Rules

Which invariants must always hold?

## Open Questions

Which aspects remain unresolved?

## Possible Implementation

Only after the previous sections have stabilised should implementation ideas be discussed.

Implementation should always remain subordinate to the domain.

---

# Scope

The workbook currently explores the Core domain of MudClub and its relationship with the sporting modules.

Current chapters include:

- Identity
- Registration
- Membership
- Assignment
- Season
- Team
- Coaching
- Competition

Future chapters may include:

- Communications
- Finance
- Documents
- Volunteers
- Facilities

---

# Success Criteria

The workbook will be considered successful when contributors can explain the operation of an amateur sports club without referring to Rails, databases or implementation details.

Only then should implementation begin.

---

## Related Documents

- Architecture Handbook 00 – Project Vision
- Architecture Handbook 03 – Domain Model
- Architecture Handbook 06 – Architecture Philosophy