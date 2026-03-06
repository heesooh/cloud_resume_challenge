locals {
  name_prefix = var.project_name

  # S3 Object Content Type Lookup Table
  content_types = {
    html = "text/html"
    css  = "text/css"
    js   = "application/javascript"
    json = "application/json"
    png  = "image/png"
    jpg  = "image/jpeg"
    svg  = "image/svg+xml"
    txt  = "text/plain"
  }

  # Update FrontEnd Script API URL with API Gateway Endpoint (In Memory)
  counter_script = templatefile("../frontend/out/resume/script.js.tpl", {
    api_url = trimsuffix(aws_apigatewayv2_stage.visitor_count_api_stage.invoke_url, "/")
  })
}
