# 🤝 Contributing to Retail Store OpenTofu GitOps

Thank you for your interest in contributing to this project! This guide will help you get started with contributing to our OpenTofu GitOps platform.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Contributing Guidelines](#contributing-guidelines)
- [Pull Request Process](#pull-request-process)
- [Issue Guidelines](#issue-guidelines)
- [Development Workflow](#development-workflow)
- [Testing](#testing)
- [Documentation](#documentation)

## 📜 Code of Conduct

This project adheres to a code of conduct. By participating, you are expected to uphold this code. Please report unacceptable behavior to the project maintainers.

### Our Standards

- **Be respectful** and inclusive of different viewpoints and experiences
- **Be collaborative** and help others learn and grow
- **Be constructive** in feedback and discussions
- **Be patient** with newcomers and those learning

## 🚀 Getting Started

### Prerequisites

Before contributing, ensure you have:

- **Git** installed and configured
- **GitHub account** with SSH keys set up
- **AWS CLI** configured (for testing infrastructure changes)
- **OpenTofu** installed (version 1.11+)
- **kubectl** installed
- **Docker** installed (for local testing)

### Fork and Clone

1. **Fork** this repository to your GitHub account
2. **Clone** your fork locally:
   ```bash
   git clone git@github.com:YOUR_USERNAME/retail-store-opentofu-gitops.git
   cd retail-store-opentofu-gitops
   ```
3. **Add upstream** remote:
   ```bash
   git remote add upstream git@github.com:NitishJha199/retail-store-opentofu-gitops.git
   ```

## 🛠️ Development Setup

### Local Environment

1. **Switch to gitops branch:**
   ```bash
   git checkout gitops
   ```

2. **Install development dependencies:**
   ```bash
   # For Java services
   cd src/ui && ./mvnw install
   cd ../cart && ./mvnw install
   cd ../orders && ./mvnw install

   # For Go services
   cd ../catalog && go mod download

   # For Node.js services
   cd ../checkout && yarn install
   ```

3. **Set up pre-commit hooks:**
   ```bash
   # Install pre-commit
   pip install pre-commit

   # Install hooks
   pre-commit install
   ```

### Testing Infrastructure Changes

1. **Create a test environment:**
   ```bash
   cd open-tofu
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your test values
   ```

2. **Test your changes:**
   ```bash
   tofu init
   tofu plan
   # Review the plan carefully before applying
   ```

## 📝 Contributing Guidelines

### Types of Contributions

We welcome several types of contributions:

- 🐛 **Bug fixes** - Fix issues in code or documentation
- ✨ **New features** - Add new functionality or services
- 📚 **Documentation** - Improve or add documentation
- 🔧 **Infrastructure** - Enhance OpenTofu configurations
- 🚀 **CI/CD** - Improve GitHub Actions workflows
- 🧪 **Tests** - Add or improve test coverage
- 🎨 **UI/UX** - Improve user interface and experience

### Contribution Areas

#### 🏗️ Infrastructure (OpenTofu)
- Improve resource configurations
- Add new AWS services integration
- Enhance security configurations
- Optimize cost and performance

#### 🚀 Applications
- Add new microservices
- Improve existing service functionality
- Enhance error handling and logging
- Add monitoring and observability

#### 🔄 CI/CD
- Improve GitHub Actions workflows
- Add new testing strategies
- Enhance security scanning
- Optimize build and deployment processes

#### 📚 Documentation
- Improve README and guides
- Add architectural documentation
- Create troubleshooting guides
- Add code comments and examples

## 🔄 Pull Request Process

### Before Creating a PR

1. **Create a feature branch:**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** following our coding standards

3. **Test your changes:**
   ```bash
   # Run relevant tests
   ./scripts/test.sh

   # For infrastructure changes
   cd open-tofu && tofu plan
   ```

4. **Update documentation** if needed

5. **Commit your changes:**
   ```bash
   git add .
   git commit -m "feat: add new feature description"
   ```

### PR Guidelines

#### Title Format
Use conventional commit format:
- `feat:` - New features
- `fix:` - Bug fixes
- `docs:` - Documentation changes
- `style:` - Code style changes
- `refactor:` - Code refactoring
- `test:` - Adding tests
- `chore:` - Maintenance tasks

#### Description Template
```markdown
## 📋 Description
Brief description of changes

## 🔄 Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Infrastructure change
- [ ] CI/CD improvement

## 🧪 Testing
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing completed
- [ ] Infrastructure plan reviewed

## 📚 Documentation
- [ ] README updated
- [ ] Code comments added
- [ ] Architecture docs updated

## ✅ Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Tests added/updated
- [ ] Documentation updated
```

### Review Process

1. **Automated checks** must pass (CI/CD pipeline)
2. **Code review** by at least one maintainer
3. **Testing** in development environment
4. **Documentation review** if applicable
5. **Final approval** and merge

## 🐛 Issue Guidelines

### Bug Reports

Use the bug report template:

```markdown
## 🐛 Bug Description
Clear description of the bug

## 🔄 Steps to Reproduce
1. Step one
2. Step two
3. Step three

## 💭 Expected Behavior
What should happen

## 🔍 Actual Behavior
What actually happens

## 🌍 Environment
- OS: [e.g., macOS, Linux, Windows]
- OpenTofu version: [e.g., 1.11.3]
- AWS region: [e.g., us-west-2]
- Kubernetes version: [e.g., 1.33]

## 📋 Additional Context
Screenshots, logs, or other context
```

### Feature Requests

Use the feature request template:

```markdown
## 💡 Feature Description
Clear description of the proposed feature

## 🎯 Use Case
Why is this feature needed?

## 💭 Proposed Solution
How should this feature work?

## 🔄 Alternatives Considered
Other solutions you've considered

## 📋 Additional Context
Any other context or screenshots
```

## 🧪 Testing

### Running Tests

#### Unit Tests
```bash
# Java services
cd src/ui && ./mvnw test
cd src/cart && ./mvnw test
cd src/orders && ./mvnw test

# Go services
cd src/catalog && go test ./...

# Node.js services
cd src/checkout && yarn test
```

#### Integration Tests
```bash
# Run integration test suite
./scripts/integration-tests.sh
```

#### Infrastructure Tests
```bash
# Validate OpenTofu configuration
cd open-tofu
tofu init
tofu validate
tofu plan
```

### Test Coverage

- Maintain **>80%** test coverage for new code
- Add tests for bug fixes
- Include integration tests for new features
- Test error conditions and edge cases

## 📚 Documentation

### Documentation Standards

- Use **clear, concise language**
- Include **code examples** where helpful
- Add **diagrams** for complex concepts
- Keep documentation **up-to-date** with code changes

### Documentation Types

- **README files** - Overview and quick start
- **Code comments** - Inline documentation
- **Architecture docs** - System design and decisions
- **API documentation** - Service interfaces
- **Troubleshooting guides** - Common issues and solutions

## 🎨 Code Style

### General Guidelines

- **Consistent formatting** across all files
- **Meaningful variable and function names**
- **Clear code comments** for complex logic
- **Error handling** for all failure scenarios
- **Security best practices** always

### Language-Specific Guidelines

#### OpenTofu/HCL
```hcl
# Use descriptive resource names
resource "aws_eks_cluster" "retail_store_cluster" {
  name     = local.cluster_name
  role_arn = aws_iam_role.cluster_role.arn
  
  # Group related configurations
  vpc_config {
    subnet_ids = module.vpc.private_subnets
  }
}

# Use locals for computed values
locals {
  cluster_name = "${var.cluster_name}-${random_string.suffix.result}"
  common_tags = {
    Environment = var.environment
    Project     = "retail-store"
    ManagedBy   = "opentofu"
  }
}
```

#### Java
```java
// Use meaningful class and method names
public class CartService {
    
    // Document complex methods
    /**
     * Adds an item to the user's cart with quantity validation
     * @param userId The user identifier
     * @param item The item to add
     * @return Updated cart or error
     */
    public Cart addItem(String userId, CartItem item) {
        // Implementation
    }
}
```

#### Go
```go
// Use Go conventions
type CatalogService struct {
    repository ProductRepository
    logger     *log.Logger
}

// Document exported functions
// GetProducts retrieves products with optional filtering
func (s *CatalogService) GetProducts(filter ProductFilter) ([]Product, error) {
    // Implementation
}
```

## 🚀 Release Process

### Versioning

We use [Semantic Versioning](https://semver.org/):
- **MAJOR** version for incompatible API changes
- **MINOR** version for backward-compatible functionality
- **PATCH** version for backward-compatible bug fixes

### Release Workflow

1. **Create release branch** from `gitops`
2. **Update version numbers** and changelog
3. **Test thoroughly** in staging environment
4. **Create release PR** with detailed notes
5. **Merge and tag** the release
6. **Deploy to production** via GitHub Actions

## 🆘 Getting Help

### Community Support

- **GitHub Discussions** - General questions and discussions
- **GitHub Issues** - Bug reports and feature requests
- **Documentation** - Check existing docs first
- **Code Examples** - Look at existing implementations

### Maintainer Contact

For urgent issues or security concerns, contact the maintainers directly.

## 🙏 Recognition

Contributors will be recognized in:
- **README contributors section**
- **Release notes** for significant contributions
- **GitHub contributors graph**
- **Special mentions** for outstanding contributions

---

Thank you for contributing to the Retail Store OpenTofu GitOps project! Your contributions help make this platform better for everyone. 🚀