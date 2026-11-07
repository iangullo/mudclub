# MudClub Architecture Handbook
## 02. Ubiquitous Language

Version: 1.0
Status: Approved

---

# Purpose

A shared language is essential for designing software that accurately reflects its domain.

MudClub adopts the principles of Domain-Driven Design by establishing a ubiquitous language: a common vocabulary shared by developers, contributors and domain experts.

The objective is not merely to define terms, but to ensure that every important business concept has a clear and unambiguous meaning throughout the platform.

Whenever possible, class names, services, documentation and user interfaces should adopt this terminology consistently.

---

# Core Principles

The vocabulary of MudClub should:

- reflect how amateur sports organisations describe themselves;
- avoid unnecessary technical jargon;
- distinguish similar concepts with precise definitions;
- remain stable over time;
- evolve alongside the architecture.

If two concepts require different business rules, they should generally have different names.

Likewise, different names should never describe the same concept.

---

# Organisation

## Club

A sports organisation using MudClub.

A club provides the organisational context in which people participate.

A club may organise one or more sports and operate multiple teams across different seasons.

---

## Person

An individual known to the platform.

A Person represents identity.

A person may later become a member, coach, player, volunteer, official or administrator.

These roles are forms of participation rather than different kinds of people.

---

## Membership

The formal relationship between a Person and a Club.

Membership grants a person the ability to participate in the activities of the club according to its organisational rules.

Membership exists over a period of time and may change status during its lifecycle.

---

## Season

A defined period during which the club organises its sporting activities.

Most operational concepts are associated with a particular season.

---

## Facility

A physical location used by the club.

Examples include sports halls, courts, meeting rooms and training venues.

---

# Participation

Participation is the central concept of MudClub.

It describes how people engage with the organisation over time.

Participation evolves naturally throughout a person's relationship with a club.

Examples include:

- becoming a member;
- joining a team;
- coaching a squad;
- managing a competition;
- volunteering at an event.

Participation is represented through explicit business relationships rather than inferred from isolated attributes.

---

## Registration

A request to participate.

Registration begins a workflow that may eventually result in membership and/or participation in a specific activity.

A registration is not itself a membership.

---

## Assignment

The allocation of a member to an organisational or sporting responsibility.

Examples include:

- player assigned to a team;
- coach assigned to a team;
- manager assigned to a team;
- volunteer assigned to an event.

Assignments typically exist for a limited period of time.

---

## Role

A responsibility performed by a member within the organisation.

Examples include:

- player;
- coach;
- manager;
- referee;
- volunteer;
- club administrator.

A person may hold multiple roles simultaneously.

---

# Sporting Concepts

## Sport

A configurable sporting discipline supported by the platform.

Rather than representing an isolated business entity, a Sport defines the rules and behaviours that influence other modules.

Examples include:

- player positions;
- scoring systems;
- tactical boards;
- match formats;
- statistics.

The implementation of Sport may evolve from the existing model towards a configuration-driven approach.

---

## Team

A club's sporting representation within a competition during a season.

A Team brings together members assigned to compete on behalf of a club.

Teams exist for a defined period and may change from one season to the next.

---

## Competition

An organised sporting event in which teams participate.

Competitions define fixtures, standings and sporting outcomes.

---

## Match

A scheduled sporting contest between two or more teams within a competition.

---

## Training Session

A planned coaching activity intended to develop players or teams.

Training sessions belong to the Coaching domain rather than the Competition domain.

---

## Drill

A reusable coaching exercise.

Drills are combined into training sessions and practice plans.

---

## Practice Plan

A structured coaching session composed of one or more drills.

Practice plans define the intended flow and objectives of a training session.

---

# Administrative Concepts

## Admissions

The process through which registration requests are reviewed before membership is granted.

Admissions represent organisational workflows rather than sporting activities.

---

## Finance

The management of financial relationships within the club.

Examples include subscriptions, invoices, payments and budgets.

---

## Communications

The distribution of information to members and other participants.

Examples include announcements, notifications and messaging.

---

# Architectural Concepts

## Core

The collection of organisational concepts shared across the platform.

Core defines identity, participation and organisational structure.

---

## Functional Module

A coherent area of business knowledge responsible for a specific capability.

Examples include Coaching, Competition and Finance.

Modules collaborate but retain ownership of their business rules.

---

## Platform Service

A technical capability used throughout the platform.

Examples include authentication, notifications, storage and auditing.

Platform services are independent of the sporting domain.

---

# Naming Guidelines

Contributors should prefer terminology already defined within this document.

Before introducing a new concept, contributors should determine whether an existing term already represents the intended meaning.

New terminology should only be introduced when it reflects a genuinely distinct business concept.

---

# Conclusion

The ubiquitous language provides the conceptual foundation of MudClub.

It allows developers and domain experts to communicate using a shared vocabulary while ensuring that the architecture remains aligned with the operational reality of amateur sports organisations.

As the platform evolves, this document should remain the authoritative reference for business terminology.

---

## Related Documents

- 00 Project Vision
- 03 Domain Model
- 06 Architecture Philosophy
- 07 Module Boundaries