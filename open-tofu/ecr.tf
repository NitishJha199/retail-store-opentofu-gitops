# =============================================================================
# ECR REPOSITORIES FOR CONTAINER IMAGES
# =============================================================================

# ECR repositories for each microservice
resource "aws_ecr_repository" "retail_store_services" {
  for_each = toset(["ui", "catalog", "cart", "orders", "checkout"])
  
  name                 = "retail-store-${each.key}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(local.common_tags, {
    Name    = "retail-store-${each.key}"
    Service = each.key
  })
}

# ECR lifecycle policy to manage image retention
resource "aws_ecr_lifecycle_policy" "retail_store_policy" {
  for_each   = aws_ecr_repository.retail_store_services
  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 tagged images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v", "latest", "main", "develop"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Delete untagged images older than 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}