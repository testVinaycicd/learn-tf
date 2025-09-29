resource "aws_cloudwatch_log_group" "web_instance" {
  name              = "/aws/ec2/${var.name}-web"
  retention_in_days = 14
  tags = { Name = "${var.name}-web-log" }
}

resource "aws_cloudwatch_log_metric_filter" "http_5xx" {
  name           = "${var.name}-5xx-filter"
  log_group_name = aws_cloudwatch_log_group.web_instance.name
  # Use wildcards instead of regex
  pattern        = "\" 5?? \""

  metric_transformation {
    name      = "${var.name}_5xx_count"
    namespace = "MyApp"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "high_5xx" {
  alarm_name          = "${var.name}-High-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = aws_cloudwatch_log_metric_filter.http_5xx.metric_transformation[0].name
  namespace           = aws_cloudwatch_log_metric_filter.http_5xx.metric_transformation[0].namespace
  period              = 300
  statistic           = "Sum"
  threshold           = 5

  alarm_description           = "Alarm when 5xx count is high"
  insufficient_data_actions   = []
}



resource "aws_cloudwatch_metric_alarm" "high_cpu_cwagent" {
  alarm_name          = "${var.name}-HighCPU-CWAgent"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  threshold           = 80
  treat_missing_data  = "missing"

  # 60s if your agent publishes every 60s
  # (period is defined on the metric query below)

  metric_query {
    id = "m1"
    metric {
      namespace   = "CWAgent"
      metric_name = "cpu_usage_idle"
      period      = 60
      stat        = "Average"
      dimensions = {
        InstanceId = var.ec2_instance_id
      }
    }
    return_data = false
  }

  metric_query {
    id          = "e1"
    expression  = "100 - m1"
    label       = "CPUUtilization (CWAgent)"
    return_data = true
  }

  alarm_description = "Alarm when CPU > 80% computed from CWAgent metrics"
}
