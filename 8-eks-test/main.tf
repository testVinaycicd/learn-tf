data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = ["mikey-vpc"]
  }

  filter {
    name   = "cidr"
    values = ["10.0.0.0/16"]
  }
}

output "vpc_id" {
  value = data.aws_vpc.selected.id
}