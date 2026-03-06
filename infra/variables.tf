variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "cloud-resume-challenge-tf"
}

variable "python_runtime" {
  default = "python3.14"
}

variable "resume_files_to_upload" {
  default = [
    "index.html",
    "styles.css"
  ]
}
