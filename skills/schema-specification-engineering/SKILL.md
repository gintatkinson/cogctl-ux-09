---
name: schema-specification-engineering
description: Reverse-engineer structural schemas (e.g., YANG, OpenAPI, Protobuf) and their associated normative specification documents into deterministic, behavior-driven Agile feature specifications.
risk: medium
source: custom
---

# Schema Specification Engineering

Use this as the single canonical workflow for translating structural schemas and their normative specification documents into highly rigorous, implementation-ready Agile specifications for sub-agents. 

> [!TIP]
> This skill operates in the spirit of the `andrej-karpathy` methodology: focus deeply on the fundamentals, enforce exhaustive structural rigor, leave absolutely zero ambiguity in the acceptance criteria, and instrument the outputs flawlessly into project tracking systems.

> [!IMPORTANT]
> **EXHAUSTIVE SEMANTIC MODELING MANDATE**
> Do NOT blindly map every isolated leaf node (e.g., `x`, `y`, `z`) to a separate Feature. You MUST semantically model the schema by grouping cohesive properties into a single logical Feature (e.g., "Cartesian Coordinates"). However, "zero abstraction" still applies: within that grouped Feature, you MUST exhaustively document EVERY underlying leaf node, capturing its exact data type, mathematical constraints (fraction-digits, units), defaults, and verbatim RFC text. No constraint detail may be lost or summarized away.

## Step 1: Forensic Audit & Module Decomposition

1. **Parse the Schema:** Read the primary structural schema file (e.g., `*.yang`, `*.yaml`, `*.proto`) and its imports.
2. **Identify Top-Level Trees:** Decompose the high-level structural containers (e.g., `/globals`, `/tunnels`, `/lsps`, `/rpcs`) into discrete logical groupings.
3. **Establish Epics:** Map these high-level structures directly into Agile "Epics". Do not create the Epic GitHub issue yet. First, document it locally as a markdown file (e.g., `docs/epics/epic-01-name.md`).

## Step 2: Exhaustive Feature Extraction & Logical Scoping

1. **Semantic Feature Breakdown:** Analyze the child containers, choices, or elements. Identify cohesive functional groups (e.g., a "Velocity Vector" containing `v-north`, `v-east`, and `v-up`) and map them to a distinct "Feature".
2. **Logical Scoping (Platform-Agnostic):** Feature specifications must be strictly logical and implementation-free. No target platform frontmatter fields, no filesystem paths, and no programming language specifics. Physical platform selection occurs strictly during implementation/design.
3. **Exhaustive Constraint & Typedef Parsing:** For EVERY leaf node and typedef within the grouped feature, analyze and record all structural constraints:
   - All custom types and typedefs (e.g., `geographic-coordinate-degree`) must be explicitly defined and mapped to their fields.
   - `when` and `must` clauses.
   - `type` definitions (fraction-digits, string patterns, identityrefs).
   - `units` and `default` values.
   - `config false` (operational vs configuration state).
