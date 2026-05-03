output "public_ip" {
  value = azurerm_public_ip.pip.ip_address
}
 
output "rdp_command" {
  value = "mstsc /v:${azurerm_public_ip.pip.ip_address}"
}
 
output "private_ip" {
  description = "Static private IP — use this when configuring the Splunk forwarder"
  value       = "10.0.1.4"
}
