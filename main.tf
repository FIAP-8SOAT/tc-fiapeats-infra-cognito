terraform {
  backend "s3" {
    bucket  = "terraform-fiapeats"
    key     = "state/fiapeatscognito/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

provider "aws" {
  region = "us-east-1"
}

# ---------------------------
# Cognito User Pool
# ---------------------------
resource "aws_cognito_user_pool" "fiapeats_user_pool" {
  name = "fiapeats-user-pool"

  alias_attributes = ["email"]

  password_policy {
    minimum_length    = 8
    require_uppercase = true
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
  }

  mfa_configuration         = "OFF"
  auto_verified_attributes  = ["email"]

  schema {
    name                = "email"
    required            = true
    mutable             = false
    attribute_data_type = "String"
  }
}

# ---------------------------
# User Pool Client
# ---------------------------
resource "aws_cognito_user_pool_client" "fiapeats_client" {
  name         = "fiapeats-client"
  user_pool_id = aws_cognito_user_pool.fiapeats_user_pool.id

  generate_secret                      = true
  allowed_oauth_flows                 = ["code", "implicit"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes                = ["openid", "email"]
  supported_identity_providers        = ["COGNITO"]
  callback_urls                         = ["https://oauth.pstmn.io/v1/callback"]

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_PASSWORD_AUTH"
  ]
}

# ---------------------------
# Identity Pool
# ---------------------------
resource "aws_cognito_identity_pool" "fiapeats_identity_pool" {
  identity_pool_name               = "fiapeats-identity-pool"
  allow_unauthenticated_identities = false

  cognito_identity_providers {
    client_id     = aws_cognito_user_pool_client.fiapeats_client.id
    provider_name = "cognito-idp.us-east-1.amazonaws.com/${aws_cognito_user_pool.fiapeats_user_pool.id}"
  }
}

# ---------------------------
# IAM Policy for Cognito Authenticated Role
# ---------------------------
data "aws_iam_policy_document" "cognito_authenticated_assume_role_policy" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = ["cognito-identity.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "cognito-identity.amazonaws.com:aud"
      values   = [aws_cognito_identity_pool.fiapeats_identity_pool.id]
    }

    condition {
      test     = "StringLike"
      variable = "cognito-identity.amazonaws.com:amr"
      values   = ["authenticated"]
    }
  }
}

resource "aws_iam_role" "cognito_authenticated_role" {
  name               = "fiapeats-cognito-authenticated-role"
  assume_role_policy = data.aws_iam_policy_document.cognito_authenticated_assume_role_policy.json
}

# ---------------------------
# Attach IAM Role to Identity Pool
# ---------------------------
resource "aws_cognito_identity_pool_roles_attachment" "fiapeats_identity_pool_roles_attachment" {
  identity_pool_id = aws_cognito_identity_pool.fiapeats_identity_pool.id

  roles = {
    authenticated = aws_iam_role.cognito_authenticated_role.arn
  }
}

# ---------------------------
# Domain
# ---------------------------
resource "aws_cognito_user_pool_domain" "fiapeats_domain" {
  domain       = "fiapeats-auth" 
  user_pool_id = aws_cognito_user_pool.fiapeats_user_pool.id
}

