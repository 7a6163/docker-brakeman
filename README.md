# docker-brakeman

[![Docker Image Size (latest by date)](https://img.shields.io/docker/image-size/7a6163/brakeman)](https://hub.docker.com/r/7a6163/brakeman)
[![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/7a6163/docker-brakeman/docker-build-and-push.yml)](https://github.com/7a6163/docker-brakeman/actions)

A lightweight Docker image for [Brakeman](https://github.com/presidentbeef/brakeman), a static analysis security vulnerability scanner for Ruby on Rails applications.

## Features

- Based on Ruby 3 Alpine for minimal image size
- Multi-architecture support (linux/amd64, linux/arm64)
- Configurable Brakeman version (default: 7.0.2)
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

You can use this image with reviewdog to post code review comments:

```bash
docker run --rm -v $(pwd):/app 7a6163/brakeman brakeman -f json | \
  docker run --rm -i -v $(pwd):/app 7a6163/brakeman reviewdog -f=brakeman -reporter=github-pr-review
```

For GitHub Actions integration, you can use the reviewdog GitHub Actions:

```yaml
- name: Run Brakeman with reviewdog
  uses: reviewdog/action-brakeman@v2
  with:
    github_token: ${{ secrets.GITHUB_TOKEN }}
    reporter: github-pr-review
    brakeman_version: 7.0.2
```

## Tags

- `latest`: Always points to the most recent stable release
- `vX.Y.Z`: Points to specific versions (e.g., `v7.0.2`)

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
