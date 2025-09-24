resource "aws_security_group" "api_sg" {
  name        = "api-sg"
  description = "Allow external HTTP and SSH access to API"

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "api_ec2_role" {
  name = "api-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "api_s3_policy" {
  name = "api-s3-access"
  role = aws_iam_role.api_ec2_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ]
      Resource = [
        var.bucket_arn,
        "${var.bucket_arn}/*"
      ]
    }]
  })
}

resource "aws_iam_instance_profile" "api_instance_profile" {
  name = "api-instance-profile"
  role = aws_iam_role.api_ec2_role.name
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

resource "aws_instance" "api" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  iam_instance_profile        = aws_iam_instance_profile.api_instance_profile.name
  vpc_security_group_ids      = [aws_security_group.api_sg.id]
  key_name                    = aws_key_pair.deployer.key_name

  user_data = <<-EOF
    #!/bin/bash
    set -e

    apt-get update -y
    apt-get install -y wget unzip

    DOTNET_DIR=/usr/share/dotnet

    wget https://dotnet.microsoft.com/download/dotnet/scripts/v1/dotnet-install.sh -O dotnet-install.sh
    chmod +x dotnet-install.sh
    ./dotnet-install.sh --channel 9.0 --install-dir $DOTNET_DIR

    ln -sf $DOTNET_DIR/dotnet /usr/bin/dotnet

    echo "export DOTNET_ROOT=$DOTNET_DIR" > /etc/profile.d/dotnet.sh
    echo "export PATH=\$PATH:\$DOTNET_ROOT" >> /etc/profile.d/dotnet.sh
    chmod +x /etc/profile.d/dotnet.sh

    $DOTNET_DIR/dotnet --list-sdks
    $DOTNET_DIR/dotnet --list-runtimes

    APP_DIR=/home/ubuntu/app
    mkdir -p $APP_DIR
    chown -R ubuntu:ubuntu $APP_DIR

    cat <<EOT > /etc/systemd/system/dotnet-api.service
    [Unit]
    Description=.NET 9 API Service
    After=network.target

    [Service]
    ExecStart=$DOTNET_DIR/dotnet $APP_DIR/Dotnet.Aws.S3.API.dll
    WorkingDirectory=$APP_DIR
    Restart=always
    RestartSec=10
    SyslogIdentifier=dotnet-api
    User=ubuntu
    Environment=DOTNET_ROOT=$DOTNET_DIR
    Environment=ASPNETCORE_URLS=http://0.0.0.0:5000

    [Install]
    WantedBy=multi-user.target
    EOT

    chmod 644 /etc/systemd/system/dotnet-api.service

    systemctl daemon-reload
    systemctl enable dotnet-api
    systemctl start dotnet-api
  EOF

  tags = {
    Name = "ganascimento-dotnetawss3app-api"
  }
}
