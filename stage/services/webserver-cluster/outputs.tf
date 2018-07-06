output "launch_configuration_id" {
  value = "${aws_launch_configuration.web_example.id}"
}

output "security_groups" {
  value = "${aws_security_group.elb-sg.id}"
}

output "elb_dns_name" {
  value = "${aws_elb.web_example.dns_name}"
}

#output "public_ip" {
#  value = "${aws_instance.example.public_ip}"
#}


#output "public_dns_name" {
#  value = "${aws_instance.example.public_dns}"
#}

