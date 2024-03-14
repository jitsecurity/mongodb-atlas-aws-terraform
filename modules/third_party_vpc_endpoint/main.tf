resource "aws_security_group" "third_party_service_security_group" {
  name        = "${var.name}_egress_any"
  description = "Allow egress traffic from vpc interface EP of ${var.name}, ingress from specific security groups"
  vpc_id      = var.vpc_id
  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = var.allowed_access_security_groups
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = "${var.name}_egress_any"
  }
}

resource "aws_vpc_endpoint" "third_party_service" {
  vpc_id            = var.vpc_id
  service_name      = var.service_name
  vpc_endpoint_type = "Interface"

  security_group_ids = [aws_security_group.third_party_service_security_group.id]

  subnet_ids = var.subnet_ids
  tags = {
    Name = var.name
  }
}
