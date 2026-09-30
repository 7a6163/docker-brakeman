# docker-brakeman

[![Docker Image Size (latest by date)](https://img.shields.io/docker/image-size/7a6163/brakeman)](https://hub.docker.com/r/7a6163/brakeman)
[![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/7a6163/docker-brakeman/docker-build-and-push.yml)](https://github.com/7a6163/docker-brakeman/actions)

A lightweight Docker image for [Brakeman](https://github.com/presidentbeef/brakeman), a static analysis security vulnerability scanner for Ruby on Rails applications.

## Features

- Based on Ruby 3 Alpine for minimal image size
- Multi-architecture support (linux/amd64, linux/arm64)
- Configurable Brakeman version (default: 8.0.4)
- Configurable reviewdog version (default: v0.20.3)
- Uses tini as init system
- Automated code review integration

## Installation

Pull the image from Docker Hub:

```bash
docker pull 7a6163/brakeman
```

Or from GitHub Container Registry:

```bash
docker pull ghcr.io/7a6163/brakeman
```

## Usage

Run Brakeman in your Rails application directory:

```bash
docker run --rm -v $(pwd):/app 7a6163/brakeman
```

To run with specific options:

```bash
docker run --rm -v $(pwd):/app 7a6163/brakeman brakeman [options]
```

For example, to generate a HTML report:

```bash
docker run --rm -v $(pwd):/app 7a6163/brakeman brakeman -o report.html
```

### Using with reviewdog

This image includes a convenient wrapper script for reviewdog that supports both GitHub and GitLab (including private instances).

#### Quick Usage

```bash
# Defaults to the local reporter (prints results, no API token needed).
# Pass -r to post to GitHub/GitLab; the reporter is not auto-detected.
docker run --rm -v $(pwd):/app 7a6163/brakeman run-reviewdog
```

#### GitHub Integration

```bash
# GitHub PR review
docker run --rm -v $(pwd):/app -e GITHUB_TOKEN 7a6163/brakeman \
  run-reviewdog -r github-pr-review

# GitHub Check API
docker run --rm -v $(pwd):/app -e GITHUB_TOKEN 7a6163/brakeman \
  run-reviewdog -r github-check
```

#### GitLab Integration (Public GitLab.com)

```bash
# GitLab MR discussion
docker run --rm -v $(pwd):/app -e GITLAB_TOKEN 7a6163/brakeman \
  run-reviewdog -r gitlab-mr-discussion --token $GITLAB_TOKEN

# GitLab MR commit comments
docker run --rm -v $(pwd):/app -e GITLAB_TOKEN 7a6163/brakeman \
  run-reviewdog -r gitlab-mr-commit --token $GITLAB_TOKEN
```

#### Private GitLab Instance

```bash
# Private GitLab with custom API URL
docker run --rm -v $(pwd):/app -e GITLAB_TOKEN 7a6163/brakeman \
  run-reviewdog -r gitlab-mr-discussion \
  --gitlab-api https://gitlab.company.com/api/v4 \
  --token $GITLAB_TOKEN
```

#### Manual reviewdog Usage (Advanced)

```bash
# Traditional approach still works
docker run --rm -v $(pwd):/app 7a6163/brakeman brakeman -f json | \
  docker run --rm -i -v $(pwd):/app -e GITHUB_TOKEN 7a6163/brakeman \
  reviewdog -f=brakeman -reporter=github-pr-review
```

#### CI/CD Integration

**GitHub Actions:**
```yaml
- name: Run Brakeman with reviewdog
  uses: reviewdog/action-brakeman@v2
  with:
    github_token: ${{ secrets.GITHUB_TOKEN }}
    reporter: github-pr-review
    brakeman_version: 8.0.4

# Or using our Docker image directly
- name: Run Brakeman with reviewdog (Docker)
  run: |
    docker run --rm -v ${{ github.workspace }}:/app \
      -e GITHUB_TOKEN=${{ secrets.GITHUB_TOKEN }} \
      7a6163/brakeman run-reviewdog -r github-pr-review
```

**GitLab CI:**
```yaml
brakeman-review:
  stage: test
  image: 7a6163/brakeman
  variables:
    GIT_DEPTH: 0  # reviewdog needs the MR base commit to compute the diff
  script:
    - run-reviewdog -r gitlab-mr-discussion --token "$REVIEWDOG_GITLAB_API_TOKEN"
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
```

`REVIEWDOG_GITLAB_API_TOKEN` must be a Project (or Personal) Access Token with
the `api` scope and at least the Reporter role, stored as a masked CI/CD variable.
`CI_JOB_TOKEN` does not have permission to post MR discussions.

Self-managed GitLab works with the same job: `CI_API_V4_URL` is provided by
GitLab CI and picked up automatically. Use `--gitlab-api URL` only when running
outside GitLab CI.

#### Available Options

The `run-reviewdog` script supports various options:

- `-r, --reporter`: Choose reporter (github-pr-review, github-check, gitlab-mr-discussion, gitlab-mr-commit, local)
- `-l, --level`: Set severity level (info, warning, error)
- `-f, --filter-mode`: Filter mode (added, diff_context, file, nofilter)
- `--fail-on-error`: Exit with error if issues found
- `--gitlab-api URL`: Custom GitLab API URL for private instances
- `--token TOKEN`: Access token for API authentication

#### Environment Variables

- `REVIEWDOG_GITHUB_API_TOKEN` or `GITHUB_TOKEN`: GitHub access token
- `REVIEWDOG_GITLAB_API_TOKEN`: GitLab access token (or pass `--token`; `GITLAB_TOKEN` is not read)
- `CI_API_V4_URL`: GitLab API URL (auto-detected in GitLab CI)
- `CI_MERGE_REQUEST_IID`: GitLab MR ID (auto-detected in GitLab CI)

## Tags

- `latest`: Always points to the most recent stable release
- `vX.Y.Z`: Points to specific versions (e.g., `v8.0.4`)

## Building with Custom Versions

You can build the Docker image with custom Brakeman and reviewdog versions:

```bash
# Build with default versions
docker build -t brakeman .

# Build with custom Brakeman version
docker build --build-arg BRAKEMAN_VERSION=7.1.0 -t brakeman .

# Build with custom reviewdog version
docker build --build-arg REVIEWDOG_VERSION=v0.21.0 -t brakeman .

# Build with custom versions for both
docker build --build-arg BRAKEMAN_VERSION=7.1.0 --build-arg REVIEWDOG_VERSION=v0.21.0 -t brakeman .
```

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.
