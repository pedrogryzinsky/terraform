resource "aws_key_pair" "development_key" {
  key_name   = "development-key"
  public_key = var.public_key
}
