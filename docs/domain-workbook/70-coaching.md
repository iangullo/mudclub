# MudClub Domain Workbook
## 70. Coaching

Version: 1.0
Status: Approved

---

# Purpose

The Coaching domain represents the structured process through which a club develops its members as athletes and individuals.

Its purpose is not simply to organise training sessions, but to support long-term sporting development through planning, instruction, observation and continuous improvement.

Coaching provides the primary activity undertaken by most Teams.

Competition may evaluate or demonstrate that development, but coaching remains the principal purpose.

---

# Domain Narrative

The primary mission of most amateur sports clubs is to help people improve through sport.

Athletes develop technical skills.

They acquire tactical understanding.

They improve physically.

They grow socially and emotionally.

Coaches organise this development through structured activities delivered over time.

These activities are intentionally planned and progressively adapted according to the needs of the athletes and the objectives of the Team.

Coaching therefore represents a continuous educational process rather than a collection of isolated training sessions.

Player and Coach are sporting profiles of a Person that are involved in the coaching activity.

---

# Responsibilities

The Coaching domain is responsible for:

- planning athlete development;
- organising training activities;
- delivering coaching sessions;
- managing coaching resources;
- recording observations;
- supporting continuous improvement.

Coaching deliberately avoids managing organisational membership or competitive administration.

---

# Coaching versus Team

A Team provides the organisational environment.

Coaching provides the developmental activity.

Every coaching activity belongs to a Team.

A Team, however, may temporarily exist before coaching begins.

---

# Coaching versus Competition

Competition is not the purpose of coaching.

Rather, competition provides one means of expressing and evaluating the development achieved through coaching.

Many Teams participate in formal competitions.

Others focus exclusively on learning, recreation or personal development.

The Coaching model should support both equally.

---

# Core Concepts

The Coaching domain is expected to include concepts such as:

- Training Session;
- Practice Plan;
- Drill;
- Play;
- Coaching Objective;
- Athlete Evaluation;
- Attendance;
- Session Notes.

These concepts may evolve independently while sharing the same developmental purpose.

---

# Lifecycle

Typical coaching cycle:

```text
Planning

↓

Preparation

↓

Training Session

↓

Observation

↓

Evaluation

↓

Adjustment

↓

Next Session
```

Coaching is inherently iterative.

Each activity informs future planning.

---

# Relationships

```text
Season
      │
      ▼
    Team
      │
      ▼
 Coaching Programme
      │
      ▼
Training Sessions
      │
      ▼
Drills / Plays
      │
      ▼
Athlete Development
      │
      ▼
Competition (optional)
```

Competition is a possible consequence of coaching rather than its defining purpose.

---

# Time Awareness

Coaching occurs continuously throughout a Season.

Development should be understood over long periods rather than individual sessions.

Historical coaching information provides valuable context for future planning.

---

# Business Rules

Examples include:

- Every coaching activity belongs to one Team.
- Coaching objectives may evolve during the Season.
- Training Sessions should preserve historical records.
- Athlete participation should be recorded independently for each session.
- Coaching should remain meaningful even without formal competition.

---

# Open Questions

## Coaching Programme

Should Teams possess an explicit Coaching Programme that groups sessions, objectives and evaluations?

Current thinking suggests this may become the aggregate root of the Coaching domain.

---

## Athlete Evaluation

Should evaluations belong to:

- individual Training Sessions;
- Coaching Programmes;
- Assignments;
- or the Athlete independently?

This requires further exploration.

---

## Development Objectives

Should coaching objectives be defined:

- for the Team;
- for individual athletes;
- or both?

Current thinking suggests both may coexist.

---

## Session Templates

Should clubs be able to reuse training plans across Seasons?

Current thinking suggests yes.

Templates should remain independent from historical sessions.

---

## Coaching Staff

Should multiple coaches collaborate equally within the same Team?

Current thinking suggests yes.

Assignments determine responsibilities rather than the Coaching domain itself.

---

# Possible Implementation

The Coaching module should remain independent from Competition.

Training Sessions, Drills and Plays become specialised concepts within the Coaching domain.

Relationships with Members should occur through Assignments rather than direct ownership.

The design should support different coaching methodologies without imposing a specific sporting philosophy.

---

# Initial Conclusions

Coaching represents the principal activity undertaken by amateur sports clubs.

Its purpose is to foster athlete development through structured learning rather than simply organising training sessions.

Teams provide the organisational framework.

Coaching provides the developmental process.

Competition may evaluate that development, but it does not define it.

---

## Related Documents

Workbook

- 40 Assignment
- 50 Season
- 60 Team

Next Chapter

- 80 Competition