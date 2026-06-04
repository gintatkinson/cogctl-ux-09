#!/usr/bin/env python3
import os
import re
import subprocess
import sys

def parse_yang_file(filepath):
    """
    Parses a YANG file and extracts all defined names (typedefs, containers, lists, leaves, choices, cases, identities).
    """
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()

    # Extract module name
    module_match = re.search(r'\bmodule\s+([a-zA-Z0-9_\-]+)', content)
    if not module_match:
        return None, set(), {}

    module_name = module_match.group(1)

    # Clean the content by removing comments and quoted strings (descriptions/references) in a single pass
    pattern = re.compile(
        r'(/\*.*?\*/)|(//.*?\n)|("([^"\\]|\\.)*")|(\'[^\']*\')',
        re.DOTALL
    )
    
    def replacer(match):
        if match.group(3) is not None:
            return '""'
        elif match.group(5) is not None:
            return "''"
        else:
            return '\n'

    clean_content = pattern.sub(replacer, content)

    # Patterns to match definitions
    patterns = {
        "typedef": r'\btypedef\s+([a-zA-Z0-9_\-.]+)',
        "leaf": r'\bleaf\s+([a-zA-Z0-9_\-.]+)',
        "container": r'\bcontainer\s+([a-zA-Z0-9_\-.]+)',
        "list": r'\blist\s+([a-zA-Z0-9_\-.]+)',
        "choice": r'\bchoice\s+([a-zA-Z0-9_\-.]+)',
        "case": r'\bcase\s+([a-zA-Z0-9_\-.]+)',
        "identity": r'\bidentity\s+([a-zA-Z0-9_\-.]+)'
    }

    definitions = set()
    categorized_defs = {k: set() for k in patterns.keys()}
    for key, pattern_str in patterns.items():
        for match in re.finditer(pattern_str, clean_content):
            name = match.group(1)
            # Filter out any accidental matches with common keywords if matched
            if name not in {"description", "reference", "organization", "contact", "revision", "import", "prefix", "namespace", "yang-version"}:
                definitions.add(name)
                categorized_defs[key].add(name)

    return module_name, definitions, categorized_defs

def parse_covered_nodes(content):
    """
    Parses the covered-nodes list from the YAML frontmatter of a markdown file.
    """
    frontmatter_match = re.match(r"^---\s*\n(.*?)\n---\s*\n", content, re.DOTALL)
    if not frontmatter_match:
        return []
    
    frontmatter = frontmatter_match.group(1)
    
    # Check for inline list e.g. covered-nodes: [a, b, c]
    inline_match = re.search(r"covered-nodes:\s*\[(.*?)\]", frontmatter)
    if inline_match:
        return [n.strip().strip('"').strip("'") for n in inline_match.group(1).split(",") if n.strip()]
        
    # Check for block list
    block_match = re.search(r"covered-nodes:\s*\n((?:\s*-\s*\S+\n?)+)", frontmatter)
    if block_match:
        lines = block_match.group(1).splitlines()
        nodes = []
        for line in lines:
            line_match = re.search(r"-\s*(\S+)", line)
            if line_match:
                nodes.append(line_match.group(1).strip().strip('"').strip("'"))
        return nodes
        
    return []

def pre_scan_features(features_dir):
    """
    Scrapes metadata from the headers of all feature files quickly without loading full contents.
    """
    features = []
    if not os.path.exists(features_dir):
        return features

    for filename in os.listdir(features_dir):
        if not filename.endswith(".md"):
            continue
        filepath = os.path.join(features_dir, filename)
        try:
            with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
                head = f.read(2048)  # Read first 2KB for frontmatter

            labels = []
            status = None
            frontmatter_match = re.match(r"^---\s*\n(.*?)\n---\s*\n", head, re.DOTALL)
            if frontmatter_match:
                frontmatter_text = frontmatter_match.group(1)
                for line in frontmatter_text.splitlines():
                    if line.startswith("labels:"):
                        labels_match = re.search(r"\[(.*?)\]", line)
                        if labels_match:
                            labels = [lbl.strip().strip('"').strip("'") for lbl in labels_match.group(1).split(",")]
                    elif line.startswith("status:"):
                        status = line.split(":", 1)[1].strip().strip('"').strip("'")
            
            features.append({
                "filename": filename,
                "filepath": filepath,
                "labels": labels,
                "status": status,
                "content": None,
                "covered_nodes": []
            })
        except Exception:
            pass
    return features

