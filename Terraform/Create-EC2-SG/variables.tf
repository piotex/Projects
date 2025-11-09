variable "vpc_id" {
    default = "vpc-0bc74542e890accc2"
}

variable "ec2_instance_type" {
    default = "t3.micro"
}

variable "ec2_ami" {
    default = "ami-0444794b421ec32e4"
}

variable "ec2_key_name" {
    default = "web-ec2-key"
}