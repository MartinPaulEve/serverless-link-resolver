output "doi_put-url" {
  value = "${aws_api_gateway_deployment.lr.invoke_url}"
}