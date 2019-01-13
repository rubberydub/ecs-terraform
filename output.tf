#
# output.tf
#
# Terraform output.
#

output "ssh-config" {
  value = "${data.template_file.ssh-config.rendered}"
}
