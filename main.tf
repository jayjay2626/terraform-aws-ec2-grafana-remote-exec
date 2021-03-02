// defining a few local variables
locals {
    // copied from my aws account
    vpc_id                  = "vpc-f072c48a"
    subnet_id               = "subnet-acfa9df0"
    ssh_user                = "ubuntu"
    key_name                = "jayjay"
    private_key_path        = "jayjay.pem" // make sure .gitignore ignore this file and don't upload it to github
}

provider "aws" {
  region = "us-east-1"
}

// create custom security group
resource "aws_security_group" "grafana-sg" {
  name        = "grafana-sg"
  description = "Allow ssh http https jenkins inbound traffic"
  vpc_id = local.vpc_id

  // ssh port 22
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // http port 80
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // https port 443
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // jenkins port 8080
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // rangeley826_flaskapp port 5000
  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  //  prometheus port 8001
  ingress {
    from_port   = 8001
    to_port     = 8001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  //  grafana port 3000
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # // tired of adding exception but NOT best practices
  # //  open to all port which is not safe
  # ingress {
  #   from_port   = 0
  #   to_port     = 0
  #   protocol    = "-1"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  // outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


}

resource "aws_instance" "grafana" {
  ami                     = "ami-03d315ad33b9d49c4"
  subnet_id               = local.subnet_id     //"subnet-acfa9df0"
  instance_type           = "t2.micro"
  key_name = local.key_name
  security_groups        = [aws_security_group.grafana-sg.id]

  provisioner "remote-exec" {
    
    connection {
        type            = "ssh"
        user            = local.ssh_user
        private_key     = file(local.private_key_path)
        host            = aws_instance.grafana.public_ip
        #agent           = false
        #timeout         = "2m"
    }

    // install jenkins, docker, 
    inline = [
      # "sudo apt update && sudo apt upgrade -y",
      # "sudo apt install openjdk-11-jdk -y",
      # "wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -",
      # "sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'",
      # "sudo apt update && sudo apt install jenkins -y",
      # "sudo ufw allow 8080",
      # #"sudo ufw enable",
      # "sudo systemctl start jenkins",
      # //"sudo cat /var/lib/jenkins/secrets/initialAdminPassword >> jenkins_password.txt"
      # "echo 'Jenkins has been installed'",

      // installing docker
      "sudo apt update && sudo apt upgrade -y",
      "sudo apt install apt-transport-https ca-certificates curl software-properties-common -y",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
      "sudo add-apt-repository 'deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable'",
      "sudo apt update && sudo apt upgrade -y",
      "sudo apt install docker-ce -y",
      "sudo usermod -aG docker ubuntu",
      "echo 'Docker has been installed'",
      "sudo docker run -d -p 8080:3000 --name grafana grafana/grafana"

    ]
  }

   provisioner "local-exec" {
    command = "echo ${aws_instance.grafana.public_ip} > public_ip.txt"
  }


  tags = {
    Name = "flaskapp"
  }

}

  output "grafana_public_ip" {
      value = aws_instance.grafana.public_ip
  }

