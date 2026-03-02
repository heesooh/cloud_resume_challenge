variable "aws_region" {
    default = "us-east-1"
}

variable "resume_files_to_upload" {
    default = [
        "index.html",
        "styles.css",
        "script.js"
    ]
}
