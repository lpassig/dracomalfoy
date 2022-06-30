 # Get HCP generated AMI 
 data "hcp_packer_iteration" "mongodb-ubuntu" {
   bucket_name = "ubuntu-mongodb-old"
   channel     = "dev"
 }

 data "hcp_packer_image" "mongodb-ubuntu" {
   bucket_name    = data.hcp_packer_iteration.mongodb-ubuntu.bucket_name
   iteration_id   = data.hcp_packer_iteration.mongodb-ubuntu.ulid
   cloud_provider = "azurerm"
   region         = "${var.resource_group_location}"
 }

data "tfe_outputs" "outputs" {
  organization = "propassig"
  workspace = "Slytherin_Azure_LandingZone"
}

resource "azurerm_resource_group" "rg" {
  name      = "project-${var.NAME}"
  location  = nonsensitive(data.tfe_outputs.outputs.values.resource_group_location)

  tags = {
    owner               = "${var.NAME}"
    project             = "project-${var.NAME}"
    terraform           = "true"
    environment         = "dev"
  }
}

resource "azurerm_network_interface" "nic" {
  name                = "${var.NAME}-nic"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  ip_configuration {
    name                          = "${var.NAME}-config"
    subnet_id                     = nonsensitive(data.tfe_outputs.outputs.values.subnet_id)
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "vm" {
  name                  = "${var.NAME}-vm"
  location              = nonsensitive(data.tfe_outputs.outputs.values.resource_group_location)
  resource_group_name   = nonsensitive(data.tfe_outputs.outputs.values.resource_group_name)
  network_interface_ids = ["${azurerm_network_interface.nic.id}"]
  vm_size               = "Standard_F2"

  # This means the OS Disk will be deleted when Terraform destroys the Virtual Machine
  delete_os_disk_on_termination = true

  storage_image_reference {
    id = data.hcp_packer_image.mongodb-ubuntu.cloud_image_id // packer image 
  }

  storage_os_disk {
    name              = "osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile_linux_config {
    disable_password_authentication = true
  }
  
}

module "ec2-instance" {
  source  = "app.terraform.io/propassig/ec2-instance/aws"
  version = "4.0.0"

  name = "${var.NAME}-instance"
                              
  ami                         = data.hcp_packer_image.mongodb-ubuntu.cloud_image_id // packer image (Alternative: "ami-02bcb9d2fae1fc079")
  instance_type               = "t2.micro"
  availability_zone           = nonsensitive(data.tfe_outputs.outputs.values.availability_zone)
  monitoring                  = true
  vpc_security_group_ids      = nonsensitive(data.tfe_outputs.outputs.values.vpc_security_group_ids)
  subnet_id                   = nonsensitive(data.tfe_outputs.outputs.values.subnet_id)
  associate_public_ip_address = true
  iam_instance_profile        = nonsensitive(data.tfe_outputs.outputs.values.instance_profile)

  user_data = file("cloud-init/start-db.yaml")
}

#
##
### EKS
##
#
# data "aws_eks_cluster" "eks-cluster" {
#   name = module.eks.cluster_id
# }

# data "aws_eks_cluster_auth" "eks-cluster" {
#   name = module.eks.cluster_id
# }

# module "eks" {
#   source  = "terraform-aws-modules/eks/aws"

#   cluster_name    = "${var.NAME}-eks"
#   cluster_version = "1.18"
#   subnets         = module.vpc.private_subnets

#   vpc_id = module.vpc.vpc_id

#   node_groups = {
#     alpha = {
#       desired_capacity = 1
#       max_capacity     = 3
#       min_capacity     = 1
#       disk_size        = var.wn-disk-size
#       instance_types   = var.wn-instance-types[var.stage]
#       subnets          = [module.vpc.private_subnets[0]]
#     }

#     beta = {
#       desired_capacity = 1
#       max_capacity     = 3
#       min_capacity     = 1
#       disk_size        = var.wn-disk-size
#       instance_types   = var.wn-instance-types[var.stage]
#       subnets          = [module.vpc.private_subnets[1]]
#     }

#     gamma = {
#       desired_capacity = 1
#       max_capacity     = 3
#       min_capacity     = 1
#       disk_size        = var.wn-disk-size
#       instance_types   = var.wn-instance-types[var.stage]
#       subnets          = [module.vpc.private_subnets[2]]
#     }
#   }
#   workers_additional_policies = ["arn:aws:iam::aws:policy/AmazonElasticFileSystemFullAccess"]

#   write_kubeconfig   = true
#   config_output_path = "./"
# }