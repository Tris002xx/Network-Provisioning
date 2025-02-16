# https://developer.hashicorp.com/packer/docs/templates/hcl_templates/blocks/packer
packer {
  required_plugins {
    amazon = {
      version = ">= 1.3"
      source  = "github.com/hashicorp/amazon"
    }
  }
}
# https://developer.hashicorp.com/packer/docs/templates/hcl_templates/blocks/source
source "amazon-ebs" "ubuntu" {
  ami_name      = "web-nginx-aws"
  instance_type = "t2.micro"
  region        = "us-west-2"

  source_ami_filter {
    filters = {
      # Using a wildcard filter for Ubuntu 24.04 AMIs
      name                = "ubuntu/images/hvm-ssd/ubuntu-24.04-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }

  ssh_username = "ubuntu"
}
# https://developer.hashicorp.com/packer/docs/templates/hcl_templates/blocks/build
build {
  name    = "web-nginx"
  sources = [
    "source.amazon-ebs.ubuntu"
  ]
    # https://developer.hashicorp.com/packer/docs/templates/hcl_templates/blocks/build/provisioner
  # Create necessary directories and adjust ownership.
  provisioner "shell" {
    inline = [
      "echo Creating required directories...",
      "sudo mkdir -p /web/html",   // Document root for HTML file as per nginx.conf
      "sudo mkdir -p /tmp/web",      // Location for nginx config file staging
      "sudo chown -R ubuntu:ubuntu /web/html",
      "sudo chown -R ubuntu:ubuntu /tmp/web"
    ]
  }

  # Place the HTML file into the document root.
  provisioner "file" {
    source      = "files/index.html"
    destination = "/web/html/index.html"
  }

  # Place the nginx configuration file into /tmp/web as expected by the setup script.
  provisioner "file" {
    source      = "files/nginx.conf"
    destination = "/tmp/web/nginx.conf"
  }

  # Install Nginx and configure it using the provided shell script commands.
  provisioner "shell" {
    inline = [
      "echo Updating package index and installing Nginx...",
      "sudo apt update",
      "sudo apt install -y nginx",
      "",
      "echo Setting up Nginx configuration files...",
      "sudo cp /tmp/web/nginx.conf /etc/nginx/sites-available/",
      "sudo unlink /etc/nginx/sites-enabled/* || true",  // Unlink any existing enabled sites
      "sudo ln -s /etc/nginx/sites-available/nginx.conf /etc/nginx/sites-enabled/",
      "",
      "echo Enabling and restarting Nginx...",
      "sudo systemctl enable nginx",
      "sudo systemctl restart nginx"
    ]
  }
}
