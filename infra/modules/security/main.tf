resource "aws_key_pair" "ec2_key" {
  key_name   = "${var.stage}-ec2-key"
  public_key = var.public_key
}
