# MudClub Architecture Handbook
## 01. Repository Overview

Version: 1.0
Status: Approved

---

# Purpose

This document provides an overview of the current MudClub repository and explains how its structure supports the project's long-term architectural goals.

The repository reflects the gradual evolution of the application from a basketball club management system towards a modular platform for amateur sports organisations.

While the current implementation follows a conventional Ruby on Rails structure, the repository is expected to evolve alongside the architecture described throughout this handbook.

---

# Repository Philosophy

MudClub follows the conventions of Ruby on Rails wherever practical.

Rails conventions provide a familiar development experience, reduce unnecessary complexity and allow contributors to focus on the domain rather than the framework.

As the project evolves, architectural improvements should complement these conventions rather than replace them.

The repository should therefore remain approachable for Rails developers while progressively expressing the business concepts that define MudClub.

---

# Current Structure

The repository follows the standard Rails application layout.

Typical directories include:

- `app/`
- `config/`
- `db/`
- `lib/`
- `public/`
- `test/`
- `docs/`

This organisation reflects the technical implementation of the application rather than its conceptual architecture.

Future development should increasingly align the implementation with the business domains described in this handbook.

---

# The Application Directory

The `app/` directory contains the executable business application.

Within it, Rails groups components according to their technical responsibilities.

Examples include:

- models;
- controllers;
- views;
- components;
- helpers;
- jobs;
- mailers.

This organisation is intentionally retained because it follows established Rails conventions.

However, business concepts should progressively become more visible through namespaces and application structure as MudClub evolves.

---

# The Documentation Directory

The `docs/` directory contains the architectural and functional documentation of the project.

It is intended to become the primary source of architectural knowledge for contributors.

Documentation should evolve alongside the implementation.

Significant architectural decisions should be reflected here before large-scale implementation work begins.

The documentation is organised into distinct areas, including:

- architecture;
- user documentation;
- developer guides;
- future design proposals.

---

# Tests

The test suite documents the expected behaviour of the application.

As the architecture evolves, tests should increasingly reflect business behaviour rather than implementation details.

Where practical, tests should validate business rules at the appropriate level of abstraction.

---

# Configuration

Application configuration should remain external to the business domain whenever possible.

Environment-specific behaviour belongs within configuration rather than within business modules.

This separation encourages portability and simplifies deployment.

---

# Libraries

The `lib/` directory contains reusable infrastructure and supporting libraries that do not naturally belong within the application's business domains.

Reusable framework extensions, importers, exporters and integration code should generally reside here.

Business logic should not migrate into `lib/` simply because it is shared.

Shared business behaviour belongs within the appropriate domain.

---

# Documentation as Architecture

The repository should not be regarded solely as source code.

The architecture handbook forms part of the repository itself.

Its purpose is to explain why the software is organised as it is and to provide guidance for future evolution.

When implementation and documentation diverge, contributors should determine whether the architecture or the implementation requires revision.

Both should evolve together.

---

# Looking Forward

The current repository represents MudClub 1.x.

MudClub 2.0 is expected to retain the strengths of the existing implementation while progressively introducing clearer business boundaries.

This evolution should occur incrementally rather than through a complete rewrite.

The objective is to clarify the architecture already emerging within the application rather than replace it.

---

## Related Documents

- 00 Project Vision
- 03 Domain Model
- 05 Application Architecture
- 06 Architecture Philosophy