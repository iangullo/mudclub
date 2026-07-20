# MudClub Domain Workbook
## 40. Assignment

Version: 1.0
Status: Approved

---

# Purpose

Assignment represents the appointment of a member to fulfil a particular organisational responsibility.

While Membership records **why** a person belongs to a club, Assignment records **what** the club has entrusted that member to do.

Assignments are explicit, time-aware commitments made between a club and one of its members.

They are expected to evolve naturally as the needs of the organisation change.

---

# Domain Narrative

Membership alone does not imply participation.

A member may become:

- a player;
- a coach;
- a team manager;
- a volunteer;
- a club president;
- an admissions officer.

Each responsibility represents a commitment accepted by both the organisation and the member.

Assignments therefore describe organisational responsibilities rather than identities.

Throughout a member's life within the club, assignments may begin, evolve and conclude while Membership itself remains unchanged.

---

# Current MudClub Implementation

MudClub 1.x models many assignments implicitly through several independent relationships.

Examples include:

- Players belonging to Teams.
- Coaches assigned to Teams.
- Team managers linked directly to Teams.
- Club administrators configured through application permissions.

These solutions successfully support current functionality but make it difficult to answer broader organisational questions, such as:

- What responsibilities does this member currently hold?
- What responsibilities has this member held historically?
- When did a responsibility begin or end?
- Which responsibilities are compatible?

MudClub 2.0 proposes introducing Assignment as a first-class domain concept.

---

# Assignment versus Membership

Membership answers:

> Why does this person belong to this club?

Assignment answers:

> What responsibility has this member been entrusted with?

Membership establishes an enduring organisational relationship.

Assignments describe the responsibilities performed during that relationship.

Membership may exist without Assignments.

Assignments cannot exist without Membership.

---

# Position

Assignments always refer to a recognised Position.

A Position defines a responsibility understood by the MudClub platform.

Examples include:

- Player
- Head Coach
- Assistant Coach
- Team Manager
- Technical Director
- Club President
- Secretary
- Treasurer
- Volunteer
- Admissions Officer

Positions form part of MudClub's ubiquitous language.

They are defined by the platform rather than individually created by clubs.

This ensures that permissions, workflows and reporting remain consistent across all installations.

Individual clubs remain free to decide:

- which Positions they use;
- whether particular Positions may coexist;
- any club-specific naming conventions presented to users.

---

# Assignment Concepts

Every Assignment records:

- one Membership;
- one Position;
- an organisational context;
- start and end dates;
- its current status.

Future versions of MudClub may allow Assignments to reference different organisational contexts, such as:

- Teams;
- Committees;
- Facilities;
- Competitions;
- Club-wide responsibilities.

The exact scope of these assignment targets remains under discussion.

---

# Lifecycle

```
Created

↓

Offered

↓

Accepted

↓

Active

↓

Modified

↓

Completed

↓

Archived
```

Assignments maintain their own independent lifecycle.

A Membership may accumulate many Assignments throughout its lifetime.

---

# Relationships

```
Identity

↓

Membership

↓

Assignment

↓

Position

↓

Organisational Context

↓

Activities
```

Assignments connect Members with the operational responsibilities they perform.

---

# Time Awareness

Assignments are inherently temporal.

Examples include:

- coaching a team for one sporting period;
- serving as Club President for two years;
- volunteering during a tournament;
- acting as Technical Director throughout several sporting periods.

Historical Assignments remain valuable organisational knowledge and should normally be preserved.

---

# Business Rules

Examples include:

- Every Assignment belongs to exactly one Membership.
- Every Assignment references one Position.
- Positions are defined by the platform.
- Multiple concurrent Assignments are supported.
- Clubs may establish policies restricting incompatible combinations of Positions.
- Assignment history should be preserved.
- Assignments possess explicit start and (optionally) end dates.

---

# Open Questions

## Acceptance

**Question**

How should acceptance of an Assignment be evidenced?

**Discussion**

Assignments represent mutual commitments.

For members with MudClub user accounts, acceptance may be explicit.

For younger members or organisations without individual user accounts, acceptance may instead be represented through guardian approval, club confirmation or administrative acceptance.

The mechanism remains an implementation decision rather than a domain constraint.

---

## Assignment Hierarchies

**Question**

Should Assignments support reporting or mentoring relationships?

**Discussion**

Many clubs appoint Technical Directors, Sporting Coordinators or similar roles responsible for supporting and guiding coaches.

These relationships are not always organisational hierarchies.

Future versions may distinguish between:

- reporting relationships;
- mentoring relationships.

Further exploration is required.

---

## Assignment Targets

**Question**

Should Assignments always relate to Teams?

**Discussion**

Current thinking suggests that Assignments should reference a broader organisational context.

Possible targets include:

- Team;
- Committee;
- Competition;
- Facility;
- Club.

Whether this flexibility is required in MudClub 2.0 remains open.

---

# Possible Implementation

Assignment should become one of the principal Core models.

Competition, Coaching, Communications and future modules should reference Assignments rather than directly associating themselves with Persons.

Position definitions should remain platform-managed, while Assignment records capture the historical appointments made by individual clubs.

---

# Initial Conclusions

Assignments transform Membership into participation.

Membership defines belonging.

Positions define recognised organisational responsibilities.

Assignments record that a member occupied a particular Position for a period of time.

This separation provides a consistent vocabulary for every module while preserving the complete history of organisational responsibilities.

---

## Related Documents

Architecture Handbook

- 03 Domain Model
- 07 Module Boundaries

Workbook

- 30 Membership

Next Chapter

- 50 Team