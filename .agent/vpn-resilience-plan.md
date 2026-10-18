# Issue 19 execution plan

Scope: declarative NixOS services and generated helpers for PC, laptop, server;
no activation, live failure injection, secret changes, or host routing changes.

- [x] Read issue/comments, owning modules, host roles and networking runbooks.
- [x] Add sanitized layered status and launcher diagnostics with regression tests.
- [x] Add bounded component recovery, prerequisite waits, maintenance and resume handling.
- [x] Exercise authorization rejection, DNS/transport/egress failures and retry limits.
- [x] Update operator runbooks and approved live-validation matrix.
- [ ] Run focused tests, flake checks, namespace harness and all three host builds.
- [ ] Review against issue and repository standards, commit and open PR to main.

Use the existing isolated health service for probe execution; root-owned public
status contains only fixed reason codes, counters, timestamps and probe results.
Recovery never repairs a namespace/firewall by tearing it down. Missing deployment,
secret/configuration faults and authorization rejection require operator action.
Tests at the CLI/service and existing real namespace harness boundaries; mocks do
not establish real-provider failover. Preserve independent IPv4/IPv6 filtering,
private DNS, desktop provider masks and mutable refreshed Hide.me tokens.

Review: standards and issue-spec reviews identified dependency/condition-skipped
startup, credential-change prerequisite ordering and status-priority issues;
fixed them and added regressions. Final re-review reported no remaining blocker.
25 CLI scenarios pass, including interruption-safe repair budgets and unchanged
SOPS content re-materialization preserving the private authorization hold.
Original server journal unavailable: hostname resolution failed and configured
Tailscale IP SSH timed out. No live services or runtime secrets were changed.
