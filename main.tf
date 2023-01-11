### Creating Security Group for EC2
resource "aws_security_group" "instance" {
  name = "terraform-app-instance"
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
}

### Creating EC2 instance
resource "aws_instance" "app" {
  ami           = data.aws_ami.amazon_linux_2.id
  key_name	= "${var.key_name}"
  instance_type = "t3.medium"
  root_block_device {
    volume_size = 50
  }
  vpc_security_group_ids = ["${aws_security_group.instance.id}"]
  tags = {
    project = "web-app"
  }
  monitoring              = true
  ebs_optimized           = true
}

### Creating Launch Configuration
resource "aws_launch_configuration" "app" {
  image_id               = data.aws_ami.amazon_linux_2.id
  instance_type          = "t2.medium"
  security_groups        = ["${aws_security_group.instance.id}"]
  key_name               = "${var.key_name}"
  user_data = <<-EOF
    $#!/bin/bash
    set -ex
    sudo yum update -y
    sudo amazon-linux-extras install docker -y
    sudo service docker start
    sudo usermod -a -G docker ec2-user
	sudo docker run -d -p 80:80 --name nginx nginx:latest
  EOF
}

### Creating AutoScaling Group
resource "aws_autoscaling_group" "app" {
  launch_configuration = "${aws_launch_configuration.app.id}"
  availability_zones = ["us-east-2a"]
  min_size = 1
  max_size = 2
}
