
resource "aws_vpc" "myvpc" {
    cidr_block = var.cidr

    tags = {
      "Name"= "vpc-aws-public-ec2-s3-lb"
    }
}


resource "aws_subnet" "mypublicsubnet1" {
  vpc_id = aws_vpc.myvpc.id
  cidr_block = "10.0.64.0/26"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "mypublicsubnet2" {
  vpc_id = aws_vpc.myvpc.id
  cidr_block = "10.0.64.128/26"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id

}

resource "aws_route_table" "myroutetable" {
  vpc_id = aws_vpc.myvpc.id
  route {
    cidr_block="0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    "Name"= "aws-public-rt"
  }
}

resource "aws_route_table_association" "rt1" {
  subnet_id = aws_subnet.mypublicsubnet1.id
  route_table_id = aws_route_table.myroutetable.id
}

resource "aws_route_table_association" "rt2" {
  subnet_id = aws_subnet.mypublicsubnet2.id
  route_table_id = aws_route_table.myroutetable.id
}

resource "aws_security_group" "mysg" {
  name = "ec2-s3-demo-sg"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }
  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  tags = {
    Name = "ec2-s3-demo-sg"
  }
}

resource "aws_s3_bucket" "mybucket" {
    bucket = "jayanth-terraform-ec2-s3-bucket-erwerwr"

}



resource "aws_instance" "server1" {
    ami= "ami-06aa3f7caf3a30282"
    instance_type = "t2.micro"
    vpc_security_group_ids = [aws_security_group.mysg.id]
    subnet_id = aws_subnet.mypublicsubnet1.id
    user_data = base64encode(file("userdata1.sh"))
}

resource "aws_instance" "server2" {
    ami= "ami-06aa3f7caf3a30282"
    instance_type = "t2.micro"
    vpc_security_group_ids = [aws_security_group.mysg.id]
    subnet_id = aws_subnet.mypublicsubnet2.id
    user_data = base64encode(file("userdata.sh"))
}

### create alb

resource "aws_lb" "web-ec2-alb" {
  name = "web-ec2-alb"
  internal = false

  load_balancer_type = "application"
  security_groups = [ aws_security_group.mysg.id ]

  subnets = [ aws_subnet.mypublicsubnet1.id, aws_subnet.mypublicsubnet2.id]

  tags = {
    "Name"="web-ec2-alb"
  }
}

resource "aws_lb_target_group" "mytg" {
    name="TG"
    port = 80
    protocol = "HTTP"
    vpc_id = aws_vpc.myvpc.id

    health_check {
      path = "/"
      port = "traffic-port"
    }
}

resource "aws_lb_listener" "lb-listener" {
  load_balancer_arn = aws_lb.web-ec2-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.mytg.arn
  }
}

resource "aws_lb_target_group_attachment" "tg-attach1" {
  target_group_arn = aws_lb_target_group.mytg.arn
  target_id        = aws_instance.server1.id
  port             = 80
}
resource "aws_lb_target_group_attachment" "tg-attach2" {
  target_group_arn = aws_lb_target_group.mytg.arn
  target_id        = aws_instance.server2.id
  port             = 80
}

output "lb-dns-name" {
    value = aws_lb.web-ec2-alb.dns_name
  
}