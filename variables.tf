
variable "region" {
  description = "Name of the region to be used"
  type        = string
  default     = "eu-west-2"
}

# Change the default value to your group
variable "s3_access_group" {
  description = "The group the user you are connecting to the infrastructure with belongs to"
  type        = string
  default     = "devops"
}

# Change the below CIDR IPs to what you require. Can be inserted as a list.
variable "whitelisted_ips" {
  description = "List of IPs in CIDR format that will have access to the bastion host"
  type = list(string)
  default = [ "93.96.117.61/32", "52.57.90.250/32" ]
}

variable "users" {
  type = list(object({
    full_name = string
    email     = string
  }))
  default = [
    # {
    #   full_name = "Telmo-Sampaio"
    #   email     = "Telmo.sampaio@generatedhealth.com"
    # },
    # {
    #   full_name = "Kashif-Ahmed"
    #   email     = "kashif.ahmed@generatedhealth.com"
    # },
    # {
    #   full_name = "Vicente-Manzano"
    #   email     = "vicente.manzano@generatedhealth.com"
    # },
  ]
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

variable "bucket_dashboard_group_name" {
  description = "Name of the bucket dashboard group"
  type        = string
  default     = "BucketDashboardGroup"
}
variable "sshkey" {
  description = "Name of the sshkey used to connect to the bastion host"
  type        = string
  default     = "gh-key"
}
