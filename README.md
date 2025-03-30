# docker-brakeman

[![Docker Image Size (latest by date)](https://img.shields.io/docker/image-size/7a6163/brakeman)](https://hub.docker.com/r/7a6163/brakeman)
[![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/7a6163/docker-brakeman/docker-build-and-push.yml)](https://github.com/7a6163/docker-brakeman/actions)

A lightweight Docker image for [Brakeman](https://github.com/presidentbeef/brakeman), a static analysis security vulnerability scanner for Ruby on Rails applications.

## Features

- Based on Ruby 3 Alpine for minimal image size
- Multi-architecture support (linux/amd64, linux/arm64)
- Brakeman version 7.0.0
- Uses tini as init system

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

## Tags

- `latest`: Always points to the most recent stable release
- `vX.Y.Z`: Points to specific versions (e.g., `v7.0.0`)

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.
