# 🔧 GitLab CI/CD Generator for Docker Services

[![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://docker.com)
[![GitLab](https://img.shields.io/badge/GitLab-FC6D26?style=for-the-badge&logo=gitlab&logoColor=white)](https://gitlab.com)
[![Bash](https://img.shields.io/badge/Bash-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)](https://gnu.org/software/bash/)

> **Automate GitLab CI/CD pipeline generation for multi-service Docker projects with intelligent dependency management and build optimization.**

## 🎯 Overview

The `generate-yaml-RAOUL.sh` script automatically analyzes your Docker-based microservices architecture and generates optimized GitLab CI/CD pipelines. It provides intelligent dependency detection, conditional builds, and parallel execution strategies.

### Core Capabilities

| Feature                   | Description                                        | Impact                         |
| ------------------------- | -------------------------------------------------- | ------------------------------ |
| 🔍 **Auto-Discovery**     | Scans project structure for Docker services        | Zero manual configuration      |
| 🧠 **Dependency Mapping** | Analyzes FROM statements to build dependency graph | Correct build order guaranteed |
| ⚡ **Conditional Builds** | Executes only when changes are detected            | Reduced CI/CD costs            |
| 🔄 **Parallel Execution** | Independent services build simultaneously          | Faster deployment cycles       |

## 📁 Project Structure

```
project-root/
├── 🌐 frontend-service/
│   ├── Dockerfile
│   └── src/
├── 🔌 api-service/
│   ├── Dockerfile
│   └── app/
├── 🗄️ database-service/
│   ├── Dockerfile
│   └── migrations/
└── 🛠️ generate-yaml-RAOUL.sh
```

## 🚀 Quick Start

### Prerequisites

- GitLab project with Container Registry enabled
- Docker runners configured
- Multi-service Docker project structure

### Installation & Usage

```bash
# Make script executable
chmod +x generate-yaml-RAOUL.sh

# Generate pipeline
./generate-yaml-RAOUL.sh
```

The script will:

1. **Scan** for services (folders containing `Dockerfile`)
2. **Analyze** dependency relationships
3. **Generate** optimized `.gitlab-ci.yml`
4. **Backup** existing configuration (if present)

## 🏗️ Generated Pipeline Architecture

### Pipeline Stages

```mermaid
graph LR
    A[🔍 check_base] --> B[🏗️ build]
    B --> C[🚀 deploy]
```

#### Stage 1: `check_base`

- **Purpose**: Detect base image changes using digest comparison
- **Optimization**: Prevents unnecessary rebuilds
- **Caching**: Maintains digest cache between pipeline runs

#### Stage 2: `build`

- **Purpose**: Build and push Docker images
- **Intelligence**: Only executes when changes are detected
- **Parallelization**: Independent services build concurrently

### Smart Build Triggers

The pipeline executes builds when:

- ✅ **File Changes**: Service source code modifications
- ✅ **Dependency Updates**: Changes in dependent services
- ✅ **Base Image Changes**: New digest detected for base images
- ✅ **Scheduled Runs**: Automated pipeline execution

## 🔗 Dependency Management

### Example Configuration

```dockerfile
# Base service
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --production

# Dependent service
FROM $CI_REGISTRY_IMAGE/base-service:latest
COPY . /app
```

### Dependency Resolution

The script automatically:

- **Parses** `FROM` statements in Dockerfiles
- **Maps** inter-service dependencies
- **Orders** builds to respect dependency chain
- **Parallelizes** independent service builds

## ⚙️ Configuration

### Environment Variables

| Variable             | Purpose                     | Source             |
| -------------------- | --------------------------- | ------------------ |
| `$CI_REGISTRY_IMAGE` | Container registry base URL | GitLab (automatic) |
| `$CI_JOB_TOKEN`      | Authentication token        | GitLab (automatic) |

### GitLab Requirements

- **Container Registry**: Enabled for image storage
- **Docker Runners**: Available for build execution
- **Permissions**: Registry push/pull access configured

## 🎛️ Advanced Features

### Cache Management

- **Digest Tracking**: Monitors base image changes
- **Artifact Persistence**: Maintains state between jobs
- **Cache Invalidation**: Smart cache refresh strategies

### Build Optimization

- **Conditional Logic**: Skip unnecessary builds
- **Resource Efficiency**: Parallel execution where possible
- **Cost Reduction**: Minimize CI/CD resource usage

## 🔧 Customization Options

### Extending the Script

```bash
# Custom registry support
CUSTOM_REGISTRY="registry.example.com"

# Custom tag strategies
BUILD_TAG="${CI_COMMIT_SHORT_SHA}"

# Additional build arguments
DOCKER_BUILD_ARGS="--build-arg ENV=production"
```

### Integration Possibilities

- **Testing Integration**: Add test stages before build
- **Security Scanning**: Integrate vulnerability checks
- **Deployment Automation**: Extend to deployment stages
- **Notification Systems**: Add build status notifications

## 🛠️ Troubleshooting

<details>
<summary><strong>🔍 Service Detection Issues</strong></summary>

**Problem**: Script doesn't find services

**Solutions**:

- Verify `Dockerfile` naming (case-sensitive)
- Check folder structure matches expected pattern
- Ensure services are in subdirectories

</details>

<details>
<summary><strong>🔗 Dependency Resolution Problems</strong></summary>

**Problem**: Dependencies not detected correctly

**Solutions**:

- Use standard format: `$CI_REGISTRY_IMAGE/service-name:tag`
- Match service names to folder names (lowercase)
- Verify FROM statement syntax

</details>

<details>
<summary><strong>⚡ Performance Issues</strong></summary>

**Problem**: Slow or unnecessary builds

**Solutions**:

- Check cache configuration
- Verify change detection rules
- Review runner resource allocation

</details>

---

<div align="center">

**Built for DevOps teams who value efficiency and automation**

</div>
