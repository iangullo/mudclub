# MudClub Domain Workbook
## 20. Registration & Admissions

Version: 1.1
Status: Approved

---

# Purpose

Registration represents the first interaction between a prospective member and a club.

It provides a structured process through which individuals express an interest in joining an organisation.

Admissions represents the club's evaluation of that request.

Together they define the workflow that transforms a prospective participant into an official member.

Unlike Membership, Registration is temporary.

Its purpose is to evaluate suitability, gather information and support decision-making.

---

# Domain Narrative

Every relationship between a person and a club begins with a conversation.

A parent asks whether their child can join.

A player wishes to transfer clubs.

A coach offers their services.

A volunteer wants to help.

Before any formal relationship exists, the club must understand who is applying, why they wish to participate and whether the necessary information has been provided.

Registration captures this initial expression of interest.

Registration belongs to the preparation of a sporting period rather than the sporting period itself.

Admissions determines whether that request should become a Membership.

---

# Current MudClub Implementation

MudClub 1.x has no dedicated Registration workflow.

Prospective members are generally created directly as Players or Coaches and subsequently associated with a Club.

While functional, this approach combines two distinct concepts:

- requesting admission;
- becoming a member.

MudClub 2.0 proposes separating these concepts explicitly.

---

# People versus Membership

Registration is not Membership.

Registration represents a request.

Membership represents an accepted relationship.

Registration may result in:

- Membership;
- rejection;
- withdrawal;
- postponement;
- waiting list placement.

Not every registration becomes a member.

---

# Registration Concepts

## Registration

Represents an application submitted to a club.

A Registration belongs to:

- one Person;
- one Club;
- one requested participation category.

It may include:

- contact information;
- medical information;
- supporting documents;
- preferred category;
- previous sporting experience;
- guardian information.

---

## Admissions

Admissions is the business process through which registrations are evaluated.

Typical activities include:

- validating information;
- requesting additional documentation;
- interviewing applicants;
- assigning reviewers;
- accepting or rejecting requests.

Admissions owns the workflow.

Registration owns the information.

---

# Lifecycle

```
Prospective Person

↓

Registration Draft

↓

Submitted

↓

Under Review

↓

Additional Information Requested

↓

Accepted
        │
        └──────────────┐
                       │
                Membership Created

Rejected

Withdrawn

Waiting List
```

Admissions concludes when Registration reaches a terminal state.

Membership begins afterwards.

---

# Relationships

```
People

↓

Registration

↓

Admissions

↓

Membership

↓

Assignment

↓

Team
```

Each stage introduces a new business commitment.

---

# Business Rules

Examples include:

- a Registration always belongs to exactly one Club;
- a Registration always identifies one Person;
- a Registration may require guardian approval;
- only Admissions may create Memberships;
- Membership cannot exist without successful Admissions.

---

# Open Questions

### Registration Forms

Should clubs configure multiple registration forms depending on age, sport or activity?

---

### Admissions Roles

Who may approve registrations?

Possible candidates include:

- Admissions Officers;
- Club Administrators;
- Team Managers;
- Coaches (for specific categories).

---

### Supporting Documents

Should registrations manage uploaded documents such as:

- medical certificates;
- parental authorisations;
- identity documents;
- photographs?

---

### Waiting Lists

Should waiting lists belong to Registration or to Membership?

---

### Transfers

Should transferring between clubs reuse the Registration workflow or follow a dedicated transfer process?

---

# Possible Implementation

Registration should become an independent domain concept within the Core module.

Admissions will likely be implemented through Application Services coordinating Registration, People and Membership.

No Membership should be created directly.

Every Membership should originate from an Admissions decision.

---

# Initial Conclusions

Registration is the gateway into MudClub.

It represents interest rather than commitment.

Admissions transforms that interest into an organisational decision.

Membership begins only after that decision has been made.

Separating these concepts simplifies the remainder of the domain and enables richer workflows without increasing conceptual complexity.

---

## Related Documents

Architecture Handbook

- 03 Domain Model
- 05 Application Architecture
- 07 Module Boundaries

Workbook

- 10 People

Next Chapter

- 30 Membership