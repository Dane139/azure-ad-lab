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

---

### Step 2: Securing the Deployment

To adhere to security best practices, hardcoding credentials into the main configuration files was strictly avoided.

- **Network Security Group (NSG):** Configured an inbound security rule allowing RDP traffic (Port 3389) *strictly* from my local public IP address, supported by a baseline deny-all rule.
- **Secrets Management:** Created a local `terraform.tfvars` file to store the sensitive administrator password and my specific IP address.
- **Version Control Security:** Implemented a `.gitignore` file to ensure the `.tfvars` file and local `.tfstate` files were never committed to public version control.


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