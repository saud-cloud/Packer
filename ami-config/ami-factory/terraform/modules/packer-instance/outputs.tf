output "role_arn" {
  value = "${aws_iam_role.S3AccessRole.arn}"
}
output "access_key" {
  value = "${aws_iam_access_key.instruqt.id}"
}
output "secret_key" {
  value = "${aws_iam_access_key.instruqt.encrypted_secret}"
}