def load_feature_details(feature_meta):
    """
    Loads full content and parses covered-nodes on-demand.
    """
    try:
        with open(feature_meta["filepath"], "r", encoding="utf-8") as f:
            content = f.read()
        feature_meta["content"] = content
        feature_meta["covered_nodes"] = parse_covered_nodes(content)
        return True
    except Exception as e:
        print(f"Error loading {feature_meta['filename']}: {e}")
        return False

def get_modified_files(workspace_dir):
    """
    Returns a set of files modified in the working tree, index, or HEAD commit.
    """
    modified = set()
    try:
        # Working tree & staging area changes
        status_output = subprocess.check_output(["git", "status", "--porcelain"], text=True, cwd=workspace_dir)
        for line in status_output.splitlines():
            if len(line) > 3:
                filepath = line[3:].strip()
                modified.add(os.path.normpath(os.path.join(workspace_dir, filepath)))
                
        # If no changes in working tree, check HEAD commit changes
        if not modified:
            diff_output = subprocess.check_output(["git", "diff", "--name-only", "HEAD~1...HEAD"], text=True, cwd=workspace_dir)
            for line in diff_output.splitlines():
                if line.strip():
                    modified.add(os.path.normpath(os.path.join(workspace_dir, line.strip())))
    except Exception as e:
        print(f"Warning: Git change detection failed: {e}")
    return modified

def audit_epics_structure(workspace_dir, active_epics=None):
    """
    Audits epic files for correct header structures.
    If active_epics is provided, restricts audit to those files.
    """
    epics_dir = os.path.join(workspace_dir, "docs", "epics")
    errors = {}
    if not os.path.exists(epics_dir):
        return errors

    required_headers = [
        (r"^## 1\.\s+Context\b", "## 1. Context"),
        (r"^## 2\.\s+Requirements\s+&\s+Checklist\b", "## 2. Requirements & Checklist"),
        (r"^## 3\.\s+Architecture\s+and\s+System\s+Interaction\s+Diagrams\b", "## 3. Architecture and System Interaction Diagrams"),
        (r"^## 4\.\s+(State\s+Machine\s+Definitions|Verification\s+and\s+Validation\s+Plan)\b", "## 4. State Machine Definitions / Verification and Validation Plan"),
        (r"^## 5\.\s+Specification\s+Context\b", "## 5. Specification Context"),
        (r"^## 6\.\s+Source\s+References\b", "## 6. Source References")
    ]

    files_to_check = []
    if active_epics is not None:
        files_to_check = [os.path.basename(p) for p in active_epics]
    else:
        files_to_check = [f for f in os.listdir(epics_dir) if f.endswith(".md")]

    for filename in files_to_check:
        filepath = os.path.join(epics_dir, filename)
        if not os.path.exists(filepath):
            continue
        try:
            with open(filepath, "r", encoding="utf-8") as f:
                content = f.read()
        except Exception as e:
            errors[filename] = [f"Failed to read file: {e}"]
            continue

        missing = []
        for pattern, header_name in required_headers:
            if not re.search(pattern, content, re.MULTILINE):
                missing.append(header_name)
        
        if missing:
            errors[filename] = missing
            
    return errors

