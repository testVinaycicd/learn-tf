resource "aws_cloudwatch_log_group" "web_instance" {
  name              = "/aws/ec2/${var.name}-web"
  retention_in_days = 14
  tags = { Name = "${var.name}-web-log" }
}

resource "aws_cloudwatch_log_metric_filter" "http_5xx" {
  name           = "${var.name}-5xx-filter"
  log_group_name = aws_cloudwatch_log_group.web_instance.name
  pattern        = "[ip, ident, user, ts, request, status=5??, bytes, ...]" # <-- choose the right pattern

  metric_transformation {
    name      = "${var.name}_5xx_count"
    namespace = "MyApp"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "high_5xx" {
  alarm_name          = "${var.name}-High-5xx"
  namespace           = "MyApp"
  metric_name         = "${var.name}_5xx_count"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 5
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_description   = "Alarm when 5xx count >= 5 in 5 minutes"
  insufficient_data_actions = []
}
