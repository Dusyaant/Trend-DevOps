# 🚀 DevOps Capstone Project: Trendify CI/CD Pipeline

![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-232F3E?style=for-the-badge&logo=amazon-aws&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)
![Jenkins](https://img.shields.io/badge/Jenkins-D24939?style=for-the-badge&logo=jenkins&logoColor=white)

An end-to-end DevOps pipeline automating the containerization, infrastructure provisioning, and deployment of a static web application ("Trendify") to a managed AWS Elastic Kubernetes Service (EKS) cluster.

## 📋 Project Overview
This repository contains the infrastructure as code (IaC), containerization, and Kubernetes configuration required to deploy the Trendify application. The primary goal of this capstone is to demonstrate a fully automated Continuous Integration and Continuous Deployment (CI/CD) pipeline.

### 🛠️ Tech Stack & Tools
* **Containerization:** Docker, Docker Hub
* **Infrastructure as Code (IaC):** Terraform
* **Cloud Provider:** Amazon Web Services (VPC, EC2, EKS, ELB, IAM)
* **Container Orchestration:** Kubernetes (`kubectl`)
* **CI/CD Automation:** Jenkins (Declarative Pipeline, GitHub Webhooks)
* **Monitoring:** Kubernetes Metrics Server (Open-source)
* **Version Control:** Git, GitHub

---

## 🏗️ Architecture & CI/CD Pipeline Explanation

The deployment process is fully automated via Jenkins. The pipeline executes the following stages:
1. **Source Control:** Developer pushes code changes to the `main` branch on GitHub.
2. **Trigger:** A GitHub Webhook automatically triggers the Jenkins pipeline.
3. **Build:** Jenkins builds the Docker image from the provided `Dockerfile` (Configured to run Nginx on port `3000`).
4. **Push:** Jenkins authenticates and pushes the new image (`prospendeo/trend-app:latest`) to Docker Hub.
5. **Deploy:** Jenkins authenticates with AWS EKS (`update-kubeconfig`) and executes `kubectl apply` to roll out the latest `k8s-deployment.yaml` configurations.
6. **Expose:** The Kubernetes Service provisions an AWS Load Balancer to route external HTTP traffic to the application on port `3000`.

---

## ⚙️ Setup & Deployment Instructions

### 1. Infrastructure Provisioning (Terraform)
The underlying AWS infrastructure (VPC, Subnets, Jenkins EC2 instance, EKS Cluster, and Worker Nodes) is managed via Terraform.
```bash
terraform init
terraform plan
terraform apply --auto-approve

```

### 2. Jenkins Configuration

* Installed Jenkins on the provisioned Ubuntu 24.04 EC2 instance.
* Installed required plugins: Docker Pipeline, Kubernetes CLI, AWS Credentials, Git.
* Added global credentials for Docker Hub (`prospendeo`) and AWS IAM access keys.
* Created a Pipeline project and integrated it with the GitHub repository URL.

### 3. Application Deployment

The Kubernetes deployment consists of a ReplicaSet of 2 pods and a LoadBalancer service.

```bash
# Apply the deployment manually if bypassing Jenkins
kubectl apply -f k8s-deployment.yaml

```

### 4. Cluster Monitoring (Metrics Server)

To fulfill the open-source monitoring requirement, the official Kubernetes Metrics Server was deployed to track node and pod resource utilization (CPU/Memory).

```bash
# Install Metrics Server
kubectl apply -f [https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml](https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml)

# View live resource utilization
kubectl top nodes
kubectl top pods

```

---

## ⚠️ Important Note: AWS Load Balancer (ARN vs DNS)

*Submission Guideline Note:* By default, Kubernetes provisions an AWS Classic Load Balancer (CLB), which uses a **DNS Name** instead of an **ARN**.

During deployment, an attempt was made to provision a Network Load Balancer (NLB) via the `service.beta.kubernetes.io/aws-load-balancer-type: nlb` annotation to generate a standard ARN. However, due to a strict AWS account restriction on this tier (`OperationNotPermitted: This AWS account currently does not support creating load balancers`), the NLB creation was blocked.

As a result, the application was successfully exposed via the Classic Load Balancer. The live application was accessed via the following DNS Name:

* **Load Balancer URL:** `http://a7b449ee47fbc4140af262e4e1eca1c2-1417524296.us-east-1.elb.amazonaws.com`

---

## 📸 Project Evidence & Screenshots

All visual proof of the working pipeline, infrastructure, and application can be found in the `/screenshots` directory of this repository.

* `1_Local_Docker_Container_Running.png` - App containerized on port 3000.
* `2_DockerHub_Image_Pushed.png` - Docker Hub repository updated.
* `3_Terraform_Apply_Success.png` - AWS infrastructure successfully built.
* `4_Jenkins_Pipeline_Dashboard.png` - CI/CD pipeline automation success.
* `6_Jenkins_Git_Webhook_Trigger.png` - Webhook integration.
* `8_Trendify_App_Live_AWS_ELB.jpg` - Live app running on AWS Load Balancer.
* `11_Metrics_Server_Resource_Usage.png` - `kubectl top` CPU/Memory monitoring data.

---

## 🧹 Cleanup

To prevent ongoing AWS charges, the environment can be securely torn down in the following order:

```bash
# 1. Delete Kubernetes resources to detach the AWS Load Balancer
kubectl delete -f k8s-deployment.yaml

# 2. Destroy the AWS infrastructure via Terraform
terraform destroy --auto-approve

```

---

**Author:** Dusyaant R.

Your capstone project is now fully documented, highly professional, and ready to be graded!

```
