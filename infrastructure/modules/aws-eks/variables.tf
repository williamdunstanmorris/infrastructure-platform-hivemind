variable "cluster_name" {
  type = string
}

variable "cluster_version" {
  type        = string
  description = "Kubernetes version. Check which versions EKS currently supports before picking."
  default     = "1.37"
}

variable "node_instance_types" {
  type    = list(string)
  default = ["t3.medium"] # roughly e2-medium (2 vCPU / 4 GiB)
}

variable "node_min_size" {
  type    = number
  default = 3 # one node per AZ minimum, so losing an AZ still leaves 2/3 capacity
}

variable "node_max_size" {
  type    = number
  default = 9 # one node per AZ minimum, so losing an AZ still leaves 2/3 capacity
}

variable "node_desired_size" {
  type    = number
  default = 3
}
