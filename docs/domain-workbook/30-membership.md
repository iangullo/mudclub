# MudClub Domain Workbook
## 30. Membership

Version: 1.0
Status: Approved

---

# Purpose

Membership represents the formal relationship between an identity and an organisation.

It records that a club has accepted an individual as one of its members and establishes the rights and responsibilities that arise from that decision.

Membership is one of the central concepts of MudClub.

Many other business concepts depend upon its existence.

---

# Domain Narrative

Clubs are communities.

People do not simply appear within those communities.

They become members.

Membership represents the club's commitment to welcome an individual into the organisation.

It also represents the member's commitment to participate according to the club's rules.

Membership therefore records a mutual relationship rather than a unilateral decision.

Membership is independent of sporting activity.

A member may never play a match.

A member may coach.

A member may volunteer.

A member may simply support the club administratively.

Membership exists before any specific responsibility is assigned. It identifies a long-term organisational relationship.

Membership survives:

- Multiple Assignments;
- Multiple Teams;
- Multiple Seasons.

---

# Current MudClub Implementation

MudClub 1.x does not contain an explicit Membership model.

Membership is currently inferred through relationships such as:

- Person belonging to a Club;
- active flags (historically);
- current club associations;
- indirect business rules.

While functional, this approach makes it difficult to represent:

- historical memberships;
- temporary memberships;
- suspensions;
- resignations;
- future memberships.

MudClub 2.0 proposes modelling Membership explicitly.

---

# Membership versus Identity

Identity answers:

> Who exists?

Membership answers:

> To which organisation does this identity belong?

Identity remains stable.

Membership evolves throughout time.

A Person may possess many memberships during their lifetime.

Only one may be active for a particular club at a given moment, depending on business rules.

---

# Membership versus Assignment

Membership describes why someone belongs to the organisation.

It does not describe the specific responsibilities they perform over time.

It only records that they belong.

Responsibilities such as:

- Player
- Coach
- Team Manager
- Volunteer
- Board Member
- Referee

are assigned independently.

Assignments may change while Membership remains unchanged.

---

# Responsibilities

Membership owns concepts such as:

- admission date;
- membership status;
- membership category;
- expiry date;
- suspension;
- resignation;
- reinstatement.

Membership deliberately avoids owning:

- sporting roles;
- team allocation;
- permissions;
- financial transactions.

These belong to other domains.

---

# Lifecycle

```
Registration Accepted

↓

Membership Created

↓

Active

↓

Suspended

↓

Active

↓

Ended

↓

Archived
```

Membership records the complete history of the relationship.

Historical memberships remain valuable organisational knowledge.

---

# Relationships

```
Identity

↓

Membership

├───────────────┐
│               │
Assignments   Finance
│               │
└──────┬────────┘
       │
Communications

       │

Competition

       │

Coaching
```

Membership becomes the foundation upon which participation is built.

---

# Business Rules

Examples include:

- Membership always belongs to one Identity.
- Membership always belongs to one Club.
- Membership may only originate from an Admissions decision.
- Historical memberships should never be deleted.
- Membership status must always be explicit.
- A Membership cannot exist without an associated Identity.

Business-specific constraints (such as whether simultaneous memberships in multiple clubs are permitted) should remain configurable according to organisational policy.

---

# Open Questions

### Membership Categories

Should membership categories be configurable?

Examples include:

- Athlete
- Coach
- Volunteer
- Social Member
- Honorary Member

---

### Multiple Memberships

Can a person simultaneously belong to multiple clubs?

Can they belong to multiple sections within the same club?

---

### Membership Duration

Should memberships be perpetual until resignation?

Or renewed annually?

Should this vary between clubs?

---

### Membership Status

Candidate statuses include:

- Pending
- Active
- Suspended
- Inactive
- Ended
- Archived

Further refinement is expected.

---

### Historical Corrections

Should historical memberships ever be modified?

Or should corrections always generate new historical records?

---

# Possible Implementation

Membership should become a first-class domain model within the Core module.

Other modules should reference Membership rather than directly associating themselves with Person or Club whenever organisational participation is required.

Membership should become the principal entry point into Coaching, Competition, Finance and Communications.

---

# Initial Conclusions

Membership represents belonging.

It is the central commitment within the MudClub domain.

Identity tells us who exists.

Registration tells us who wishes to join.

Admissions decides.

Membership records that decision and establishes the enduring relationship upon which the remainder of the platform is built.

---

## Related Documents

Architecture Handbook

- 03 Domain Model
- 07 Module Boundaries

Workbook

- 10 Identity
- 20 Registration & Admissions

Next Chapter

- 40 Assignment