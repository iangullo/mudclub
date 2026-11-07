# MudClub Architecture Handbook
## 00. Project Vision

Version: 1.0
Status: Approved

---

# Why MudClub Exists

MudClub exists to help amateur sports organisations manage both the administrative and sporting aspects of their daily activities.

Its objective is to provide an open, modern and extensible platform that reflects how clubs actually operate rather than forcing clubs to adapt to the software.

MudClub is developed from the perspective of volunteers, coaches, managers and players who actively participate in amateur sport. Consequently, practical workflows and long-term maintainability are valued above technical novelty.

---

# The Problem

Most amateur sports organisations rely on a combination of spreadsheets, messaging applications, federation websites and paper forms to coordinate their activities.

Information is frequently duplicated across multiple systems, administrative tasks fall upon volunteers and organisational knowledge is often difficult to preserve from one season to the next.

Many existing applications focus on competition management or member administration while providing little support for coaching, player development and the day-to-day operation of a club.

MudClub seeks to unify these activities within a coherent platform built around the realities of amateur sport.

---

# Our Vision

MudClub is not simply a database of players, teams or fixtures.

Its purpose is to model the organisational and sporting life of amateur sports clubs.

At its heart, MudClub models the participation of people within an organisation over time.

Participation evolves naturally as people join clubs, register for activities, become members, assume responsibilities, join teams and eventually leave or change roles.

Rather than representing only the current state of a club, MudClub aims to preserve this evolution as part of the organisation's history.

---

# Guiding Values

## Clubs First

Technology should serve the operational needs of amateur clubs.

Architectural decisions should be driven by the domain rather than by implementation convenience.

---

## Open Source

MudClub is intended to remain an open-source project.

Its architecture should encourage collaboration, learning and long-term maintainability.

---

## Domain Driven

Business concepts should determine the structure of the software.

The architecture should emerge from the language and workflows used by clubs.

---

## Modular

Not every club requires every capability.

MudClub should provide a stable Core upon which independent functional modules can evolve.

---

## Practical

Features should solve genuine operational problems encountered by clubs.

Real-world experience should guide development priorities.

---

## Sustainable

MudClub should evolve through continuous refinement rather than disruptive rewrites.

Architectural improvements should preserve existing knowledge whenever practical.

---

# Scope

MudClub aims to support the complete operational lifecycle of amateur sports organisations.

This includes, but is not limited to:

- people and organisational identity;
- memberships and participation;
- coaching and player development;
- competitions;
- registrations and admissions;
- communications;
- finance;
- facilities;
- equipment;
- reporting and administration.

---

# What MudClub Is Not

MudClub does not aim to become:

- a professional sports analytics platform;
- a federation competition management system;
- a social network;
- a general-purpose enterprise resource planning system.

Where appropriate, MudClub should integrate with external systems rather than attempt to replace them.

---

# Looking Forward

MudClub is expected to evolve incrementally through successive architectural improvements.

The objective is not to create the largest sports management application.

The objective is to create a platform that accurately models amateur sports organisations, remains understandable by contributors and continues to provide value to clubs over many years.

Every architectural decision should reinforce this objective.

---

## Related Documents

- 01 Repository Overview
- 02 Ubiquitous Language
- 06 Architecture Philosophy
- 07 Module Boundaries