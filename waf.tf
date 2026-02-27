# WAF Web ACL for CloudFront distribution
resource "aws_wafv2_web_acl" "cloudfront_acl" {
  name  = "${var.organization_name}-cloudfront-waf"
  scope = "CLOUDFRONT" # global scope

  default_action {
    allow {}
  }

  visibility_config {
    sampled_requests_enabled   = true
    cloudwatch_metrics_enabled = true
    metric_name                = "cloudfrontWaf"
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    override_action {
      none {}
    }

    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "commonRules"
    }
  }

  rule {
    name     = "RateLimit2000"
    priority = 2

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }

    action {
      block {}
    }

    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "rateLimit"
    }
  }
}

# Associate the Web ACL with CloudFront distribution
resource "aws_wafv2_web_acl_association" "cf_association" {
  resource_arn = aws_cloudfront_distribution.cdn.arn
  web_acl_arn  = aws_wafv2_web_acl.cloudfront_acl.arn
}
