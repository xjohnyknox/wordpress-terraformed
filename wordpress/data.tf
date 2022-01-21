data "aws_availability_zones" "zones" {
  state = "available"

}

data "aws_subnet_ids" "subnets" {
  vpc_id = var.vpc_id
}

data "aws_vpc" "vpc" {
  id = var.vpc_id
}

data "aws_ami_ids" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/ubuntu-*-*-amd64-server-*"]
  }
}

data "template_file" "dockercompose" {
  template = <<-EOF
  version: "3.9"
  services:
    wordpress:
        image: wordpress:latest
        restart: always
        environment:
            WORDPRESS_DB_HOST: ${dbhost}
            WORDPRESS_DB_USER: ${dbuser}
            WORDPRESS_DB_PASSWORD: ${dbpassword}
            WORDPRESS_DB_NAME: ${dbname}

    nginx:
        depends_on: 
            - wordpress
        image: nginx:1.18-alpine
        restart: always
        command: "/bin/sh -c 'nginx -s reload; nginx -g \"daemon off;\"'"
        ports:
            - "${external_port}:80"
        volumes:
            - ./nginx:/etc/nginx/conf.d
        
  EOF

  vars = {
      dbhost = aws_rds_cluster.wordpress.endpoint
      dbname = aws_rds_cluster.wordpress.database_name
      dbuser = aws_rds_cluster.wordpress.master_username
      dbpassword = aws_rds_cluster.wordpress.master_password
      external_port = var.nginx_port
  }
}

data "template_file" "nginx_conf" {
    template = <<-EOF

    server {
        listen 80;
        location / {
            proxy_set_header HOST $host;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_pass http://wordpress:80;
        }
    }


    EOF
}

data "template_file" "userdata" {
    gzip = false
    base64_encode = true
    part {
        content_type = "text/x-shellscript"
        content = <<-EOF
        #!/bin/bash
        sudo apt update && sudo apt upgrade -y

        sudo apt install -y apt-transport-https ca-certificates curl software-properties-common gnupg-agent

        # install docker
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
            $(lsb_release -cs) \
            stable"

        sudo apt-get update

        sudo apt-get install docker-ce docker-ce-cli containerd.io -y
        sudo usermod -a -G docker $USER
        sudo usermod -a -G docker ubuntu

        # install docker-compose
        curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /tmp/docker-compose
        chmod +x /tmp/docker-compose
        sudo mv /tmp/docker-compose /usr/local/bin/docker-compose

        # setup wordpress app components
        mkdir -p /var/opt/wp
        mkdir -p /var/opt/wp/nginx
        cd /var/opt/wp

        echo "${dockercompose}" > docker-compose.yml
        echo "${nginx_conf}" > nginx/server.conf

        docker-compose up
        EOF
    }
}