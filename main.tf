### Creating Security Group for EC2
module "ec2_security_group" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "ec2_security_group"
  description = "Security group for ec2_security_group"
  vpc_id      = data.aws_vpc.default.id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "https-443-tcp", "all-icmp", "ssh-22-tcp"]
  egress_rules        = ["all-all"]
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
  count			= "${var.count}"
  key_name		= "${var.key_name}"
  instance_type = "t3.medium"
  root_block_device {
    volume_size = 50
  }
  vpc_security_group_ids = [
    module.ec2_security_group.this_security_group_id
  ]
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
  security_groups        = [module.ec2_security_group.this_security_group_id]
  key_name               = "${var.key_name}"
  user_data = <<-EOF
    #!/bin/bash
    set -ex
    sudo yum update -y
    sudo amazon-linux-extras install docker -y
    sudo service docker start
    sudo usermod -a -G docker ec2-user
	sudo docker run -d -p 80:80 --name nginx nginx:latest
  EOF  lifecycle {
    create_before_destroy = true
  }
}

### Creating AutoScaling Group
resource "aws_autoscaling_group" "app" {
  launch_configuration = "${aws_launch_configuration.app.id}"
  availability_zones = ["${data.aws_availability_zones.all.names}"]
  min_size = 1
  max_size = 1
  tag {
    project = "web-app"
  }
}
