variable "env" {
  type = string
}

variable "s3_lifecycle_prevent_destroy" {
  type    = string
  default = "true"
}