def main():
    try:
        workspace_dir = subprocess.check_output(["git", "rev-parse", "--show-toplevel"], text=True).strip()
    except Exception:
        workspace_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))

    # Determine command line mode
    full_mode = "--full" in sys.argv
    if full_mode:
        sys.argv.remove("--full")
    target_files = [os.path.normpath(os.path.abspath(f)) for f in sys.argv[1:] if not f.startswith("-")]

    yang_dir = None
    for root, dirs, files in os.walk(workspace_dir):
        if ".git" in dirs:
            dirs.remove(".git")
        if "yang" in dirs:
            yang_dir = os.path.join(root, "yang")
            break
            
    if not yang_dir:
        yang_dir = os.path.join(workspace_dir, "yang")

    features_dir = os.path.join(workspace_dir, "docs", "features")

    if not os.path.exists(yang_dir):
        print(f"Error: YANG directory not found at {yang_dir}")
        sys.exit(1)

    print("=== Model Coverage Parity Audit ===")
    print(f"Scanning YANG schemas in: {yang_dir}")
    print(f"Scanning feature specifications in: {features_dir}\n")

    # Fast pre-scan of all feature metadata
    all_features_meta = pre_scan_features(features_dir)

    # Determine targets for incremental mode
    active_modules = None
    active_features = None
    active_epics = None

    if not full_mode:
        modified = set()
        if target_files:
            modified = set(target_files)
        else:
            modified = get_modified_files(workspace_dir)

        if modified:
            active_modules = set()
            active_features = set()
            active_epics = set()

            for filepath in modified:
                if filepath.endswith(".yang"):
                    try:
                        module_name, _, _ = parse_yang_file(filepath)
                        if module_name:
                            active_modules.add(module_name)
                    except Exception:
                        pass
                elif filepath.endswith(".md"):
                    norm_path = filepath.replace("\\", "/")
                    if "docs/epics/" in norm_path:
                        active_epics.add(filepath)
                    elif "docs/features/" in norm_path:
                        active_features.add(os.path.basename(filepath))

            # Expand active modules based on modified features
            for f in all_features_meta:
                if f["filename"] in active_features:
                    for lbl in f["labels"]:
                        active_modules.add(lbl)

            # If no active changes were identified, run verification on nothing and succeed early
            if not active_modules and not active_epics:
                print("No schema or feature modifications detected. Incremental verification skipped.")
                print("Run with --full to force a full validation scan.")
                sys.exit(0)

            print(f"Incremental mode active. Verifying modules: {', '.join(sorted(active_modules)) if active_modules else 'None'}")
            if active_epics:
                print(f"Verifying Epic structures: {', '.join([os.path.basename(e) for e in active_epics])}")
            print()

    # 1. Parse required YANG modules
    modules = {}
    categorized_modules = {}
    for filename in os.listdir(yang_dir):
        if not filename.endswith(".yang"):
            continue
        filepath = os.path.join(yang_dir, filename)
        
        # In incremental mode, skip parsing YANG files that aren't in active_modules
        if active_modules is not None:
            # We must inspect the module name without fully parsing if possible, or parse and filter
            try:
                module_name, definitions, cat_defs = parse_yang_file(filepath)
                if module_name and module_name in active_modules:
                    modules[module_name] = definitions
                    categorized_modules[module_name] = cat_defs
            except Exception:
                pass
        else:
            try:
                module_name, definitions, cat_defs = parse_yang_file(filepath)
                if module_name:
                    modules[module_name] = definitions
                    categorized_modules[module_name] = cat_defs
            except Exception as e:
                print(f"Warning: Failed to parse YANG file {filename}: {e}")

    # Load and parse content for relevant feature files
    features = []
    for f_meta in all_features_meta:
        # Load details if:
        # - Full mode is active
        # - Or the feature matches active_features
        # - Or the feature shares a label with active_modules
        should_load = (
            full_mode or
            (active_features and f_meta["filename"] in active_features) or
            (active_modules and any(lbl in active_modules for lbl in f_meta["labels"]))
        )
        if should_load:
            if load_feature_details(f_meta):
                features.append(f_meta)

    print(f"Loaded {len(features)} feature specifications for verification.\n")

    # Audit design/solution document existence for relevant features
    designs_dir = os.path.join(workspace_dir, "docs", "designs")
    design_files = []
    if os.path.exists(designs_dir):
        design_files = [f for f in os.listdir(designs_dir) if f.endswith(".md")]

    missing_designs = []
    for f in features:
        if f.get("status") != "completed":
            continue
        feat_match = re.search(r"feat-(\d+)", f["filename"])
        if not feat_match:
            continue
        feat_num = int(feat_match.group(1))
        
        found = False
        for df in design_files:
            df_match = re.search(r"feat-(\d+)-solution", df)
            if df_match and int(df_match.group(1)) == feat_num:
                found = True
                break
        
        if not found:
            missing_designs.append((f["filename"], f"feat-{feat_num}-solution.md"))

    # Audit coverage per module
    total_defined = 0
    total_covered = 0
    coverage_gaps = {}
    semantic_violations = {}
    invalid_declarations = {}

    for module_name, definitions in sorted(modules.items()):
        cat_defs = categorized_modules.get(module_name, {})
        matching_features = [f for f in features if module_name in f["labels"]]
        
        if not matching_features:
            coverage_gaps[module_name] = sorted(list(definitions))
            semantic_violations[module_name] = [f"YANG module '{module_name}' is in the repository but has no matching feature specifications in labels."]
            total_defined += len(definitions)
            continue

        combined_text = "\n".join([f["content"] for f in matching_features])
        declared_nodes = []
        for f in matching_features:
            for node in f["covered_nodes"]:
                declared_nodes.append((node, f["filename"]))

        invalid_nodes = []
        for node, filename in declared_nodes:
            if node not in definitions:
                invalid_nodes.append(f"'{node}' (declared in {filename})")
        if invalid_nodes:
            invalid_declarations[module_name] = invalid_nodes

        declared_set = {node for node, filename in declared_nodes}
        missing = []
        for name in sorted(definitions):
            if name not in declared_set:
                missing.append(name)
            else:
                pattern = rf"(?<![a-zA-Z0-9_\-]){re.escape(name)}(?![a-zA-Z0-9_\-])"
                if not re.search(pattern, combined_text):
                    missing.append(f"{name} (declared in frontmatter but missing/undocumented in markdown body)")

        module_violations = []

        # Rule 1: Typedef completeness
        for td in sorted(cat_defs.get("typedef", [])):
            if td in declared_set:
                td_pattern = rf"(?i)###\s+Typedefs.*?(?<![a-zA-Z0-9_\-]){re.escape(td)}(?![a-zA-Z0-9_\-])"
                if not re.search(td_pattern, combined_text, re.DOTALL):
                    module_violations.append(f"Typedef '{td}' is declared in coverage but lacks detailed mapping under a '### Typedefs' header in feature body.")

        # Rule 2: Choice/Case Mutual Exclusivity and Co-dependency
        for choice_node in sorted(cat_defs.get("choice", [])):
            if choice_node in declared_set:
                choice_patterns = [
                    r"(?i)mutually\s+exclusive",
                    r"(?i)mutual\s+exclusivity",
                    r"(?i)exactly\s+one",
                    r"(?i)exclusive\s+inputs",
                    r"(?i)choice"
                ]
                if not any(re.search(pat, combined_text) for pat in choice_patterns):
                    module_violations.append(f"Choice '{choice_node}' lacks explicit mutual exclusivity / choice selection validation criteria in feature body.")

        # Rule 3: Conditional Constraints & Co-dependencies (Abstract)
        module_file = os.path.join(yang_dir, f"{module_name}.yang")
        if not os.path.exists(module_file):
            for fn in os.listdir(yang_dir):
                if fn.endswith(".yang"):
                    fp = os.path.join(yang_dir, fn)
                    try:
                        with open(fp, "r", encoding="utf-8") as f:
                            if f"module {module_name}" in f.read():
                                module_file = fp
                                break
                    except Exception:
                        pass

        if os.path.exists(module_file):
            try:
                with open(module_file, "r", encoding="utf-8") as f:
                    yang_content = f.read()
                
                if "must" in yang_content or "when" in yang_content:
                    constraint_patterns = [
                        r"(?i)must",
                        r"(?i)when",
                        r"(?i)condition",
                        r"(?i)constraint",
                        r"(?i)co-dependency",
                        r"(?i)co-dependent",
                        r"(?i)dependent",
                        r"(?i)validation\s+rule"
                    ]
                    if not any(re.search(pat, combined_text) for pat in constraint_patterns):
                        module_violations.append(f"YANG module '{module_name}' defines conditional constraints (must/when), but the feature specifications lack conditional validation rules or dependency criteria in the body.")
            except Exception as e:
                module_violations.append(f"Failed to read YANG file for conditional validation audit: {e}")

        if module_violations:
            semantic_violations[module_name] = module_violations

        module_defined = len(definitions)
        module_covered = module_defined - len(missing)
        
        total_defined += module_defined
        total_covered += module_covered

        if missing:
            coverage_gaps[module_name] = missing

        if module_defined > 0:
            pct = (module_covered / module_defined) * 100
            print(f"Module '{module_name}': {module_covered}/{module_defined} nodes covered ({pct:.2f}%)")
            if module_violations:
                print(f"  [!] {len(module_violations)} semantic validation failures found.")
            if invalid_nodes:
                print(f"  [!] {len(invalid_nodes)} invalid node declarations found.")
        else:
            print(f"Module '{module_name}': 0 nodes defined")

    print("\n=== Audit Summary ===")
    if total_defined > 0:
        overall_pct = (total_covered / total_defined) * 100
        print(f"Total Schema Nodes Defined: {total_defined}")
        print(f"Total Schema Nodes Covered: {total_covered}")
        print(f"Overall Model Coverage:     {overall_pct:.2f}%")
    else:
        print("No target schema nodes found to verify in active modules.")
        if active_modules:
            sys.exit(1)
        else:
            print("Audit completed successfully (no active modules selected).")
            sys.exit(0)

    # Restrict epic structure audit in incremental mode
    epic_errors = audit_epics_structure(workspace_dir, active_epics)

    if coverage_gaps or semantic_violations or invalid_declarations or missing_designs or epic_errors:
        if coverage_gaps:
            print("\n[!] Coverage Gaps Identified:")
            for module_name, missing in sorted(coverage_gaps.items()):
                print(f"  Module '{module_name}' is missing {len(missing)} nodes:")
                print(f"    Missing: {', '.join(missing)}")
        if semantic_violations:
            print("\n[!] Semantic Requirements Parity Gaps Identified:")
            for module_name, violations in sorted(semantic_violations.items()):
                print(f"  Module '{module_name}' failed {len(violations)} requirements checks:")
                for viol in violations:
                    print(f"    - {viol}")
        if invalid_declarations:
            print("\n[!] Invalid Frontmatter Node Declarations Identified:")
            for module_name, invalids in sorted(invalid_declarations.items()):
                print(f"  Module '{module_name}' has unrecognized nodes declared:")
                for inv in invalids:
                    print(f"    - {inv}")
        if missing_designs:
            print("\n[!] Design / Solution Walkthrough Gaps Identified:")
            for feat_file, design_file in missing_designs:
                print(f"  Feature spec '{feat_file}' is missing a corresponding solution document (e.g. '{design_file}') under 'docs/designs/'")
        if epic_errors:
            print("\n[!] Epic Document Structure Violations Identified:")
            for filename, missing in sorted(epic_errors.items()):
                print(f"  Epic file '{filename}' is missing mandated sections:")
                for m in missing:
                    print(f"    - {m}")
        print("\nError: Parity validation failed.")
        sys.exit(1)
    else:
        print("\nSuccess: 100% model coverage, semantic requirements, epic structures, and design solution documents verified across all specification files.")
        sys.exit(0)

if __name__ == "__main__":
    main()
