# ☁️ Cloud Architecture Project

This repository contains my practical work building a cloud architecture portfolio focused on core AWS services, deployed locally using LocalStack and Terraform. The goal was to create scalable, maintainable serverless infrastructure for local testing and development.

---

## 🎯 Project Goals

- Gain hands-on experience designing and managing cloud infrastructure with Terraform and AWS services.  
- Build a solid foundation with core AWS components.  
- Use LocalStack to speed iteration and avoid AWS costs during early stages.  
- Create reusable Terraform configurations and deployment scripts.  
- Maintain documentation and logs tracking progress and challenges.  

---

## 🔍 Completed Scope

- Two-tier serverless backend using API Gateway, Lambda, and DynamoDB deployed locally.  
- Infrastructure fully defined and managed with Terraform.  
- Local emulation of key AWS services for realistic testing.  
- Secure environment variable and IAM role management for Lambda.  
- Automation scripts for starting, stopping, and cleaning LocalStack and Terraform resources.  

---

## ⚠️ Important Notes

- This project was primarily used to gain practical experience with Terraform and core AWS services locally.  
- For live AWS deployments and expanded services, see my separate AWS project utilizing the free tier.  

---

## 📂 Project Structure

- `/terraform` — Terraform configurations and modules with clear descriptions above each resource block explaining their purpose.  
- `/lambda` — Lambda function code and deployment packages.  
- `/docs` — Daily logs and notes on development progress.  
- `/scripts` — Automation scripts for managing the local environment with detailed comments.  
- `README.md` — Project overview and status.  

---

*This project is complete for local development. Refer to my AWS project for live deployment.*