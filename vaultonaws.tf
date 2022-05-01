provider "aws" {
  region = "ca-central-1"
  access_key = "YOUR_ACCESS_KEY"
  secret_key = "YOUR_SECRET_KEY"
}


data "aws_ami" "amazon_linux" {
most_recent = true
  filter {
    name = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
  owners = ["amazon"]
}

output "amazon_linux" {
  value = data.aws_ami.amazon_linux.id
}

resource "aws_instance" "myec2" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  key_name               = "YOUR_EC2_ACCESS_KEY_NAME"
  vpc_security_group_ids = [aws_security_group.allow_access.id]

  provisioner "remote-exec" {
    inline = [
      "sudo yum install -y httpd",
      "sudo systemctl start httpd",
      "sudo wget https://releases.hashicorp.com/vault/1.10.2/vault_1.10.2_linux_amd64.zip",
      "sudo unzip vault_1.10.2_linux_amd64.zip",
      "sudo chmod 777 vault",
      "./vault server -dev -dev-listen-address=\"$(hostname -i):8200\""
    ]
    on_failure = continue
    
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("./YOUR_EC2_ACCESS_KEY.pem")
      host        = self.public_ip
    }
  }
}
output "myec2" {
  value = aws_instance.myec2.public_ip
}

### NOTE - Adding a new security group resource to allow the terraform provisioner from laptop to connect to EC2 Instance via SSH.

resource "aws_security_group" "allow_access" {
  name        = "allow_admin_access"
  description = "Allow inbound traffic from specific IP"

  ingress {
    description = "HTTP into VPC"
    from_port   = 8200
    to_port     = 8200
    protocol    = "tcp"
    cidr_blocks = ["your_ip/32"]
  }
  ingress {
    description = "HTTPS into VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["your_ip/32"]
  }
  ingress {
    description = "SSH into VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["your_ip/32"]
  }
  egress {
    description = "Outbound Allowed"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
