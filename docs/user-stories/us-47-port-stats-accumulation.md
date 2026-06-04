---
title: "User Story 47: Port Stats Accumulation (Issue #TBD)"
epic: "Epic 16: IEEE 802.1Q Common Types (Issue #TBD)"
type: "user-story"
issue: 9999
status: proposed
labels: ["user-story", "ieee802-dot1q-types"]
---

# User Story: User Story 47: Port Stats Accumulation (Issue #TBD)

## Description
As a Network Operations Engineer,
I want to monitor Bridge Port ingress and egress counters (including frame-rx, frame-tx, and error discards),
So that I can identify packet loss, MTU violations, and transit delay exceedance.

## BDD Acceptance Criteria

- **Scenario: Monitor MTU violation discards**
  - **Given** the ingress MTU of a port is 1500 bytes
  - **When** 5 frames of size 1600 bytes are received on the port
  - **Then** the `mtu-exceeded-discards` counter increments by 5, and the `discard-inbound` counter increments by 5.
