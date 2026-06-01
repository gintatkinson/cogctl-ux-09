#!/usr/bin/env python3
import os
import re
import subprocess
import json
import sys

def normalize_title(title):
    if not title:
        return ""
    # Strip quotes and leading/trailing whitespace
    title = title.strip().strip('"\'')
    # Strip (Issue #...) suffix
    title = re.sub(r'\s*\(\s*Issue\s*#?\s*\d+\s*\)', '', title, flags=re.IGNORECASE)
    # Strip common prefixes (e.g., epic-01:, feat-02:, us-03:, us-10:, uc-04:, etc.)
    title = re.sub(r'^(epic|feat|us|uc|feature|user[- ]story|use[- ]case)[s]?[- ]*\d*[- ]*[:\-]\s*', '', title, flags=re.IGNORECASE)
    # Strip any remaining punctuation and normalize spacing
    title = re.sub(r'[^\w\s]', '', title)
    title = " ".join(title.split())
    return title.lower()

def extract_title(filepath):
    try:
        with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
            content = f.read(2048)  # Read first 2KB
        
        # Try finding title in YAML frontmatter
        title_match = re.search(r'^title:\s*(["\']?)(.*?)\1\s*$', content, re.MULTILINE)
        if title_match:
            return title_match.group(2).strip()
            
        # Fallback to # H1 title
        h1_match = re.search(r'^#\s+(.*?)$', content, re.MULTILINE)
        if h1_match:
            return h1_match.group(1).strip()
    except Exception as e:
        print(f"Error reading title from {filepath}: {e}")
    return None

def get_all_issues():
    print("Fetching active and closed issues from GitHub...")
    # Fetch up to 1000 issues covering all states
    cmd = ["gh", "issue", "list", "--limit", "1000", "--state", "all", "--json", "number,title,state,labels"]
    res = subprocess.run(cmd, capture_output=True, text=True)
    if res.returncode != 0:
        raise Exception(f"Failed to fetch issues: {res.stderr.strip()}")
    return json.loads(res.stdout)

def parse_markdown_file(filepath):
    try:
        with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
            content = f.read()
        
        # Parse frontmatter
        title_match = re.search(r'^title:\s*(["\']?)(.*?)\1\s*$', content, re.MULTILINE)
        issue_match = re.search(r'^issue:\s*(\d+)', content, re.MULTILINE)
        type_match = re.search(r'^type:\s*(["\']?)(.*?)\1\s*$', content, re.MULTILINE)
        
        title = title_match.group(2).strip() if title_match else None
        issue = int(issue_match.group(1)) if issue_match else None
        doc_type = type_match.group(2).strip() if type_match else None
        
        # Parse checklist issue links: e.g. - [ ] #123 or - [x] #123
        dep_issues = []
        matches = re.findall(r'-\s*\[[ xX]\]\s*#(\d+)\b', content)
        for m in matches:
            dep_issues.append(int(m))
            
        return {
            "title": title,
            "issue": issue,
            "type": doc_type,
            "dependencies": dep_issues,
            "filepath": filepath
        }
    except Exception as e:
        print(f"Error parsing {filepath}: {e}")
        return None

def get_github_repo_url(cwd=None):
    try:
        url = subprocess.check_output(["git", "remote", "get-url", "origin"], cwd=cwd, text=True).strip()
        if url.startswith("git@"):
            url = url.replace(":", "/").replace("git@", "https://")
        if url.endswith(".git"):
            url = url[:-4]
        return url
    except Exception:
        return "https://github.com/gintatkinson/cogctl-ux-09"

def get_current_branch(cwd=None):
    try:
        return subprocess.check_output(["git", "rev-parse", "--abbrev-ref", "HEAD"], cwd=cwd, text=True).strip()
    except Exception:
        return "main"

