data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0.*-x86_64-gp2"]
  }
}



resource "aws_instance" "ec2_example" {

  ami = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  subnet_id = var.subnet_id
  vpc_security_group_ids = [var.security_group]
  iam_instance_profile = var.iam_instance_profile

  tags = {
    Name = var.name
  }

  user_data = <<-EOF
      #!/bin/sh
      sudo apt-get update
      sudo apt install -y apache2
      sudo systemctl status apache2
      sudo systemctl start apache2
      sudo chown -R $USER:$USER /var/www/html
      sudo echo "<html><body><h1>Hello this is module-1 at instance id `curl http://169.254.169.254/latest/meta-data/instance-id` </h1></body></html>" > /var/www/html/index.html
      EOF
}



output "public_ip" {
  value = aws_instance.ec2_example.public_ip
}