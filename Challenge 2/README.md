# Web Platform — Architecture & CI/CD

Reference design สำหรับระบบภายในที่มี Web, API, Integration และ Apache Airflow รองรับ `dev`, `staging`, `prod` และเชื่อมต่อ cloud/on-premises

## Architecture

![Architecture](diagrams/[CRL]Architecture-diagram.svg)

- ใช้ AWS Organizations แยก `Shared Services`, `Security & Obsevbility`, `Connectivity hub`, `Dev`, `Staging`, `Prod`
- Hub VPC รวม DNS, Transit Gateway, VPN/Direct Connect และ egress
- แต่ละ environment มี Account, VPC, EKS, RDS, Secret และ Terraform state ของตนเอง
- Internal ALB รับ HTTPS -> App และ DB ที่อยู่ private subnet
- EKS เอาไว้ hosted Web, API, Integration และ Airflow บน EC2 managed node groups
- RDS PostgreSQL ไม่เปิด public access และรับ traffic เฉพาะจาก app ใน security group
- Secondary Region เป็น DR optional

### Main flow

1. Employee → Private DNS → Internal ALB
2. ALB → Web/API/Airflow บน EKS
3. App/Airflow → RDS, S3 หรือ external data source (API/DB)
4. Hybrid Traffic → Transit Gateway (Routing) → VPN หรือ Direct Connect 
5. Logs/metrics → CloudWatch + Secrets Manager + KMS

## CI/CD

![CI/CD](diagrams/cicd-pipeline.svg)

ใช้หลักการ: **Build once, promote the same image digest** โดยไม่ build image ใหม่ระหว่าง environment

### Application

1. Developer เปิด Pull Request
2. Jenkins รัน test และ security scan
3. Jenkins build image, scan/sign และ push Amazon ECR
4. Argo CD deploy Dev
5. QA/App Owner อนุมัติ Staging
6. Release Manager อนุมัติ Production ถ้ามีระบบ ITSM สามารถเพิ่ม Change manage มาอนุมัติอีกคน
7. Argo CD deploy canary; CloudWatch ตรวจ health gate
8. ถ้าไม่ผ่าน → Git revert และ rollback

### Infrastructure

1. Platform Engineer เปิด Terraform PR
2. Jenkins รัน `fmt`, `validate`, security scan และ `plan`
3. Platform Owner ตรวจและอนุมัติ
4. Jenkins assume CI IAM role assigned แล้ว `apply` 
5. CloudWatch/On-call ตรวจผล

ใช้ OIDC/short-lived role/least privilege identities; ไม่เก็บ AWS access key ถาวรใน CI

## Configuration & secrets managemant

| Type | Storage |
|---|---|
| App config | Helm/Kustomize overlay และ Kubernetes ConfigMap แยก environment |
| Secret | AWS Secrets Manager + KMS |
| Image version | ทำ GitOps manifest แบบระบุ digest |
| Infrastructure config | Terraform variables/state แยก environment |

- ห้ามเก็บ password, token, private key หรือ kubeconfig ใน Git, tfstate
- เก็บ password, token และ connection string ใน AWS Secrets Manager และเข้ารหัสด้วย KMS
- Pod อ่านเฉพาะ Secret ที่จำเป็นผ่าน EKS Pod Identity/IRSA และ least-privilege IAM role
- แยก Secret และ encryption key ระหว่าง Dev, Staging และ Prod
- เปิด secret rotation

## External connectivity

- Employee ที่ใช้ Corporate network → Route 53 Private DNS → Transit Gateway → Internal ALB → EKS
- ระบบ On-premises/private cloud → Transit Gateway → Site-to-Site VPN หรือ Direct Connect
- Public external API / DB: Integration Service → Transit Gateway → Network Firewall → NAT Gateway → Internet Gateway
- AWS services เช่น ECR, S3, Secrets Manager และ CloudWatch ใช้ VPC Endpoint(private endpoint) เพื่อลดการออก Internet
- จำกัดปลายทางและ port ด้วย route table, security group และ firewall allowlist บวกกับบังคับใช้ TLS 
- App access กำหนด timeout เพื่อป้องกัน external dependency ล่มแล้วกระทบทั้งระบบ

## Operations
- Prevention: Private subnet, least-privilege IAM/security group, Network Firewall, KMS encryption และ image scanning
- Health check: Kubernetes startup/readiness/liveness probe และ ALB target health check
- Monitor: CloudWatch metrics สำหรับ availability, latency, error code 4xx/5xx, CPU/memory, pod restart, RDS และ Airflow task
- Logs: Correlation ID ในหน้า error → CloudWatch Logs; audit log → CloudTrail และ Central S3
- Alerts: P1/P2/P3 หรือ Critical/warning ไปที่ owner,พร้อม dashboard ของแต่ละส่วน
- Backup: RDS PITR/snapshot, S3 versioning/replication, ECR replication และทดสอบ restore ตามรอบ
- Rollback: Git revert/image digest ก่อนหน้า

## กรณีมี Incident ก็ response ตามนี้
1. เกิด Alert แจ้ง On-call พร้อม environment, service, severity และ dashboard
2. ตรวจ health check, logs, metrics และ recent deployment เพื่อจำกัดขอบเขตปัญหา
3. Rollback release หรือ isolate dependency ที่ผิดปกติ
4. ตรวจสอบ user flow, error rate, latency, pod/RDS health และ external connectivity
5. ทำ RCA incident timeline, root cause และ preventive action
