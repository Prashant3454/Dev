provider "aws" {
  region = "ap-south-1"
}

resource "aws_iam_role" - "lambda-role" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sidi    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
    tags = {
    Name = "lambda-ec2-role"
  }
}

resource "aws_iam_policy" "lambda-policy" {
  name = "lambda-ec2-stop-start"

  policy = jsonencode({
    Version = "2012-10-17"
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:::*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeRegions",
        "ec2:StartInstances",
        "ec2:StopInstances"
      ],
      "Resource": "*"
    }
  ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda-ec2-policy-attach" {
  policy_arn = aws_iam_policy.lambda-policy.arn
  role = aws_iam_role.lambda-role.name
}

# Lambda function to START EC2 Instance

resource "aws_lambda_function" "ec2-start" {
  filename      = "lambda-start.zip"
  function_name = "lambda-start"
  role          = aws_iam_role.lambda-role.arn
  handler       = "lambda-start.lambda_handler"

  source_code_hash = filebase64sha256("lambda-start.zip")

  runtime = "python3.7"
  timeout = 63
}

resource "aws_cloudwatch_event_rule" "ec2-rule-start" {
  name        = "ec2-rule-start"
  description = "Trigger to Start Instance at 8 AM" #Instance will start at 8 AM MON-FRI
  schedule_expression = "cron(0 8 ? * MON-FRI *)"
}

resource "aws_cloudwatch_event_target" "lambda-func-start" {
  rule      = aws_cloudwatch_event_rule.ec2-rule-start.name
  target_id = "lambda"
  arn       = aws_lambda_function.ec2-start.arn
}

resource "aws_lambda_permission" "allow_cloudwatch-start" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ec2-start.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ec2-rule-start.arn
}

# Lambda function to STOP EC2 Instance

resource "aws_lambda_function" "ec2-stop" {
  filename      = "lambda-stop.zip"
  function_name = "lambda-stop"
  role          = aws_iam_role.lambda-role.arn
  handler       = "lambda-stop.lambda_handler"

  
  source_code_hash = filebase64sha256("lambda-stop.zip")

  runtime = "python3.7"
  timeout = 63
}

resource "aws_cloudwatch_event_rule" "ec2-rule-stop" {
  name        = "ec2-rule-stop"
  description = "Trigger to Stop Instance at 6 PM"
  schedule_expression = "cron(0 18 ? * MON-FRI *)" #Instance will stop at 6 PM MON-FRI 
}

resource "aws_cloudwatch_event_target" "lambda-func-stop" {
  rule      = aws_cloudwatch_event_rule.ec2-rule-stop.name
  target_id = "lambda"
  arn       = aws_lambda_function.ec2-stop.arn
  depends_on = [aws_cloudwatch_event_rule.ec2-rule-stop]
    
}
resource "aws_lambda_permission" "allow_cloudwatch-stop" {
  statement_id  = "AllowExecution-FromCloudWatch"
}
