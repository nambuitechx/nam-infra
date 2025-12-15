data "http" "my_ip" {
  url = "https://api.ipify.org"
}

locals {
  region  = "ap-southeast-1"
  prefix  = "nam-vpc"
  my_ip   = "${chomp(data.http.my_ip.response_body)}/32"
  ami     = "ami-05f071c65e32875a8" 
}
