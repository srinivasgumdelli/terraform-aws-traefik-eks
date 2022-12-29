output "acm_certificate_arn" {
  description = "The ARN of the ACM certificate for Traefik's ALB"
  value       = module.acm.acm_certificate_arn
}

output "https_listener_arns" {
  description = "The ARNs of the HTTPS load balancer listeners created for Traefik"
  value       = module.alb.https_listener_arns
}

output "lb_dns_name" {
  description = "The dns/hostname of the Traefik ALB"
  value       = module.alb.lb_dns_name
}

output "target_group_arn" {
  description = "The arn of the Traefik ALB Target Group"
  value       = module.alb.target_group_arns[0]
}