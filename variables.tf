variable "username" {
  description = "Name of the existing IAM user"
  type        = string
  default     = "existing-user-name"
}

variable "region" {
  description = "Name of the region to be used"
  type        = string
  default     = "eu-west-2"
}

variable "gh_bucket_name" {
  description = "Name of the S3 bucket used to store files"
  type        = string
  default     = "gh-bucket-files"
}

variable "gh_bucket_log" {
  description = "Name of the S3 bucket used for logs"
  type        = string
  default     = "gh-bucket-log"
}
variable "email_suffix" {
  description = "Email suffix for the generatedhealth.com domain"
  type        = string
  default     = "@generatedhealth.com"
}

variable "bucket_dashboard_group_name" {
  description = "Name of the bucket dashboard group"
  type        = string
  default     = "BucketDashboardGroup"
}

variable "users" {
  type = list(object({
    full_name = string
    email     = string
  }))
  default = [
    {
      full_name = "Telmo-Sampaio"
      email     = "Telmo.sampaio@generatehealth.com"
    },
    {
      full_name = "Kashif-Ahmed"
      email     = "kashif.ahmed@generatehealth.com"
    },
    {
      full_name = "Vicente-Manzano"
      email     = "vicente.manzano@generatehealth.com"
    },
    {
      full_name = "rennie-tanti"
      email     = "tanti.rennie@gmail.com"
      username  = "rentan"
    }
  ]
}

variable "sshkey" {
  description = "Name of the sshkey used to connect to the bastion host"
  type        = string
  default     = "gh-key"
}
