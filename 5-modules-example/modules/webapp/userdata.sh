#!/bin/bash
set -euxo pipefail

# Update + install httpd on Amazon Linux 2
yum update -y
yum install -y httpd

# Enable & start
systemctl enable --now httpd

# Write index page
cat > /var/www/html/index.html <<'HTML'
<html>
  <body>
    <h1>Hello from module-1</h1>
    <p>Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)</p>
    <p>Local IP: $(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)</p>
  </body>
</html>
HTML

# Set ownership/permissions (apache user on Amazon Linux is apache)
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html

# Print status to cloud-init logs
systemctl status httpd --no-pager || true
journalctl -u httpd -n 200 --no-pager || true


#yum install -y amazon-cloudwatch-agent
#
#cat > /opt/aws/amazon-cloudwatch-agent/bin/config.json <<'EOF'
#{
#  "agent": {
#    "metrics_collection_interval": 60,
#    "run_as_user": "root"
#  },
#  "metrics": {
#    "append_dimensions": {
#      "AutoScalingGroupName": "${aws:AutoScalingGroupName}",
#      "InstanceId": "${aws:InstanceId}"
#    },
#    "metrics_collected": {
#      "cpu": {
#        "measurement": [ "cpu_usage_idle", "cpu_usage_iowait" ],
#        "metrics_collection_interval": 60,
#        "totalcpu": true
#      },
#      "mem": {
#        "measurement": [ "mem_used_percent" ],
#        "metrics_collection_interval": 60
#      },
#      "disk": {
#        "measurement": [ "disk_used_percent" ],
#        "metrics_collection_interval": 300,
#        "resources": [ "/" ]
#      }
#    }
#  },
#  "logs": {
#    "logs_collected": {
#      "files": {
#        "collect_list": [
#          {
#            "file_path": "/var/log/messages",
#            "log_group_name": "/aws/ec2/${var.name}-web",
#            "log_stream_name": "{instance_id}",
#            "timestamp_format": "%b %d %H:%M:%S"
#          },
#          {
#            "file_path": "/var/log/httpd/access_log",
#            "log_group_name": "/aws/ec2/${var.name}-web-http",
#            "log_stream_name": "{instance_id}-http",
#            "timestamp_format": "%d/%b/%Y:%H:%M:%S %z"
#          },
#          {
#            "file_path": "/var/log/httpd/error_log",
#            "log_group_name": "/aws/ec2/${var.name}-web-http",
#            "log_stream_name": "{instance_id}-error",
#            "timestamp_format": "%b %d %H:%M:%S"
#          }
#        ]
#      }
#    }
#  }
#}
#EOF
#
## Start the agent with the config
#/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json -s
#Notes: