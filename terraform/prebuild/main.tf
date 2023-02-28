resource "aws_ecr_repository" "ecr"{
    name = var.registry-name
    image_tag_mutability = "IMMUTABLE"
}

resource "aws_ecr_repository_policy" "ecr-policy" {
  repository = aws_ecr_repository.ecr.name
  policy     = <<EOF
  {
    "Version": "2008-10-17",
    "Statement": [
      {
        "Sid": "Set the permission for ECR",
        "Effect": "Allow",
        "Principal": "*",
        "Action": [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:CompleteLayerUpload",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetLifecyclePolicy",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ]
      }
    ]
  }
  EOF
} 

# data "aws_ecr_authorization_token" "token" {
#     registry_id = "999176417877"
# }

# output "token" {
#   value = data.aws_ecr_authorization_token.token.authorization_token
#   sensitive = true
# }