# Automating Active Directory in Azure via Terraform

**Part 2 of 2: Cloud Automation with Infrastructure as Code**

*This project covers the automated cloud deployment of an Active Directory environment. To see the foundational, on-premises manual configuration that preceded this automation, check out* [Active Directory Home Lab: Windows Server 2025](https://github.com/Dane139/ad-home-lab)

### Objective

After manually deploying and configuring a local Active Directory environment, the goal of this project was to transition from localized hypervisor provisioning to **Infrastructure as Code (IaC)**. By utilizing Terraform and Microsoft Azure, I architected a deployment pipeline to programmatically build an enterprise-ready Windows Server 2025 domain controller. This project demonstrates the ability to translate manual administrative tasks into rapid, repeatable, and scalable cloud automation.

### Environment & Tools

- **Cloud Provider:** Microsoft Azure
- **IaC Tool:** Terraform
- **Scripting/CLI:** Azure CLI, PowerShell
- **Code Editor:** Visual Studio Code
- **OS:** Windows Server 2025 Datacenter

---

### Step 1: Defining the Infrastructure (IaC)

Rather than manually configuring networking and compute resources through a web portal, I defined the entire environment using HashiCorp Configuration Language (HCL). I created a modular file structure:

- **`main.tf`:** The core blueprint declaring the Azure Resource Group, Virtual Network (`10.0.0.0/16`), Subnet (`10.0.1.0/24`), Network Interface, and the VM itself.
- **`variables.tf`:** Parameterized the deployment to ensure flexibility (e.g., region, VM size).
- **`outputs.tf`:** Programmed Terraform to dynamically return the public IP address and a pre-formatted `mstsc` (RDP) command upon successful deployment.

<details>
<summary>▶ View main.tf Configuration</summary>

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = "ad-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "ad-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "pip" {
  name                = "ad-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_security_group" "nsg" {
  name                = "ad-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "allow-rdp"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = var.my_ip_address
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "deny-all-inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "nic" {
  name                = "ad-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.4"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

resource "azurerm_network_interface_security_group_association" "nsg_assoc" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_windows_virtual_machine" "vm" {
  name                  = "ad-dc-01"
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  size                  = var.vm_size
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  network_interface_ids = [azurerm_network_interface.nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2025-datacenter-g2"
    version   = "latest"
  }

  # Ensure WinRM is available for remote management
  winrm_listener {
    protocol = "Http"
  }
}
```

</details>

---

### Step 2: Securing the Deployment

To adhere to security best practices, hardcoding credentials into the main configuration files was strictly avoided.

- **Network Security Group (NSG):** Configured an inbound security rule allowing RDP traffic (Port 3389) *strictly* from my local public IP address, supported by a baseline deny-all rule.
- **Secrets Management:** Created a local `terraform.tfvars` file to store the sensitive administrator password and my specific IP address.
- **Version Control Security:** Implemented a `.gitignore` file to ensure the `.tfvars` file and local `.tfstate` files were never committed to public version control.

<details>
<summary>▶ View .gitignore Configuration</summary>

```hcl
# Terraform state — never commit
*.tfstate
*.tfstate.*
.terraform/
.terraform.lock.hcl
 
# Variable files containing secrets
terraform.tfvars
*.tfvars
 
# Crash logs
crash.log
crash.*.log
 
# Generated plan files
*.tfplan
```

</details>

![Gitignore Setup in VS Code](assets/9E891863-F4F3-4DB4-AEA3-4533452F606C.png)

---

### Step 3: Execution and Provisioning

With the Azure CLI authenticated, I initiated the standard Terraform workflow:

1. `terraform init` to initialize the working directory and download the `azurerm` provider.
2. `terraform plan` to validate the syntax and preview the exact resources Azure was preparing to build.
3. `terraform apply` to execute the build.

![Terraform Apply Output](assets/VirtualBoxVM_0Qx4spW9xV.jpg)

---

## Step 4: Verification and Server Configuration

Using the automated RDP output command, I instantly connected to the newly provisioned Azure VM.

From here, the server was a blank slate, mirroring the exact starting point of my previous manual lab. I was able to immediately open PowerShell and execute the AD DS role installation and domain promotion scripts, successfully bridging the gap between automated cloud infrastructure and manual systems administration. The slowest part was recreating the GPOs.

![Azure VM RDP Session](assets/image.png)

---

## What I Learned

- **The Value of IaC:** Experienced firsthand how Infrastructure as Code completely eliminates "click-ops," turning a tedious 20-minute manual network setup into a 3-minute automated deployment.
- **State Management (`.tfstate`):** Gained a practical understanding of how Terraform tracks the real-world state of cloud resources against the local configuration files to ensure idempotency.
- **Dynamic Outputs:** Learned how to leverage Terraform outputs to streamline post-deployment workflows, completely eliminating the need to dig through the Azure portal to find dynamic public IP addresses.
- **Cloud Networking vs. Local Networking:** Transitioned my understanding of VirtualBox NAT/Internal networks into enterprise cloud networking concepts (Azure VNets, Subnets, and Network Security Groups).