4. **Logical Integration & UI Capabilities:** Every feature spec MUST explicitly include a `## 2. Logical System Integration & UI Capabilities` section detailing:
   - **Logical Data Model:** The representation of the feature attributes in the location database system.
   - **Logical Processing Rules:** Validation, normalization, and coordinate co-dependency rules (e.g., latitude/longitude must exist together; coordinate constraints depend on the reference frame's astronomical body and datum).
   - **Logical UI Representation:** Description of required UI elements, inputs, display formatting (e.g., DMS representation), and alert/error display criteria.
5. **Acceptance Criteria Translation:** Transform these logical constraints and UI capabilities into exhaustive Given-When-Then Logical Acceptance Criteria. Include E2E validation scenarios (e.g., coordinate bound failures, co-dependency omissions, and different reference frames).
6. **Draft the Feature Specs:** Write each Feature as a local markdown file (e.g., `docs/features/feat-01-name.md`).

## Step 3: Specification Context Injection (Verbatim)

1. **Locate Normative Text:** Find the canonical normative text document (e.g., IETF RFC, 3GPP TS) associated with the schema.
2. **Extract Line-by-Line Context:** Identify the exact paragraphs and sections that explain the behavioral logic of the specific structural container.
3. **Embed Context:** Inject this verbatim text directly into the feature specification under a `## Specification Context (Verbatim)` section. This guarantees that implementing sub-agents have ground-truth knowledge and are not hallucinating implementation details.

## Step 4: Output Formatting & Strict GitHub Instrumentation

> [!WARNING]
> You must strictly follow the operational sequencing below to ensure the `#IssueID` linkages are perfectly resolved.

1. **Epic Markdown Template:**
   The Epic markdown file (e.g., `docs/epics/epic-[X]-[name].md`) MUST strictly adhere to this format:
   ```markdown
   ---
   title: "Epic [X]: [Epic Title] (Issue #[IssueID])"
   type: "epic"
   issue: [IssueID]
   labels: ["epic", "<protocol-name>"]
   ---

   # Epic: Epic [X]: [Epic Title] (Issue #[IssueID])

   ## 1. Context
   [Detailed context explaining the purpose of this epic, the referenced specifications, and how it fits into the broader system architecture]

   ## 2. Requirements & Checklist
   [Construct a markdown tasklist of child features/stories/cases referencing BOTH the Issue ID and the absolute GitHub URL of the documents. Note: relative links resolve incorrectly on GitHub and cause 404 errors. You MUST dynamically determine the remote repository URL by running `git remote get-url origin` and construct the absolute link pointing to the file on the current branch]
   - [ ] #[IssueID] - [Feature [Y]: [Feature Title] (Issue #[IssueID])](https://github.com/owner/repo/blob/branch_name/docs/features/feat-[Y].md)

   ## 3. Architecture and System Interaction Diagrams
   [Include Mermaid diagrams outlining high-level structural components, data flow, or class relationships within this Epic's scope]
   ```mermaid
   classDiagram
       class GeoLocation {
           +referenceFrame
           +locationChoice
           +velocity
           +temporalValidity
       }
       %% Add other classes and relationships
   ```

   ## 4. State Machine Definitions
   [Include a Mermaid state diagram modeling key operational states and transitions, e.g. for configuration states, validity transitions, or system modes]
   ```mermaid
   stateDiagram-v2
       [*] --> Unconfigured
       Unconfigured --> Configured : Configure reference-frame
       Configured --> Active : Set location coordinates
       Active --> Expired : System time > valid-until
       Active --> Configured : Clear coordinates
       Expired --> Active : Update valid-until / coordinates
   ```

   ## 5. Specification Context
   [Verbatim specifications, descriptions, and functional goals from the primary normative specification]

   ## 6. Source References
   YANG Schema: [Link to structural schema, e.g., ietf-geo-location@2022-02-11.yang](https://github.com/YangModels/yang/blob/main/standard/ietf/RFC/ietf-geo-location%402022-02-11.yang)
   Normative Specification: [Link to normative specification, e.g., RFC 9179 Geographic Location](https://datatracker.ietf.org/doc/rfc9179/)
   ```

2. **Feature Markdown Template:**
   Every Feature specification file (e.g., `docs/features/feat-[X]-[name].md`) MUST strictly adhere to this format:
   ```markdown
   ---
   title: "Feature [X]: [Feature Title] (Issue #[IssueID])"
   epic: "Epic [Y]: [Parent Epic Title] (Issue #[ParentIssueID])"
   type: "feature"
   issue: [IssueID]
   labels: ["feature", "<protocol-name>"]
   covered-nodes: ["list", "of", "covered", "leaf-nodes", "choices", "cases", "or", "typedefs"]
   ---

   # Feature: Feature [X]: [Feature Title] (Issue #[IssueID])

   [Detailed description of what the feature does, which containers/choices it implements]

   ## 1. Schema Definitions & Constraints
   [Define any custom typedefs (e.g. geographic-coordinate-degree) that apply to the leaves in this feature, followed by every leaf node, container, choice, or case in the grouped feature with its exact types, conditions, units, and defaults]
   
   ### Typedefs
   - `[typedef-name]`: [Typedef description]
     - **Type:** [Base type]
     - **Constraints:** [Precision, fraction-digits, ranges, etc.]

   ### Nodes
   - `[node-name]` ([node-type]): [Description]
     - **Type:** [Exact data type or custom typedef reference]
     - **Default:** [Default value if defined]
     - **Units:** [Units of measurement if defined]
     - **Condition:** [Any 'when' or 'must' clauses, co-dependency constraints, or reference-frame dependencies]

   ## 2. Logical System Integration & UI Capabilities
   - **Logical Data Model:** [How attributes map to the location database system schema]
   - **Logical Processing Rules:** [Validation, normalization, co-dependency rules (e.g. requiring both latitude/longitude if ellipsoid is set) and reference-frame constraints]
   - **Logical UI Representation:** [Required UI inputs, display elements, DMS formatting, and validation error messages]

   ## 3. State Machine and Validation Flow
   [If applicable, include a state diagram or flow chart modeling validation logic and internal component states for this feature]
   ```mermaid
   stateDiagram-v2
       [*] --> Empty
       Empty --> Valid : Input matches schema constraints
       Empty --> Invalid : Input violates schema constraints
       Valid --> Empty : Clear inputs
       Invalid --> Empty : Clear inputs
   ```

   ## 4. BDD Given-When-Then Acceptance Criteria
   [Exhaustive Given-When-Then logical acceptance criteria, covering all schema constraints, input validations, error states, co-dependency validations, and reference-frame dynamic bounds]
   - **Scenario 1: [Scenario Title]**
     - **Given** [initial state]
       **When** [action/trigger]
       **Then** [expected outcome]

   ## 5. Specification Context (Verbatim)
   > [Verbatim normative paragraph or explanation quoted directly from the official specification document]

   ## 6. Source References
   YANG Schema: [Link to structural schema](https://github.com/YangModels/yang/blob/main/standard/ietf/RFC/ietf-geo-location%402022-02-11.yang)
   Normative Specification: [Link to normative specification](https://datatracker.ietf.org/doc/rfc9179/)
   ```

3. **GitHub Label Bootstrapping:** Run `gh label create "epic" --force`, `gh label create "feature" --force`, and `gh label create "<protocol-name>" --force` (where `<protocol-name>` matches the protocol label in your frontmatter).

4. **Feature Generation FIRST:**
   - Execute `gh issue create` for EVERY Feature markdown file first.
   - Example: `gh issue create --title "Feature Title" --body-file docs/features/feat-01.md --label "feature"`
   - **CRITICAL:** Capture the returned GitHub Issue URL/ID from standard output.

5. **Epic Markdown Assembly:**
   - Now that you possess the actual live Issue IDs for all extracted features, inject them into the Epic's Markdown file according to the template above.
   - Replace the placeholder tasklist with the live Issue IDs and absolute URL links pointing to each Feature document on the current branch.

6. **Epic Generation LAST:**
   - Finally, execute `gh issue create` for the Epic markdown file containing the fully resolved tasklist.


