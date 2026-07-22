# MudClub Domain Workbook
## 05. Domain Overview

Version: 1.1
Status: Approved

---

# Purpose

Provide a high-level map of the MudClub domain.

This chapter introduces the principal business concepts and explains how they relate before each concept is explored in detail.

It serves as the conceptual bridge between the Architecture Handbook and the detailed Domain Workbook.

---

# The Two Dimensions of MudClub

One of the principal discoveries during the domain review is that MudClub models two complementary domains.

---

## Organisational Domain

This domain answers:

> Who belongs to the organisation?

It includes:

People

↓

Registration

↓

Membership

↓

Assignment

These concepts describe the people, organisations and responsibilities that make up the club.

---

## Sporting Domain

This domain answers:

> How does the club deliver sport?

It includes:

Season

↓

Team

↓

Coaching

↓

Competition

These concepts describe the sporting activities organised by the club.

---

## Where both domains meet

Assignments connect both worlds.

               Organisation

People

↓

Membership

↓

Assignment

↓

Season

↓

Team

↓

Coaching

↓

Competition

Without Membership there is no participation.

Without Assignment there is no sporting involvement.

---

# Fundamental Questions

Each chapter answers one business question.

| Chapter      | Question                                            |
| ------------ | --------------------------------------------------- |
| People     | Who exists?                                         |
| Registration | Who wishes to join?                                 |
| Membership   | Who belongs to the club?                            |
| Assignment   | What responsibilities does each member hold?        |
| Season       | During which sporting period is activity organised? |
| Team         | How is that sporting activity organised?            |
| Coaching     | How are athletes developed?                         |
| Competition  | How do Teams participate externally?                |

---

# Concept Relationships

Rather than being isolated entities, the concepts form a progression.

```
People

↓

Registration

↓

Membership

↓

Assignment

↓

Season

↓

Team

↓

Coaching

↓

Competition
```

Each concept builds upon those preceding it while introducing new business knowledge.

---

# Annual Operating Cycle

The concepts also describe the annual rhythm followed by most amateur clubs.

```
Club prepares next Season
        │
        ▼
Registrations Open
        │
        ▼
Admissions Process
        │
        ▼
Membership Created
        │
        ▼
Assignments Made
        │
        ▼
Teams Formed
        │
        ▼
Coaching Programme Begins
        │
        ▼
Competition (optional)
        │
        ▼
Season Ends
        │
        ▼
Review & Planning
        │
        └───────────────┐
                        ▼
               Next Season
```

This illustrates that the workbook models both static concepts and the processes that connect them.

---

# Core Domain Principles

The following principles underpin the domain model.

## People is permanent.

People and organisations exist independently of participation.

## Relationships are first-class concepts.

Registrations, Memberships and Assignments possess their own lifecycle and business rules.

## Time matters.

Most concepts evolve over time.

Historical information should normally be preserved rather than overwritten.

## Sporting activity is organised, not assumed.

Teams, Coaching and Competitions are deliberate organisational structures created within a Season.

## Competition is optional.

Clubs may organise sporting activity without participating in formal leagues or tournaments.

## Seasons organise time.

Membership organises organisational continuity.

Season organises sporting continuity.

---

# Relationship with the Modules

The domain concepts naturally align with MudClub's future modular architecture.

| Domain         | Principal Concepts                             |
| -------------- | ---------------------------------------------- |
| Core           | People, Registration, Membership, Assignment |
| Competition    | Season, Team, Competition                      |
| Coaching       | Training, Sessions, Drills, Plays              |
| Administration | Finance, Communications, Documents             |

---

# Reading the Workbook

The recommended reading order is:

```
05 Domain Overview

↓

10 People

↓

20 Registration

↓

30 Membership

↓

40 Assignment

↓

50 Season

↓

60 Team

↓

70 Coaching

↓

80 Competition
```

Each chapter expands one concept introduced in this overview.

---

# Initial Conclusions

MudClub models amateur sports clubs through two complementary perspectives:
- the organisational relationships that define who participates;
- the sporting structures through which participation occurs.

Together these concepts form a coherent domain model capable of supporting clubs, coaches, athletes and future modules without being tied to a specific sport or implementation.

# Related Documents

Architecture Handbook
- 03 Domain Model
- 07 Module Boundaries

Workbook
- 10 People
- 90 Annual Club Cycle (future)