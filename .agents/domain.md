# Domain documentation

This repository uses a single-context layout: root `GLOSSARY.md` and `docs/adr/`.

When exploring domain terms, read the glossary if present and use its vocabulary.
Read ADRs relevant to the affected subsystem. Surface any conflict with an ADR
rather than silently overriding the decision.

If these documents do not exist, proceed silently. Create them lazily through
domain-modeling when terms or decisions are resolved; do not add empty scaffolding.

Use the existing task-routing guide to keep exploration scoped.
Architecture, module conventions and subsystem runbooks remain authoritative
for their respective areas.
