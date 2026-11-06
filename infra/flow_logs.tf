
# 1. Create a CloudWatch Log Group
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/cloud-netsec-flow-logs"
  retention_in_days = 1
}

# 2. Allow AWS VPC Flow Logs to access CloudWatch
resource "aws_iam_role" "flow_logs_role" {
  name = "cloud-netsec-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "vpc-flow-logs.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# 3. Give the role permission to write logs
resource "aws_iam_role_policy" "flow_logs_policy" {
  name = "cloud-netsec-flow-logs-policy"
  role = aws_iam_role.flow_logs_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ]
      Resource = "${aws_cloudwatch_log_group.vpc_flow_logs.arn}:*"
    }]
  })
}

# 4. Collect traffic logs from Public Subnet 1
resource "aws_flow_log" "public_subnet_logs" {
  subnet_id            = aws_subnet.public_1.id
  traffic_type         = "ALL"
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.vpc_flow_logs.arn
  iam_role_arn         = aws_iam_role.flow_logs_role.arn

  depends_on = [aws_iam_role_policy.flow_logs_policy]
}

# 5. Collect traffic logs from Private Subnet 1
resource "aws_flow_log" "private_subnet_logs" {
  subnet_id            = aws_subnet.private_1.id
  traffic_type         = "ALL"
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.vpc_flow_logs.arn
  iam_role_arn         = aws_iam_role.flow_logs_role.arn

  depends_on = [aws_iam_role_policy.flow_logs_policy]
}
