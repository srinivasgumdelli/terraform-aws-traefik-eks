variable "alb_name" {
  description = "(Optional) Name of the ALB. If omitted, the default name will be used. Default: `traefik-alb`"
  type = string
  default = "traefik-alb"
}

variable "alb_name_prefix" {
  description = "(Optional) Name prefix of the ALB. If omitted, the default name prefix will be used. Default: `traef-`"
  type = string
  default = "traef-"
}

variable "backend_port" {
  description = "(Optional) The port on which the Traefik service is listening. Default: `80`"
  type = number
  default = 80
}

variable "chart_name" {
  description = "(Optional) Name of the Traefik Helm chart. If omitted, the default name will be used. Default: `traefik`"
  type = string
  default = "traefik"
}

variable "deregistration_delay" {
  description = "(Optional) The amount time for ALB TargetGroup to wait before changing the state of a deregistering target from draining to unused. Default: `60`"
  type = number
  default = 60
}

variable "fqdn" {
  description = "The fully qualified domain name to create the certificate for Traefik and Route53 record"
  type = string
}

variable "http_port" {
  description = "(Optional) The port on which the Traefik service is listening. Default: `80`"
  type = number
  default = 80
}

variable "https_port" {
  description = "(Optional) The port on which the Traefik service is listening. Default: `443`"
  type = number
  default = 443
}

variable "inbound_cidrs" {
  description = "List of CIDR blocks to allow inbound traffic from to the Traefik ALB."
  type = list(string)
}

variable "namespace" {
  description = "(Optional) Namespace in an Amazon EKS cluster to deploy Traefik to. Default: `traefik`"
  type = string
  default = "traefik"
}

variable "outbound_cidrs" {
  description = "(Optional) List of CIDR blocks to allow outbound traffic to. Default: `[0.0.0.0/0]`"
  type = list(string)
  default = ["0.0.0.0/0"] 
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs to creaate the Traefik ALB in."
  type = list(string)
}

variable "security_group_name" {
  description = "(Optional) Name of the security group. If omitted, the default name will be used. Default: `traefik-alb-sg`"
  type = string
  default = "traefik-alb-sg"
}

variable "subject_alternative_names" {
  description = "(Optional) List of additional FQDNs to create the certificate for Traefik and Route53 record"
  type = list(string)
  default = null
}

variable "values" {
  description = "(Optional) Use the templatefile function to pass through additional configuration for Traefik using the Helm values.yaml. Default: `\"\"`"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "VPC ID to create the Traefik ALB in."
  type = string
}

variable "zone_id" {
  description = "Route53 zone ID to create a dns record to point the fdqn to the Traefik ALB."
  type = string
}
