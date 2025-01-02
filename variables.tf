variable "instance_type" { default = "t2.micro" }
variable "db_instance_class" { default = "db.t3.micro" }
variable "db_name" { default = "webapp_db" }
variable "db_username" { default = "admin" }
variable "db_password" { default = "test1234" }
variable "key_name" { default = "my-key" }
variable "vpc_cidr" { default = "172.16.1.0/24" }
variable "subnet_cidr_1" { default = "172.16.1.0/27" }
variable "subnet_cidr_2" { default = "172.16.1.32/27" }
variable "subnet_cidr_3" { default = "172.16.1.64/27" }
variable "subnet_cidr_4" { default = "172.16.1.96/27" }
variable "allowed_ip" { default = ["0.0.0.0/0"] } # 모든 IP 허용''' # 키 페어 생성