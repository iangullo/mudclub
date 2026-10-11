## ID strategy

- **UUIDs** for tables a user sees in an anonymous-facing URL, or that
  need opaque identifiers for security/consistency reasons.
  Currently: `registrations`, `admission_people`, `documents`,
  `assignments`, `memberships`, `registration_messages`.

- **bigint** for everything else. `people`, `users`, `players`,
  `coaches`, `parents`, `person_relationships`, and their join tables
  are the notable personal-data exceptions.

- **TODO (deferred):** convert the person graph (`people`, `users`,
  their FKs, and `versions.item_id`) to UUIDs. Small dataset, no urgency.
  Do it in a single pass with a data-preserving migration, or during a
  maintenance window with a schema reload + data restore. See git log
  for the deferred-design discussion.