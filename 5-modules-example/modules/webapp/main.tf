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

  user_data = file("${path.module}/userdata.sh")
}