def inject_associated_section(content, associated_ucs, associated_uss, repo_url, branch, project_root):
    # Format the lists
    uc_lines = []
    for uc in sorted(associated_ucs, key=lambda x: x["issue"]):
        rel_path = os.path.relpath(uc["filepath"], project_root)
        url = f"{repo_url}/blob/{branch}/{rel_path}"
        uc_lines.append(f"- [ ] #{uc['issue']} - [{uc['title']}]({url})")
        
    us_lines = []
    for us in sorted(associated_uss, key=lambda x: x["issue"]):
        rel_path = os.path.relpath(us["filepath"], project_root)
        url = f"{repo_url}/blob/{branch}/{rel_path}"
        us_lines.append(f"- [ ] #{us['issue']} - [{us['title']}]({url})")

    # Combine into the section text
    section_title = "## Associated Use Cases & User Stories"
    section_body = f"\n{section_title}\n"
    if uc_lines:
        section_body += "\n### Associated Use Cases\n" + "\n".join(uc_lines) + "\n"
    if us_lines:
        section_body += "\n### Associated User Stories\n" + "\n".join(us_lines) + "\n"
    
    # Check if section already exists
    existing_match = re.search(r'^##\s+Associated Use Cases\s*&\s*User Stories.*?(?=\n##\s|\Z)', content, re.DOTALL | re.MULTILINE | re.IGNORECASE)
    if existing_match:
        content = content.replace(existing_match.group(0), section_body.strip())
    else:
        req_match = re.search(r'^##\s+2\.\s+Requirements\s*&\s*Checklist.*?(?=\n##\s|\Z)', content, re.DOTALL | re.MULTILINE | re.IGNORECASE)
        if req_match:
            content = content.replace(req_match.group(0), req_match.group(0).rstrip() + "\n" + section_body)
        else:
            content = content.rstrip() + "\n\n" + section_body
            
    return content


def update_checklist_in_file(filepath, issue_dict):
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()

    # Find checkboxes matching: - [ ] #123, - [x] #123, or - [X] #123
    pattern = r"(-\s*\[([ xX])\]\s*(?:#|#\[|\#\s*)(\d+)\b)"
    
    updated_content = content
    all_deps_closed = True
    has_deps = False
    
    matches = re.findall(pattern, content)
    for full_match, current_state, dep_num_str in matches:
        has_deps = True
        dep_num = int(dep_num_str)
        dep_issue = issue_dict.get(dep_num)
        
        # Determine target state based on remote GitHub issue state
        target_state = "x" if (dep_issue and dep_issue["state"].upper() == "CLOSED") else " "
        
        if current_state != target_state:
            # Replace exactly the checkbox bracket segment
            old_item = full_match
            new_item = old_item.replace(f"[{current_state}]", f"[{target_state}]")
            updated_content = updated_content.replace(old_item, new_item, 1)
            print(f"  [Checklist] Synced dependency #{dep_num} in {os.path.basename(filepath)} to '[{target_state}]'")
            
        if target_state == " ":
            all_deps_closed = False

    if updated_content != content:
        with open(filepath, "w", encoding="utf-8") as f:
            f.write(updated_content)
            
    return updated_content, (has_deps and all_deps_closed)

def sync_issue_body_to_github(issue_num, filepath, issue_type="Issue"):
    print(f"  [{issue_type} Sync] Syncing #{issue_num} body to GitHub...")
    temp_path = filepath + ".tmp_body"
    try:
        with open(filepath, "r", encoding="utf-8") as sf:
            content = sf.read()
        
        # Prevent GraphQL: Body is too long (updateIssue) errors (limit is 65536 characters)
        if len(content) > 60000:
            trunc_index = content.rfind("\n", 0, 60000)
            if trunc_index == -1:
                trunc_index = 60000
            
            try:
                project_root = subprocess.check_output(["git", "rev-parse", "--show-toplevel"], text=True).strip()
            except Exception:
                project_root = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
            rel_path = os.path.relpath(filepath, project_root)
            
            content = content[:trunc_index] + (
                f"\n\n---\n> [!NOTE]\n"
                f"> This issue body has been truncated because it exceeds GitHub's size limit of 65,536 characters.\n"
                f"> Please refer to the full specification file in the repository at `{rel_path}` for the complete details (such as exhaustive auto-generated schema tables).\n"
            )
            
        with open(temp_path, "w", encoding="utf-8") as tf:
            tf.write(content)
        
        subprocess.run(["gh", "issue", "edit", str(issue_num), "--body-file", temp_path], check=True, capture_output=True)
    except Exception as e:
        print(f"  [Error] Failed to sync #{issue_num} body: {e}")
    finally:
        if os.path.exists(temp_path):
            os.remove(temp_path)

