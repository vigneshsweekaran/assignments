# Without Service tag
resource "aws_instance" "ubuntu-1" {
    ami = "ami-0ee8244746ec5d6d4"
    instance_type = "t2.micro"

    tags = {
        Name = "without-service-tag"
        Provider = "terraform"
    } 
}

# With Service tag Service=Web
resource "aws_instance" "ubuntu-2" {
    ami = "ami-0ee8244746ec5d6d4"
    instance_type = "t2.micro"

    tags = {
        Name = "with-service-tag-web"
        Provider = "terraform"
        Service = "Web"
    } 
}

# With service tag not matching [Data, Processing, Web,]
resource "aws_instance" "ubuntu-3" {
    ami = "ami-0ee8244746ec5d6d4"
    instance_type = "t2.micro"

    tags = {
        Name = "with-service-tag-test"
        Provider = "terraform"
        Service = "Test"
    } 
}