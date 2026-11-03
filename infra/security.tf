
# SECURITY GROUP: Controls traffic to the web server
# Stateful: automatically allows reply traffic.

resource "aws_security_group" "web_sg" {
  name        = "web-server-sg"
  description = "Allow HTTPS only"
  vpc_id      = aws_vpc.main.id

  # INBOUND: Allow HTTPS only
  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # OUTBOUND: Allow HTTPS only
  egress {
    description = "Allow HTTPS outbound"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-server-sg"
  }
}


# NETWORK ACL: Controls traffic at subnet level
# Stateless: return traffic needs separate rules.

resource "aws_network_acl" "main_nacl" {
  vpc_id = aws_vpc.main.id

  # INBOUND: Allow HTTPS requests
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  # INBOUND: Allow return traffic for outgoing connections
  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # INBOUND: Deny everything else
  ingress {
    protocol   = "-1"
    rule_no    = 200
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  # OUTBOUND: Allow HTTPS
  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  # OUTBOUND: Allow return traffic to HTTPS clients
  egress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # OUTBOUND: Deny everything else
  egress {
    protocol   = "-1"
    rule_no    = 200
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "main-nacl"
  }
}


# Attach the NACL to the public subnet
resource "aws_network_acl_association" "public_nacl_assoc" {
  network_acl_id = aws_network_acl.main_nacl.id
  subnet_id      = aws_subnet.public_1.id
}