def close_issue_on_github(issue_num, comment):
    print(f"  [Close Issue] Closing issue #{issue_num} on GitHub...")
    try:
        subprocess.run(["gh", "issue", "close", str(issue_num), "--comment", comment], check=True, capture_output=True)
    except Exception as e:
        print(f"  [Error] Failed to close issue #{issue_num}: {e}")

def main():
    # Verify GitHub CLI authentication
    try:
        issues = get_all_issues()
    except Exception as e:
        print(f"Error fetching GitHub issues: {e}")
        print("Please ensure gh CLI is authenticated and configured.")
        sys.exit(1)

    # Convert to issue lookup dictionary by issue number
    issue_dict = {issue["number"]: issue for issue in issues}

    # Map normalized titles to issue numbers, segregated by labels
    epic_titles = {}
    story_titles = {}
    usecase_titles = {}
    feature_titles = {}

    for num, issue in issue_dict.items():
        norm_title = normalize_title(issue["title"])
        labels = [l["name"].lower() for l in issue.get("labels", [])]
        
        if "epic" in labels:
            epic_titles[norm_title] = num
        elif "user-story" in labels:
            story_titles[norm_title] = num
        elif "use-case" in labels:
            usecase_titles[norm_title] = num
        elif "feature" in labels:
            feature_titles[norm_title] = num

    # Locate the docs directory relative to git root
    try:
        project_root = subprocess.check_output(["git", "rev-parse", "--show-toplevel"], text=True).strip()
    except Exception:
        project_root = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
    docs_dir = os.path.join(project_root, "docs")
    if not os.path.exists(docs_dir):
        print(f"Docs directory not found at: {docs_dir}")
        sys.exit(1)

    print(f"Scanning backlog files in {docs_dir}...")

    # Build Epic-to-UC/US relationship maps and inject them into Epic markdown files
    epics = {}
    epics_dir = os.path.join(docs_dir, "epics")
    if os.path.exists(epics_dir):
        for filename in os.listdir(epics_dir):
            if filename.endswith(".md"):
                p = parse_markdown_file(os.path.join(epics_dir, filename))
                if p and p["issue"]:
                    epics[p["issue"]] = p

    features = {}
    feature_to_epic = {}
    features_dir = os.path.join(docs_dir, "features")
    if os.path.exists(features_dir):
        for filename in os.listdir(features_dir):
            if filename.endswith(".md"):
                p = parse_markdown_file(os.path.join(features_dir, filename))
                if p and p["issue"]:
                    features[p["issue"]] = p
                    for epic_issue, epic_data in epics.items():
                        if p["issue"] in epic_data["dependencies"]:
                            feature_to_epic[p["issue"]] = epic_issue

    user_stories = {}
    story_to_epics = {}
    stories_dir = os.path.join(docs_dir, "user-stories")
    if os.path.exists(stories_dir):
        for filename in os.listdir(stories_dir):
            if filename.endswith(".md"):
                p = parse_markdown_file(os.path.join(stories_dir, filename))
                if p and p["issue"]:
                    user_stories[p["issue"]] = p
                    associated = set()
                    for feat in p["dependencies"]:
                        if feat in feature_to_epic:
                            associated.add(feature_to_epic[feat])
                    story_to_epics[p["issue"]] = associated

    use_cases = {}
    case_to_epics = {}
    usecases_dir = os.path.join(docs_dir, "use-cases")
    if os.path.exists(usecases_dir):
        for filename in os.listdir(usecases_dir):
            if filename.endswith(".md"):
                p = parse_markdown_file(os.path.join(usecases_dir, filename))
                if p and p["issue"]:
                    use_cases[p["issue"]] = p
                    associated = set()
                    for us in p["dependencies"]:
                        if us in story_to_epics:
                            associated.update(story_to_epics[us])
                    case_to_epics[p["issue"]] = associated

    repo_url = get_github_repo_url(cwd=docs_dir)
    branch = get_current_branch(cwd=docs_dir)

    for epic_issue, epic_data in epics.items():
        associated_uss = [user_stories[us] for us, epics_set in story_to_epics.items() if epic_issue in epics_set]
        associated_ucs = [use_cases[uc] for uc, epics_set in case_to_epics.items() if epic_issue in epics_set]
        
        with open(epic_data["filepath"], "r", encoding="utf-8") as f:
            content = f.read()
            
        new_content = inject_associated_section(content, associated_ucs, associated_uss, repo_url, branch, project_root)
        if new_content != content:
            with open(epic_data["filepath"], "w", encoding="utf-8") as f:
                f.write(new_content)
            print(f"  [Epic Injection] Injected associated UCs/USs into {os.path.basename(epic_data['filepath'])}")


    # Process Epics
    epics_dir = os.path.join(docs_dir, "epics")
    if os.path.exists(epics_dir):
        for filename in sorted(os.listdir(epics_dir)):
            if not filename.endswith(".md"):
                continue
            filepath = os.path.join(epics_dir, filename)
            title = extract_title(filepath)
            if not title:
                continue
            
            norm = normalize_title(title)
            issue_num = epic_titles.get(norm)
            if issue_num:
                updated_content, completed = update_checklist_in_file(filepath, issue_dict)
                is_open = issue_dict[issue_num]["state"].upper() == "OPEN"
                if is_open:
                    # Sync to keep checkbox states updated on GitHub UI
                    sync_issue_body_to_github(issue_num, filepath, issue_type="Epic")
                    if completed:
                        close_issue_on_github(
                            issue_num, 
                            "Epic completed. All constituent features successfully delivered and verified."
                        )
                        issue_dict[issue_num]["state"] = "CLOSED"
            else:
                print(f"Warning: No GitHub Epic issue found matching: '{title}'")

    # Process Features
    features_dir = os.path.join(docs_dir, "features")
    if os.path.exists(features_dir):
        for filename in sorted(os.listdir(features_dir)):
            if not filename.endswith(".md"):
                continue
            filepath = os.path.join(features_dir, filename)
            title = extract_title(filepath)
            if not title:
                continue
            
            norm = normalize_title(title)
            issue_num = feature_titles.get(norm)
            if issue_num:
                is_open = issue_dict[issue_num]["state"].upper() == "OPEN"
                if is_open:
                    # Sync to keep feature definition/acceptance criteria updated on GitHub UI
                    sync_issue_body_to_github(issue_num, filepath, issue_type="Feature")
            else:
                print(f"Warning: No GitHub Feature issue found matching: '{title}'")

    # Process User Stories
    stories_dir = os.path.join(docs_dir, "user-stories")
    if os.path.exists(stories_dir):
        for filename in sorted(os.listdir(stories_dir)):
            if not filename.endswith(".md"):
                continue
            filepath = os.path.join(stories_dir, filename)
            title = extract_title(filepath)
            if not title:
                continue
            
            norm = normalize_title(title)
            issue_num = story_titles.get(norm)
            if issue_num:
                _, completed = update_checklist_in_file(filepath, issue_dict)
                is_open = issue_dict[issue_num]["state"].upper() == "OPEN"
                if completed and is_open:
                    close_issue_on_github(
                        issue_num,
                        f"Resolved. All dependent features/tasks for BDD scenario '{title}' have been completed and verified."
                    )
                    issue_dict[issue_num]["state"] = "CLOSED"
            else:
                print(f"Warning: No GitHub User Story issue found matching: '{title}'")

    # Process Use Cases
    usecases_dir = os.path.join(docs_dir, "use-cases")
    if os.path.exists(usecases_dir):
        for filename in sorted(os.listdir(usecases_dir)):
            if not filename.endswith(".md"):
                continue
            filepath = os.path.join(usecases_dir, filename)
            title = extract_title(filepath)
            if not title:
                continue
            
            norm = normalize_title(title)
            issue_num = usecase_titles.get(norm)
            if issue_num:
                _, completed = update_checklist_in_file(filepath, issue_dict)
                is_open = issue_dict[issue_num]["state"].upper() == "OPEN"
                if completed and is_open:
                    close_issue_on_github(
                        issue_num,
                        f"Resolved. All dependent user stories and features for use case '{title}' are completed."
                    )
                    issue_dict[issue_num]["state"] = "CLOSED"
            else:
                print(f"Warning: No GitHub Use Case issue found matching: '{title}'")

    print("Backlog reconciliation complete.")

if __name__ == "__main__":
    main()
