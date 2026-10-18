# Issue 19 execution plan

Scope: declarative NixOS services and generated helpers for PC, laptop, server;
no activation, live failure injection, secret changes, or host routing changes.

- [x] Read issue/comments, owning modules, host roles and networking runbooks.
- [ ] Add sanitized layered status and launcher diagnostics with regression tests.
- [ ] Add bounded component recovery, prerequisite waits, maintenance and resume handling.
- [ ] Exercise authorization rejection, DNS/transport/egress failures and retry limits.
- [ ] Update operator runbooks and approved live-validation matrix.
- [ ] Run focused tests, flake checks, namespace harness and all three host builds.
- [ ] Review against issue and repository standards, commit and open PR to main.

Use the existing isolated health service for probe execution; root-owned public
status contains only fixed reason codes, counters, timestamps and probe results.
Recovery never repairs a namespace/firewall by tearing it down. Missing deployment,
secret/configuration faults and authorization rejection require operator action.
Tests at the CLI/service and existing real namespace harness boundaries; mocks do
not establish real-provider failover. Preserve independent IPv4/IPv6 filtering,
private DNS, desktop provider masks and mutable refreshed Hide.me tokens.
