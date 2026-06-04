---
title: "User Story 44: Traffic Class Priority Mapping (Issue #TBD)"
epic: "Epic 16: IEEE 802.1Q Common Types (Issue #TBD)"
type: "user-story"
issue: 9999
status: proposed
labels: ["user-story", "ieee802-dot1q-types"]
---

# User Story: User Story 44: Traffic Class Priority Mapping (Issue #TBD)

## Description
As a Network Operator,
I want to manage the Priority Regeneration and PCP Decoding/Encoding tables on bridge ports,
So that incoming priority code points (PCPs) map to the correct traffic class queues on transmission.

## BDD Acceptance Criteria

- **Scenario: Configure Custom PCP to Traffic Class mapping**
  - **Given** a bridge port's PCP decoding table is set to defaults
  - **When** the operator maps PCP 6 and 7 to traffic class 5
  - **Then** frames received with PCP 6 or 7 are successfully queued in traffic class queue 5.
