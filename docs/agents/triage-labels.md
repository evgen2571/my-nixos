# Triage labels

Canonical roles map directly to tracker labels.

| Role | Tracker label | Meaning |
| --- | --- | --- |
| bug | bug | Something is broken |
| enhancement | enhancement | New feature or improvement |
| needs-triage | needs-triage | Maintainer evaluation required |
| needs-info | needs-info | Waiting on reporter information |
| ready-for-agent | ready-for-agent | Fully specified for an agent |
| ready-for-human | ready-for-human | Requires human implementation or judgment |
| wontfix | wontfix | Will not be actioned |

Each triaged issue must carry exactly one category (`bug` or `enhancement`)
and one state (the remaining five roles).
Preserve unrelated labels. If states conflict, ask the maintainer before editing.
Follow the triage skill's state transitions.
