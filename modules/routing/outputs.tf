output "web_route_table_id" {
  description = "ID of the web route table"
  value       = aws_route_table.mktc_rtb_web.id
}