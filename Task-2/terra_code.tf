provider "aws"{
	region = "ap-south-1"
	profile = "mr-halkat"
}

resource "aws_instance" "MyInstance" {
	ami = "ami-052c08d70def0ac62" //rhel os image provided -comes under free tier	
	instance_type = "t2.micro"
	key_name = "mykey" //Key Name 
	security_groups = ["launch-wizard-4"]

	connection {
		type = "ssh"
		user = "ec2-user"
		private_key = file("C:/Users/Adi/Downloads/mykey.pem") // Key location in your localhost desktop
		host = aws_instance.MyInstance.public_ip
	}
	provisioner "remote-exec" {
		inline = [
		"sudo yum install httpd php git -y",
		"sudo systemctl restart httpd",
		"sudo systemctl enable httpd",
		]
	}
	tags = {
		Name = "MyOS1"
		}
}


resource "aws_security_group" "rh-security-1" {
  name        = "rh-security-1"
  description = "Allow TLS inbound traffic"

  ingress {
    description = "TCP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "allow_NFS"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "RH-Security"
  }
}



 
resource "aws_efs_file_system" "efs" {
  creation_token = "aws-efs"
 
  tags = {
    Name = "EFS"
  }
}


resource "aws_efs_mount_target" "target1" {
  file_system_id = aws_efs_file_system.efs.id
  subnet_id = "subnet-45acc709"
  security_groups = [aws_security_group.rh-security-1.id]
}

resource "aws_efs_mount_target" "target2" {
  file_system_id = aws_efs_file_system.efs.id
  subnet_id = "subnet-4ba59f23"
  security_groups = [aws_security_group.rh-security-1.id]
}

resource "aws_efs_mount_target" "target3" {
  file_system_id = aws_efs_file_system.efs.id
  subnet_id = "subnet-cda914b6"
  security_groups = [aws_security_group.rh-security-1.id]
}
  

resource "aws_efs_access_point" "efs_ap" {
  file_system_id = aws_efs_file_system.efs.id
}


resource "aws_s3_bucket" bucket-for-image-source {
  bucket = bucket-for-image-source
  acl    = "public-read"
  region = "ap-south-1"

  tags = {
    Name = "S3_Bucket"
  }
}

resource "aws_s3_bucket_public_access_block" "taskbucketpolicy" {
  bucket = aws_s3_bucket.rhel-s3-bucket01.id


  block_public_acls   = false
  block_public_policy = false
}

locals {
  s3_origin_id = "aws_s3_bucket.bucket-for-image-source.id"
}

resource "aws_s3_bucket_object" bucket-for-image-source {
  bucket = bucket-for-image-source
  key    = "image.png"
  source = "/terraform/test/image.png"
}

resource "aws_s3_bucket_public_access_block" "s3_public" {
  bucket = bucket-for-image-source

  block_public_acls   = false
  block_public_policy = false
}

resource "aws_cloudfront_distribution" "cloudfront_dist" {
  origin {
    domain_name = aws_s3_bucket.rhel-s3-bucket01.bucket_regional_domain_name
    origin_id   = local.s3_origin_id

    custom_origin_config {
      http_port = 80
      https_port = 80
      origin_protocol_policy = "match-viewer"
      origin_ssl_protocols = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }
  
  enabled = true

  default_cache_behavior {
    allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl = 0
    default_ttl = 3600
    max_ttl = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

#Mounting the EFS volume
resource "null_resource" "mounting" {

  depends_on = [
    aws_efs_mount_target.target1,
    aws_efs_mount_target.target2,
    aws_efs_mount_target.target3,
  ]

  connection {
    type = "ssh"
    user = "ec2-user"
    private_key = file("C:/Users/Adi/Downloads/mykey.pem")
    host = aws_instance.rhel_apache_server.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install nfs-utils amazon-efs-utils -y",
      "sudo rm -rf /var/www/html",
      "sudo mkdir /var/www/html",
      "sudo mount -t efs ${aws_efs_file_system.efs.id}:/ /var/www/html/",
      "sudo chmod go+rw /var/www/html",
      "sudo git clone https://github.com/adi-001/Terraform-workspace.git /var/www/html",
      "sudo sed -i 's/url/${aws_cloudfront_distribution.cloudfront_dist.domain_name}/g' /var/www/html/index.html",
      "sudo systemctl restart httpd"
    ]
  }
}


output "az" {
  value = aws_instance.rhel_apache_server.availability_zone
}

output "ip" {
  value = aws_instance.rhel_apache_server.public_ip
}

