variable "region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-2"
}

variable "callback_url" {
  description = "URL para redirección después del login"
  type        = string
  default     = "http://localhost:5500/callback.html"
}

variable "logout_url" {
  description = "URL para redirección después del logout"
  type        = string
  default     = "http://localhost:5500/logout.html"
}