# MudClub Domain Workbook
## 80. Competition

Version: 1.0
Status: Approved

---

# Purpose

The Competition domain represents the structured organisation of sporting activities through which Teams participate in competitive experiences.

Competition provides opportunities for Teams to apply, evaluate and celebrate the development achieved through coaching.

While many clubs participate in formal leagues and tournaments, competitive participation remains optional.

The Competition domain therefore supports both competitive and non-competitive sporting programmes.

---

# Domain Narrative

Competition is one of the ways in which sport is experienced.

It allows Teams to test their preparation, measure their progress and enjoy participation alongside other Teams.

For some Teams, competition is central to their sporting programme.

For others, it plays only a minor or occasional role.

Regardless of competitive ambition, the purpose of Competition is not merely to determine winners.

Competition creates meaningful sporting experiences that contribute to the development of athletes, coaches and clubs.

Within MudClub, competition is viewed as the natural complement to Coaching rather than its replacement.

Just as examinations allow students to demonstrate learning, Competition allows Teams to express the development achieved through coaching.

---

# Responsibilities

The Competition domain is responsible for:

- organising competitive participation;
- managing Competitions;
- managing sporting calendars;
- organising Matches and sporting events;
- recording results;
- maintaining standings where applicable;
- preserving sporting history.

Competition deliberately avoids managing:

- Membership;
- Assignments;
- coaching methodology;
- club administration.

---

# Competition versus Coaching

Coaching develops athletes.

Competition provides opportunities to apply and evaluate that development.

Although closely related, each possesses distinct responsibilities.

A Team may coach without competing.

Competition therefore builds upon Coaching but does not define it.

---

# Competition versus Team

Competition belongs to Teams.

A Team may participate in:

- no Competitions;
- one Competition;
- several Competitions simultaneously.

Participation in Competition does not alter the identity of the Team.

---

# Friendly Matches

Friendly Matches are first-class sporting events.

Unlike league fixtures, they are organised directly between participating Teams or Clubs and exist independently from formal Competitions.

Friendly Matches often serve coaching purposes by allowing Teams to experiment, evaluate progress and prepare for future competitive participation.

The Competition domain should therefore support both formal and informal sporting events.

---

# Competition Types

A Competition represents any organised sporting programme involving multiple Teams.

Examples include:

- local leagues;
- regional championships;
- national championships;
- cups;
- tournaments;
- festivals.

Each Competition possesses its own rules, calendar and participating Teams.

MudClub deliberately avoids distinguishing between these structures unless their business rules genuinely differ.

---

# Core Concepts

The Competition domain is expected to include concepts such as:

- Competition;
- Division;
- Match;
- Venue;
- Result;
- Standing;
- Competition Calendar.

Additional concepts may be introduced as the domain evolves.

---

# Lifecycle

Typical Competition lifecycle:

```text
Planning

↓

Registration

↓

Scheduling

↓

Participation

↓

Results

↓

Standings

↓

Completion

↓

Historical Archive
```

Competitions possess their own lifecycle independently from the Teams that participate.

---

# Relationships

```text
Season
      │
      ▼
    Team
      │
      ▼
 Competition
      │
      ▼
     Match
      │
      ▼
Results & Standings
```

Competition builds upon the organisational structures established elsewhere in the domain.

---

# Time Awareness

Competitions occur within a Season.

Matches occur within Competitions.

Historical competitions and results should always remain available for future reference.

Competition history forms part of the sporting memory of the Club.

---

# Business Rules

Examples include:

- Every Competition belongs to one Season.
- Every Match belongs to one Competition.
- Teams may participate in multiple Competitions.
- Competition participation is optional.
- Friendly Matches may exist independently from formal Competitions.
- Historical results should never be overwritten without traceability.

---

# Match Officials

Formal Competitions are normally administered by external governing bodies.

Officials such as referees, commissioners and table officials therefore remain outside the scope of MudClub.

Future versions may support officials for club-organised tournaments or friendly events, but this is not considered part of the Core Competition domain.

---

# Future Evolution

The following concepts may become part of future versions of MudClub:

## Competition Statistics

Current statistical support intentionally remains minimal.

Possible future developments include:

- player statistics;
- team statistics;
- historical comparisons;
- competition analytics;
- performance dashboards.

These are considered enhancements rather than fundamental domain concepts.

---

## Competition Organisers

MudClub 2.x models Competition from the perspective of an individual Club.

Future versions may introduce concepts such as:

- Federations;
- Associations;
- Competition Organisers;
- League Administrators.

These organisations belong to the wider sporting ecosystem and remain outside the scope of the current redesign.

---

# Candidate Rails Implementation

Competition should remain an independent bounded context.

Primary entities are expected to include:

- Competition;
- Match;
- Result.

Relationships with Members should normally occur indirectly through Teams and Assignments.

The implementation should support leagues, tournaments, championships and friendly competitions without requiring specialised subclasses unless genuine business rules justify them.

---

# Initial Conclusions

Competition represents the organised expression of sporting activity.

It complements Coaching by providing opportunities to apply and evaluate athlete development.

Competition enriches the sporting experience, but it does not define the purpose of a Club.

The primary mission of an amateur sports club remains the development of its members through structured sporting activity.

MudClub therefore models Competition as an important, but optional, part of the sporting domain.

---

## Related Documents

### Workbook

- 50 Season
- 60 Team
- 70 Coaching

### Future Chapters

- 90 Annual Club Cycle
- 100 Implementation Notes