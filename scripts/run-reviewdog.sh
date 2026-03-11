#!/bin/bash
set -eo pipefail

# Default values
REPORTER="${REPORTER:-local}"
LEVEL="${LEVEL:-warning}"
FILTER_MODE="${FILTER_MODE:-added}"
FAIL_ON_ERROR="${FAIL_ON_ERROR:-false}"

# Help message
show_help() {
    cat << EOF
Usage: run-reviewdog.sh [OPTIONS]

Run Brakeman with reviewdog for code review on GitHub or GitLab.

OPTIONS:
    -h, --help              Show this help message
    -r, --reporter REPORTER Set reporter (github-pr-review, github-check, gitlab-mr-discussion, gitlab-mr-commit, local)
    -l, --level LEVEL       Set level (info, warning, error)
    -f, --filter-mode MODE  Set filter mode (added, diff_context, file, nofilter)
    --fail-on-error         Exit with error code if reviewdog finds errors
    --gitlab-api URL        GitLab API URL (for private GitLab instances)
    --token TOKEN           Access token for GitHub/GitLab API

ENVIRONMENT VARIABLES:
    REVIEWDOG_GITHUB_API_TOKEN  GitHub access token
    REVIEWDOG_GITLAB_API_TOKEN  GitLab access token
    CI_API_V4_URL               GitLab API URL (auto-detected in GitLab CI)
    CI_MERGE_REQUEST_IID        GitLab MR IID (auto-detected in GitLab CI)
    CI_PROJECT_ID               GitLab Project ID (auto-detected in GitLab CI)
    GITHUB_TOKEN                GitHub token (auto-detected in GitHub Actions)

EXAMPLES:
    # Local run
    run-reviewdog.sh

    # GitHub PR review
    run-reviewdog.sh -r github-pr-review --token \$GITHUB_TOKEN

    # GitLab MR discussion
    run-reviewdog.sh -r gitlab-mr-discussion --token \$GITLAB_TOKEN

    # Private GitLab instance
    run-reviewdog.sh -r gitlab-mr-discussion --gitlab-api https://gitlab.company.com/api/v4 --token \$GITLAB_TOKEN

EOF
}

# Helper to check that a flag has a value
require_arg() {
    if [ -z "$2" ] || [ "${2#-}" != "$2" ]; then
        echo "Error: $1 requires a value"
        exit 1
    fi
}

# Parse arguments
while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        -r|--reporter)
            require_arg "$1" "${2:-}"
            REPORTER="$2"
            shift 2
            ;;
        -l|--level)
            require_arg "$1" "${2:-}"
            LEVEL="$2"
            shift 2
            ;;
        -f|--filter-mode)
            require_arg "$1" "${2:-}"
            FILTER_MODE="$2"
            shift 2
            ;;
        --fail-on-error)
            FAIL_ON_ERROR="true"
            shift
            ;;
        --gitlab-api)
            require_arg "$1" "${2:-}"
            export CI_API_V4_URL="$2"
            shift 2
            ;;
        --token)
            require_arg "$1" "${2:-}"
            TOKEN="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Set token based on reporter type
if [ -n "$TOKEN" ]; then
    case "$REPORTER" in
        github-*)
            export REVIEWDOG_GITHUB_API_TOKEN="$TOKEN"
            ;;
        gitlab-*)
            export REVIEWDOG_GITLAB_API_TOKEN="$TOKEN"
            ;;
    esac
fi

# Validate reporter, level, and filter-mode values
case "$REPORTER" in
    github-pr-review|github-check|gitlab-mr-discussion|gitlab-mr-commit|local) ;;
    *) echo "Error: unsupported reporter: $REPORTER"; exit 1 ;;
esac

case "$LEVEL" in
    info|warning|error) ;;
    *) echo "Error: unsupported level: $LEVEL"; exit 1 ;;
esac

case "$FILTER_MODE" in
    added|diff_context|file|nofilter) ;;
    *) echo "Error: unsupported filter-mode: $FILTER_MODE"; exit 1 ;;
esac

# Auto-detect CI environment if reporter is not set
if [ "$REPORTER" = "local" ]; then
    if [ -n "$GITHUB_ACTIONS" ]; then
        echo "Detected GitHub Actions environment"
        if [ -n "$GITHUB_BASE_REF" ]; then
            REPORTER="github-pr-review"
        else
            REPORTER="github-check"
        fi
    elif [ -n "$GITLAB_CI" ]; then
        echo "Detected GitLab CI environment"
        REPORTER="gitlab-mr-discussion"
    fi
fi

# Validate GitLab requirements
if echo "$REPORTER" | grep -q "^gitlab-"; then
    if [ -z "$REVIEWDOG_GITLAB_API_TOKEN" ]; then
        echo "Error: GitLab reporter requires REVIEWDOG_GITLAB_API_TOKEN"
        exit 1
    fi

    # For private GitLab, ensure API URL is set
    if [ -z "$CI_API_V4_URL" ] && [ -z "$GITLAB_API_URL" ]; then
        echo "Warning: GitLab API URL not set. Using default gitlab.com"
        export CI_API_V4_URL="https://gitlab.com/api/v4"
    elif [ -n "$GITLAB_API_URL" ]; then
        export CI_API_V4_URL="$GITLAB_API_URL"
    fi

    # Check for required GitLab CI variables
    if [ "$REPORTER" != "local" ]; then
        if [ -z "$CI_MERGE_REQUEST_IID" ] && [ -z "$CI_COMMIT_SHA" ]; then
            echo "Warning: Running outside GitLab CI. Some features may be limited."
        fi
    fi
fi

# Validate GitHub requirements
if echo "$REPORTER" | grep -q "^github-"; then
    if [ -z "$REVIEWDOG_GITHUB_API_TOKEN" ] && [ -z "$GITHUB_TOKEN" ]; then
        echo "Error: GitHub reporter requires REVIEWDOG_GITHUB_API_TOKEN or GITHUB_TOKEN"
        exit 1
    fi

    # Use GITHUB_TOKEN if REVIEWDOG_GITHUB_API_TOKEN is not set
    if [ -z "$REVIEWDOG_GITHUB_API_TOKEN" ] && [ -n "$GITHUB_TOKEN" ]; then
        export REVIEWDOG_GITHUB_API_TOKEN="$GITHUB_TOKEN"
    fi
fi

echo "Brakeman $(brakeman --version 2>/dev/null || echo 'unknown')"
echo "reviewdog $(reviewdog --version 2>/dev/null || echo 'unknown')"
echo "Reporter: $REPORTER"
echo "Level: $LEVEL"
echo "Filter mode: $FILTER_MODE"

# Run Brakeman and pipe to reviewdog
if [ "$FAIL_ON_ERROR" = "true" ]; then
    brakeman -f json -q --no-pager --no-exit-on-warn --no-exit-on-error | \
        reviewdog -f=brakeman \
            -reporter="$REPORTER" \
            -level="$LEVEL" \
            -filter-mode="$FILTER_MODE" \
            -fail-on-error
else
    brakeman -f json -q --no-pager --no-exit-on-warn --no-exit-on-error | \
        reviewdog -f=brakeman \
            -reporter="$REPORTER" \
            -level="$LEVEL" \
            -filter-mode="$FILTER_MODE"
fi
