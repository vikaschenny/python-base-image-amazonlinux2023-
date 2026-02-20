# Python Base Image

A container image used for running Python projects, built on Amazon Linux 2023.

## Overview

This project provides a minimal, production-ready Python base image optimized for containerized Python applications. The image is built on Amazon Linux 2023 and includes Python 3.11, pip, and essential tools for running Python applications in containerized environments.

## Base Image

- **Base**: `amazonlinux:2023` ([Docker Hub](https://hub.docker.com/_/amazonlinux))
- **Python Version**: 3.11.14
- **Package Manager**: dnf (DNF package manager)
- **Image Size**: ~87 MB (content size)

## Current Approach

### Architecture Decisions

1. **Amazon Linux 2023 Base**
   - Stable, secure, and high-performance execution environment
   - Optimized for AWS environments but works anywhere Docker runs
   - Provides ongoing security and maintenance updates from AWS
   - Minimal base image footprint

2. **Python 3.11 Installation**
   - Amazon Linux 2023 comes with Python 3.9 by default
   - We install Python 3.11 alongside the default Python 3.9
   - **Important**: We use `python3.11` explicitly for all pip operations
   - This approach preserves system tools (like `dnf`) that depend on Python 3.9
   - Avoids breaking system package management while providing the latest Python features

3. **Minimal Image Size**
   - Configured dnf to skip documentation (`tsflags=nodocs`)
   - Disabled weak dependencies (`install_weak_deps=False`)
   - Removed build tools (gcc, python3.11-devel) after building dumb-init
   - Cleaned package caches and logs after each installation step
   - Multi-stage cleanup to minimize final image size

4. **Signal Handling with dumb-init**
   - Uses `dumb-init` as the entrypoint for proper signal handling
   - Ensures child processes receive signals correctly
   - Prevents zombie processes in containers
   - Critical for production containerized applications

5. **Build Context Management**
   - Uses `REMOTE_SOURCE` and `REMOTE_SOURCE_DIR` build arguments
   - Copies application files to `/remote-source/app` during build
   - Cleans up build context after installation to reduce image size
   - Supports flexible build scenarios

### Build Process

The Containerfile follows a layered approach:

1. **Base Layer**: Amazon Linux 2023
2. **System Configuration**: Configure dnf for minimal installation
3. **Python Installation**: Install Python 3.11 and pip
4. **Pip Upgrade**: Upgrade pip to latest version
5. **Build Tools**: Install gcc and python3.11-devel temporarily
6. **Application Dependencies**: Install dumb-init using constraints.txt
7. **Cleanup**: Remove build tools and clean caches
8. **Final Setup**: Set entrypoint to dumb-init

## Key Features

- ✅ Python 3.11.14 runtime
- ✅ Latest pip (26.0.1)
- ✅ Proper signal handling with dumb-init
- ✅ Minimal image size (~87 MB)
- ✅ English locale support (glibc-langpack-en)
- ✅ Production-ready configuration
- ✅ Security-focused (minimal attack surface)

## Building the Image

### Prerequisites

- Docker or Podman installed
- Build context with `app/constraints.txt` file

### Build Command

```bash
docker build -f Containerfile -t python-base-image:amazonlinux2023 .
```

Or with Podman:

```bash
podman build -f Containerfile -t python-base-image:amazonlinux2023 .
```

### Build Arguments

- `CONTAINER_IMAGE`: Base image (default: `amazonlinux:2023`)
- `REMOTE_SOURCE`: Source directory to copy (default: `.`)
- `REMOTE_SOURCE_DIR`: Destination directory in container (default: `/remote-source`)

Example with custom base image:

```bash
docker build \
  --build-arg CONTAINER_IMAGE=amazonlinux:2 \
  -f Containerfile \
  -t python-base-image:amazonlinux2 .
```

## Usage

### Basic Usage

```bash
# Run Python interactively
docker run --rm -it python-base-image:amazonlinux2023 python3.11

# Run a Python script
docker run --rm -v $(pwd):/app python-base-image:amazonlinux2023 python3.11 /app/script.py

# Check Python version
docker run --rm python-base-image:amazonlinux2023 python3.11 --version

# Check pip version
docker run --rm python-base-image:amazonlinux2023 python3.11 -m pip --version
```

### Using as Base Image

Create your own Dockerfile:

```dockerfile
FROM python-base-image:amazonlinux2023

WORKDIR /app

# Copy requirements
COPY requirements.txt .

# Install dependencies
RUN python3.11 -m pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Run your application
CMD ["python3.11", "app.py"]
```

### With pip install

```bash
docker run --rm \
  -v $(pwd):/app \
  python-base-image:amazonlinux2023 \
  python3.11 -m pip install --user -r /app/requirements.txt
```

## Project Structure

```
python-base-image/
├── Containerfile          # Container build definition
├── app/
│   └── constraints.txt    # Python package constraints (optional)
├── README.md              # This file
├── README.rst             # Original README
├── LICENSE                # Apache License 2.0
└── .zuul.d/               # CI/CD configuration
    ├── jobs.yaml
    └── project.yaml
```

## Technical Notes

### Why Python 3.11 Explicitly?

Amazon Linux 2023 ships with Python 3.9 as the default `python3`. System tools like `dnf` depend on Python 3.9. By using `python3.11` explicitly:

- We don't break system package management
- We provide access to Python 3.11 features
- We maintain compatibility with system tools
- We follow best practices for multi-Python environments

### Constraints File

The `app/constraints.txt` file can be used to pin specific package versions. Currently, it's a placeholder but can be populated to enforce version constraints:

```txt
# Example constraints.txt
dumb-init==1.2.5
```

### Image Optimization

The build process optimizes for size:

- Multi-layer caching for faster rebuilds
- Removal of build dependencies after use
- Cache and log cleanup after each step
- Minimal documentation installation
- No weak dependencies

## CI/CD Integration

This project includes Zuul CI/CD configuration (`.zuul.d/`) for automated builds and image publishing to `quay.io/ansible/python-base`.

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) file for details.

## Contributing

When contributing, please ensure:

1. Containerfile follows the layered approach
2. Image size remains minimal
3. All build steps include cleanup
4. Python version compatibility is maintained
5. System tools remain functional

## References

- [Amazon Linux 2023 Documentation](https://docs.aws.amazon.com/linux/al2023/)
- [Docker Hub - Amazon Linux](https://hub.docker.com/_/amazonlinux)
- [dumb-init](https://github.com/Yelp/dumb-init)
- [Python 3.11 Documentation](https://docs.python.org/3.11/)
