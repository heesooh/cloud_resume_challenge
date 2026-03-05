variable "aws_region" {
    default = "us-east-1"
}

variable "resume_files_to_upload" {
    default = [
        "index.html",
        "styles.css"
    ]
}

locals {
    # S3 object Content Type Lookup Table
    content_types = {
        ".html" = "text/html"
        ".css"  = "text/css"
        ".js"   = "application/javascript"
        ".png"  = "image/png"
        ".jpg"  = "image/jpeg"
    }

    # Update FrontEnd Script API URL with API Gateway Endpoint (In Memory)
    counter_script = templatefile("../frontend/script.js.tpl", {
        api_url = trimsuffix(aws_apigatewayv2_stage.visitor_count_api_stage.invoke_url, "/")
    })
}
