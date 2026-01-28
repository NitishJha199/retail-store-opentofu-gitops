# 🤝 Contributing to Retail Store GitOps

Thank you for your interest in contributing to the Retail Store GitOps project! This document provides guidelines and information for contributors.

## 🌟 Ways to Contribute

- 🐛 **Bug Reports**: Report issues and bugs
- 💡 **Feature Requests**: Suggest new features and improvements
- 📝 **Documentation**: Improve documentation and guides
- 🔧 **Code Contributions**: Submit bug fixes and new features
- 🧪 **Testing**: Help test new features and report issues
- 💬 **Community Support**: Help other users in discussions

## 🚀 Getting Started

### Prerequisites

- Git and GitHub account
- AWS account with appropriate permissions
- Docker, kubectl, OpenTofu installed
- Basic knowledge of Kubernetes, GitOps, and Infrastructure as Code

### Development Setup

1. **Fork the Repository**
   ```bash
   # Fork on GitHub, then clone your fork
   git clone https://github.com/YOUR_USERNAME/retail-store-opentofu-gitops.git
   cd retail-store-opentofu-gitops
   ```

2. **Set Up Development Environment**
   ```bash
   # Add upstream remote
   git remote add upstream https://github.com/NitishJha199/retail-store-opentofu-gitops.git
   
   # Create development branch
   git checkout -b feature/your-feature-name
   ```

3. **Deploy Development Environment**
   ```bash
   # Deploy infrastructure for testing
   ./deploy-modules.sh
   
   # Build and push test images
   ./scripts/build-and-push-images.sh
   ```

## 📋 Contribution Guidelines

### Code Style

#### OpenTofu/Terraform
- Use consistent indentation (2 spaces)
- Include comments for complex logic
- Use meaningful variable names
- Follow [Terraform best practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)

```hcl
# Good
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "retail-store"
  
  validation {
    condition     = length(var.cluster_name) > 0
    error_message = "Cluster name cannot be empty."
  }
}

# Bad
variable "name" {
  default = "cluster"
}
```

