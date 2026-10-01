#!/bin/bash
# Read JSON input from stdin
input=$(cat)

# Extract model display name from JSON using sed/grep (no jq dependency)
model=$(echo "$input" | grep -o '"model"[[:space:]]*:[[:space:]]*{[^}]*"display_name"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"display_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
if [ -z "$model" ]; then
    model=$(echo "$input" | grep -o '"model"[[:space:]]*:[[:space:]]*{[^}]*"id"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
fi
if [ -z "$model" ]; then
    model="unknown"
fi

# Extract context window usage percentage
ctx_pct=$(echo "$input" | grep -o '"used_percentage"[[:space:]]*:[[:space:]]*[0-9]*' | head -1 | sed 's/.*:[[:space:]]*//')
if [ -z "$ctx_pct" ]; then
    ctx_pct="?"
fi

user=$(whoami)
host=$(hostname -s)
pwd_path=$(pwd)

# Check if we're in a git repo
if git rev-parse --git-dir >/dev/null 2>&1; then
    # Get branch or commit info
    branch=$(git branch --show-current 2>/dev/null)
    if [ -z "$branch" ]; then
        # Detached HEAD - show commit hash
        commit=$(git rev-parse --short HEAD 2>/dev/null)
        branch="@${commit}"
    else
        # Truncate long branch names
        if [ ${#branch} -gt 32 ]; then
            branch="${branch:0:12}…${branch: -12}"
        fi
    fi

    # Get git status information
    git_status=""

    # Check for current git action (rebase, merge, etc)
    if [ -d "$(pwd)/.git/rebase-merge" ] || [ -d "$(pwd)/.git/rebase-apply" ]; then
        git_status+=" REBASE"
    elif [ -f "$(pwd)/.git/MERGE_HEAD" ]; then
        git_status+=" MERGE"
    elif [ -f "$(pwd)/.git/CHERRY_PICK_HEAD" ]; then
        git_status+=" CHERRY-PICK"
    elif [ -f "$(pwd)/.git/REVERT_HEAD" ]; then
        git_status+=" REVERT"
    elif [ -f "$(pwd)/.git/BISECT_LOG" ]; then
        git_status+=" BISECT"
    fi

    # Get upstream branch and check if we're behind/ahead
    upstream=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)
    if [ -n "$upstream" ]; then
        # Count commits behind/ahead
        behind=$(git rev-list --count HEAD..$upstream 2>/dev/null)
        ahead=$(git rev-list --count $upstream..HEAD 2>/dev/null)

        if [ "$behind" -gt 0 ]; then
            git_status+=" ⇣${behind}"
        fi
        if [ "$ahead" -gt 0 ]; then
            git_status+=" ⇡${ahead}"
        fi
    fi

    # Check for stashes
    stash_count=$(git stash list 2>/dev/null | wc -l)
    if [ "$stash_count" -gt 0 ]; then
        git_status+=" *${stash_count}"
    fi

    # Get file status counts
    while IFS= read -r line; do
        case "${line:0:2}" in
            "##") ;; # Branch info, skip
            "??") ((untracked++)) ;;
            "!!") ;; # Ignored, skip
            "AA"|"DD"|"AU"|"UD"|"UA"|"DU"|"UU") ((conflicted++)) ;;
            *)
                # Check if staged (first char not space/?)
                if [[ "${line:0:1}" != " " && "${line:0:1}" != "?" ]]; then
                    ((staged++))
                fi
                # Check if unstaged (second char not space/?)
                if [[ "${line:1:1}" != " " && "${line:1:1}" != "?" ]]; then
                    ((unstaged++))
                fi
                ;;
        esac
    done < <(git status --porcelain 2>/dev/null)

    # Add file status indicators
    if [ "${conflicted:-0}" -gt 0 ]; then
        git_status+=" ~${conflicted}"
    fi
    if [ "${staged:-0}" -gt 0 ]; then
        git_status+=" +${staged}"
    fi
    if [ "${unstaged:-0}" -gt 0 ]; then
        git_status+=" !${unstaged}"
    fi
    if [ "${untracked:-0}" -gt 0 ]; then
        git_status+=" ?${untracked}"
    fi

    # Check if last commit message contains "wip" or "WIP"
    last_commit=$(git log -1 --pretty=%s 2>/dev/null)
    if [[ "$last_commit" =~ (^|[^[:alnum:]])(wip|WIP)($|[^[:alnum:]]) ]]; then
        git_status+=" wip"
    fi

    # Build the prompt with git info
    printf "\e[32m%s@%s\e[0m:\e[34m%s\e[0m (\e[33m\ue0a0 %s%s\e[0m) [\e[36m%s\e[0m] \e[35mctx:%s%%\e[0m" \
        "$user" "$host" "$pwd_path" "$branch" "$git_status" "$model" "$ctx_pct"
else
    # Not in a git repo
    printf "\e[32m%s@%s\e[0m:\e[34m%s\e[0m [\e[36m%s\e[0m] \e[35mctx:%s%%\e[0m" \
        "$user" "$host" "$pwd_path" "$model" "$ctx_pct"
fi