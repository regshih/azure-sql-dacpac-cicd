variable "subscription_id" {
  description = "Azure subscription ID. Supply through TF_VAR_subscription_id or an environment tfvars file."
  type        = string
}
variable "tenant_id" {
  description = "Microsoft Entra tenant ID."
  type        = string
}
variable "entra_admin_object_id" {
  description = "Object ID of the OIDC service principal used as SQL administrator."
  type        = string
}
variable "entra_admin_name" {
  description = "Display name of the OIDC service principal used as SQL administrator."
  type        = string
}
variable "environment" {
  description = "Deployment environment."
  type        = string
  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "environment must be dev, test, or prod."
  }
}
variable "location" {
  description = "Azure region."
  type        = string
  default     = "eastus2"
}
variable "region_code" {
  description = "Short region code."
  type        = string
  default     = "eus2"
}
variable "unique_suffix" {
  description = "Globally unique lowercase alphanumeric suffix."
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9]{4,12}$", var.unique_suffix))
    error_message = "unique_suffix must contain 4-12 lowercase letters or digits."
  }
}
variable "private_endpoint_enabled" {
  description = "Create private networking and disable SQL public network access."
  type        = bool
  default     = false
}
variable "key_vault_enabled" {
  description = "Create an optional Key Vault."
  type        = bool
  default     = false
}
variable "database_sku_name" {
  description = "Azure SQL Database SKU."
  type        = string
  default     = "Basic"
}
variable "database_max_size_gb" {
  description = "Maximum database size in GB."
  type        = number
  default     = 2
}
