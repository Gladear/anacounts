## Domain Identity

resource "aws_ses_domain_identity" "email_domain" {
  domain = var.email_domain
}

# Ownership validation

output "email_domain_verification_token" {
  value = aws_ses_domain_identity.email_domain.verification_token
}

resource "aws_ses_domain_identity_verification" "email_domain_verification" {
  domain = aws_ses_domain_identity.email_domain.domain
}

# DKIM

resource "aws_ses_domain_dkim" "email_domain" {
  domain = aws_ses_domain_identity.email_domain.domain
}

output "email_domain_dkim_tokens" {
  value = aws_ses_domain_dkim.email_domain.dkim_tokens
}

resource "aws_iam_user" "ses" {
  name = "${var.app_name}-ses"
}

resource "aws_iam_access_key" "ses" {
  user = aws_iam_user.ses.name
}

resource "aws_iam_user_policy" "ses_rw" {
  name = "${var.app_name}_send_raw_email"
  user = aws_iam_user.ses.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ses:SendRawEmail"]
        Resource = "*"
      }
    ]
  })
}
