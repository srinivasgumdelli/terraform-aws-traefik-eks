# ACM SSL Certificate for the hostname
module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 3.0"

  # If no FQDN is provided then we use the default hostname
  domain_name = var.fqdn
  zone_id     = var.zone_id

  subject_alternative_names = var.subject_alternative_names

  wait_for_validation = true

  tags = {
    Name = var.fqdn
  }
}

# Security Group for the Traefik ALB, allows inbound traffic from the provided CIDRs
resource "aws_security_group" "this" {
  name = var.security_group_name

  description = "Allows access to the Traefik Application Load Balancer"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.inbound_cidrs
    content {
      from_port   = var.http_port
      to_port     = var.http_port
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  dynamic "ingress" {
    for_each = var.inbound_cidrs
    content {
      from_port   = var.https_port
      to_port     = var.https_port
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.outbound_cidrs
  }

  tags = {
    Name = var.security_group_name
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Traefik ALB, deploys a public load balancer with a listener on port 80 that redirects to port 443
# uses the ACM certificate created above to handle SSL termination and the security group created above
# for whitelisting inbound traffic
module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 6.0"

  name = var.alb_name

  load_balancer_type = "application"

  vpc_id          = var.vpc_id
  subnets         = var.public_subnet_ids
  security_groups = [aws_security_group.this.id]

  target_groups = [
    {
      name_prefix          = var.alb_name_prefix == "" ? "traef-" : var.alb_name_prefix
      backend_protocol     = "HTTP"
      backend_port         = var.backend_port
      target_type          = "ip"
      deregistration_delay = var.deregistration_delay
      health_check = {
        enabled             = true
        interval            = 10
        path                = "/"
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 5
        protocol            = "HTTP"
        matcher             = "200,404"
      }
    }
  ]

  http_tcp_listeners = [
    {
      port               = var.http_port
      protocol           = "HTTP"
      target_group_index = 0
      action_type        = "redirect"
      redirect = {
        port        = var.https_port
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  ]

  https_listeners = [
    {
      port               = var.https_port
      protocol           = "HTTPS"
      target_group_index = 0
      certificate_arn    = module.acm.acm_certificate_arn
    }
  ]

  tags = {
    Name = var.alb_name
  }
}

# Traefik Helm Chart, deploys the Traefik ingress controller using the provided helm values
# default namespace is traefik but this can be changed.
resource "helm_release" "this" {
  name             = var.chart_name == "" ? "traefik" : var.chart_name
  namespace        = var.namespace
  create_namespace = true

  repository = "https://traefik.github.io/charts"
  chart      = "traefik"
  version    = "20.7.0"

  # We are using an ALB so we don't need to create a service of type LoadBalancer
  set {
    name  = "service.type"
    value = "ClusterIP"
  }
  
  # Pass through additional helm values using templatefile
  values = var.values == "" ? [] : [var.values]
}


# Traefik Target Group Binding, binds the Traefik ingress controller to the ALB created above
# Uses AWS Load Balancer Controller to create the TargetGroupBinding resource
# https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.1/guide/targetgroupbinding/targetgroupbinding/
resource "kubectl_manifest" "this" {
  yaml_body = <<YAML
apiVersion: elbv2.k8s.aws/v1beta1
kind: TargetGroupBinding
metadata:
  name: ${resource.helm_release.this.metadata[0].name}
  namespace: ${var.namespace}
spec:
  serviceRef:
    name: ${resource.helm_release.this.metadata[0].name}
    port: ${var.backend_port}
  targetGroupARN: ${module.alb.target_group_arns[0]}
  targetType: ip
YAML
}

# Traefik DNS record, creates a CNAME record for the provided hostname in Route53 that points to the ALB created above
resource "aws_route53_record" "this" {
  name    = var.fqdn
  type    = "CNAME"
  ttl     = "60"
  records = [module.alb.lb_dns_name]
  zone_id = var.zone_id
}