# MudClub Domain Workbook
## 50. Team

Version: 1.0
Status: Approved

---

# Purpose

A Team represents the organisational unit through which a club pursues a sporting objective during a defined sporting period.

Teams bring together members, coaches and other responsibilities to participate in coaching activities, competitions and player development.

Unlike Membership, which represents belonging to the organisation, Teams represent participation in a specific sporting project.

---

# Domain Narrative

Every sporting period brings new challenges.

Players develop.

Coaches change.

Competitions evolve.

Objectives are redefined.

Although many members may continue from previous years, each Team represents a new organisational commitment with its own identity and purpose.

A Team is therefore more than a collection of people.

It is an organisational entity with its own lifecycle, objectives and sporting context.

Members participate in Teams through Assignments, allowing both the Team and its participants to evolve independently over time.

---

# Current MudClub Implementation

MudClub 1.x already models Teams as first-class entities.

Teams currently maintain relationships with:

- Players;
- Coaches;
- Events;
- Matches.

This implementation has successfully supported basketball clubs for several years.

MudClub 2.0 aims to preserve these strengths while clarifying that participation in a Team occurs through Assignments rather than through direct ownership of members.

---

# Team Identity

Every Team possesses its own identity.

Typical attributes include:

- Club;
- Sporting Programme;
- Sporting Period (Season);
- Name;
- Category;
- Competition;
- Status.

These attributes describe the Team itself rather than the individuals who participate within it.

---

# Team versus Membership

Membership answers:

> Why does this person belong to the club?

Team answers:

> Which sporting project is this member participating in?

Membership represents organisational belonging.

Teams represent sporting organisation.

A member may belong to a club without belonging to any Team.

---

# Team versus Assignment

Teams do not own Players or Coaches.

Instead, members participate in Teams through Assignments.

Examples include:

- Player assigned to U14 Boys.
- Head Coach assigned to Senior Women.
- Assistant Coach assigned to Mini Basket.

Assignments preserve the history of individual participation while allowing Teams to maintain their own independent identity.

---

# Lifecycle

```
Planned

↓

Forming

↓

Active

↓

Completed

↓

Archived
```

Teams are intentionally time-aware.

Each Team exists within a single sporting period.

When a new sporting period begins, new Teams are normally created, even if many members continue from previous years.

---

# Relationships

```
Club

↓

Sporting Programme

↓

Sporting Period

↓

Team

├──────────────┐
│              │
Assignments  Competition
│              │
│              │
Coaching     Matches
```

The Team provides the organisational context through which sporting activities are delivered.

---

# Time Awareness

Time is one of the defining characteristics of a Team.

Examples include:

- annual youth squads;
- development programmes;
- tournament squads;
- summer camps.

A Team should always preserve its historical identity rather than being reused across different sporting periods.

---

# Business Rules

Examples include:

- Every Team belongs to one Club.
- Every Team belongs to one Sporting Programme.
- Every Team belongs to one Sporting Period.
- Participation occurs through Assignments.
- Historical Teams should not be reused across Sporting Periods.
- Teams may exist without participating in formal competitions.

---

# Organisational Continuity

Although each Team represents a new organisational entity, clubs rarely begin each sporting period from scratch.

MudClub should support controlled sporting period transitions, allowing clubs to prepare new Teams by reusing selected aspects of previous ones.

Examples include:

- coaching staff;
- facilities;
- weekly schedules;
- communication groups;
- training plans;
- competitions.

Player participation should remain an explicit decision rather than being automatically inherited.

The objective is to preserve organisational continuity while recognising that every Team remains a distinct historical entity.

---

# Open Questions

## Temporary Assignments

How should temporary participation be represented?

Examples include:

- a junior player called up for one match;
- a player invited to train with another Team;
- a coach temporarily covering another squad.

Current thinking suggests these should be represented as short-lived Assignments rather than permanent Team membership.

---

## Recreational Teams

Should recreational or non-competitive groups also be represented as Teams?

Current thinking suggests yes.

Competition should remain optional rather than defining the existence of a Team.

---

## Sporting Period

This workbook deliberately avoids defining the ownership of Sporting Periods (Seasons).

Current thinking suggests they should be associated with a Club's Sporting Programme rather than globally or directly with the Club itself.

This topic will be explored in the next chapter.

---

# Possible Implementation

Team should remain one of the principal entities of the Competition domain.

Assignments provide the mechanism through which Members participate in Teams.

Competition and Coaching build upon Teams while preserving their own independent responsibilities.

---

# Initial Conclusions

Teams are organisational entities rather than collections of people.

They possess their own identity, lifecycle and sporting objectives.

Assignments record how Members participate in Teams while preserving the historical evolution of both concepts independently.

Teams exist within a Sporting Period, whose precise ownership and lifecycle will be defined in the following chapter.

---

## Related Documents

Architecture Handbook

- 03 Domain Model
- 07 Module Boundaries

Workbook

- 30 Membership
- 40 Assignment

Next Chapter

- 60 Sporting Period (Season)