#### Kubernetes YAML
- Use consistent indentation (2 spaces)
- Include resource limits and requests
- Add appropriate labels and annotations
- Follow [Kubernetes best practices](https://kubernetes.io/docs/concepts/configuration/overview/)

```yaml
# Good
apiVersion: apps/v1
kind: Deployment
metadata:
  name: retail-store-ui
  namespace: retail-store
  labels:
    app.kubernetes.io/name: ui
    app.kubernetes.io/component: frontend
    app.kubernetes.io/part-of: retail-store
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: ui
  template:
    metadata:
      labels:
        app.kubernetes.io/name: ui
    spec:
      containers:
      - name: ui
        image: retail-store-ui:latest
        resources:
          requests:
            cpu: 128m
            memory: 512Mi
          limits:
            memory: 512Mi
```

#### Documentation
- Use clear, concise language
- Include code examples
- Add diagrams where helpful
- Follow markdown best practices

### Commit Messages

Use [Conventional Commits](https://www.conventionalcommits.org/) format:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

Examples:
```
feat(ui): add shopping cart functionality

fix(deployment): resolve image pull secret issue

docs(readme): update installation instructions

chore(deps): update helm chart dependencies
```

### Pull Request Process

1. **Create Feature Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make Changes**
   - Write clean, well-documented code
   - Add tests if applicable
   - Update documentation

3. **Test Changes**
   ```bash
   # Test infrastructure changes
   cd open-tofu
   tofu plan
   
   # Test application changes
   ./test-deployment.sh
   
   # Test documentation
   # Verify all links work and formatting is correct
   ```

4. **Commit Changes**
   ```bash
   git add .
   git commit -m "feat(component): description of changes"
   ```

5. **Push and Create PR**
   ```bash
   git push origin feature/your-feature-name
   # Create pull request on GitHub
   ```

6. **PR Requirements**
   - [ ] Clear description of changes
   - [ ] Tests pass (if applicable)
   - [ ] Documentation updated
   - [ ] No merge conflicts
   - [ ] Follows code style guidelines

### Testing

#### Infrastructure Testing
```bash
# Validate OpenTofu configuration
cd open-tofu
tofu fmt -check
tofu validate

# Plan changes
tofu plan
```

#### Application Testing
```bash
# Build and test images
docker build -t test-ui ./src/ui/
docker run --rm test-ui npm test

# Integration testing
./test-deployment.sh
```

#### Documentation Testing
```bash
# Check markdown formatting
markdownlint *.md docs/*.md

# Test links
markdown-link-check README.md
```

## 🐛 Bug Reports

### Before Reporting

1. **Search existing issues** to avoid duplicates
2. **Test with latest version** to ensure bug still exists
3. **Gather relevant information** (logs, configurations, etc.)

### Bug Report Template

```markdown
**Bug Description**
A clear description of the bug.

**Steps to Reproduce**
1. Step one
2. Step two
3. Step three

**Expected Behavior**
What you expected to happen.

**Actual Behavior**
What actually happened.

**Environment**
- OS: [e.g., Ubuntu 20.04]
- OpenTofu version: [e.g., 1.6.0]
- Kubernetes version: [e.g., 1.28]
- AWS region: [e.g., us-west-2]

**Logs**
```
Paste relevant logs here
```

**Additional Context**
Any other relevant information.
```

## 💡 Feature Requests

### Feature Request Template

```markdown
**Feature Description**
A clear description of the feature you'd like to see.

**Use Case**
Describe the problem this feature would solve.

**Proposed Solution**
Your ideas for how this could be implemented.

**Alternatives Considered**
Other solutions you've considered.

**Additional Context**
Any other relevant information, mockups, or examples.
```

## 📚 Documentation Contributions

### Documentation Standards

- **Clarity**: Write for beginners and experts alike
- **Completeness**: Include all necessary steps and information
- **Accuracy**: Test all commands and procedures
- **Examples**: Provide practical, working examples
- **Structure**: Use consistent formatting and organization

### Documentation Types

1. **User Guides**: Step-by-step instructions for users
2. **Developer Docs**: Technical documentation for contributors
3. **API Documentation**: Reference documentation for APIs
4. **Troubleshooting**: Common issues and solutions
5. **Architecture**: System design and component descriptions

### Adding Documentation

1. **Create or update markdown files** in the `docs/` directory
2. **Update the main README** if adding new major sections
3. **Add links** to new documentation in appropriate places
4. **Test all commands** and procedures before submitting

## 🏷️ Issue Labels

We use the following labels to categorize issues:

### Type Labels
- `bug`: Something isn't working
- `enhancement`: New feature or request
- `documentation`: Improvements or additions to documentation
- `question`: Further information is requested
- `help wanted`: Extra attention is needed
- `good first issue`: Good for newcomers

### Priority Labels
- `priority/critical`: Critical issues that need immediate attention
- `priority/high`: High priority issues
- `priority/medium`: Medium priority issues
- `priority/low`: Low priority issues

### Component Labels
- `component/infrastructure`: OpenTofu/AWS infrastructure
- `component/kubernetes`: Kubernetes configurations
- `component/argocd`: ArgoCD configurations
- `component/applications`: Application code
- `component/ci-cd`: GitHub Actions workflows

## 🎯 Development Roadmap

### Current Focus Areas

1. **Stability**: Improving reliability and error handling
2. **Documentation**: Comprehensive guides and troubleshooting
3. **Testing**: Automated testing and validation
4. **Security**: Enhanced security practices and scanning
5. **Monitoring**: Observability and monitoring capabilities

### Future Enhancements

1. **Multi-Environment**: Support for staging/production environments
2. **Service Mesh**: Istio integration for advanced traffic management
3. **Observability**: Prometheus, Grafana, and distributed tracing
4. **Database**: Persistent storage with RDS/Aurora
5. **Caching**: Redis cluster for improved performance
6. **Advanced Deployments**: Blue-green and canary deployments

## 🤝 Community Guidelines

### Code of Conduct

- **Be respectful**: Treat everyone with respect and kindness
- **Be inclusive**: Welcome people of all backgrounds and experience levels
- **Be constructive**: Provide helpful feedback and suggestions
- **Be patient**: Remember that everyone is learning
- **Be collaborative**: Work together towards common goals

### Communication Channels

- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: Questions, ideas, and general discussion
- **Pull Requests**: Code reviews and collaboration

### Getting Help

If you need help with contributing:

1. **Check the documentation** first
2. **Search existing issues** and discussions
3. **Ask in GitHub Discussions** for general questions
4. **Create an issue** for specific problems

## 🏆 Recognition

Contributors will be recognized in the following ways:

- **Contributors list** in the README
- **Release notes** mentioning significant contributions
- **GitHub contributor statistics** and badges
- **Special recognition** for major contributions

## 📄 License

By contributing to this project, you agree that your contributions will be licensed under the same [MIT License](LICENSE) that covers the project.

## 🙏 Thank You

Thank you for contributing to the Retail Store GitOps project! Your contributions help make this project better for everyone. Whether you're fixing a typo, adding a feature, or helping other users, every contribution is valuable and appreciated.

---

**Questions?** Feel free to ask in [GitHub Discussions](https://github.com/NitishJha199/retail-store-opentofu-gitops/discussions) or create an issue if you need help getting started.