# Kasha Cloud Infrastructure

> A production-ready, highly available AWS architecture for scalable web applications with frontend, backend, and database services.

---

## 📋 Table of Contents

- [Architecture Overview](#architecture-overview)
- [Availability](#-availability)
- [Reliability](#-reliability)
- [Cost Optimization](#-cost-optimization)
- [Security](#-security)
- [Infrastructure Components](#infrastructure-components)
- [Deployment](#deployment)

---

## 🏗️ Architecture Overview

This infrastructure implements a modern, cloud-native architecture designed for high availability, scalability, and reliability. A public Application Load Balancer is fronted by a CloudFront CDN and protected by AWS WAF to provide global caching, DDoS mitigation and centralized security.

```
┌─────────────────────────────────────────────────────────────────┐
│                CloudFront CDN + AWS WAF (edge)                 │
└────────────────────────────┬────────────────────────────────────┘
                             │
                    ┌────────▼────────┐
                    │  Public ALB     │
                    │  (Port 80/443)  │
                    └────────┬────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
    ┌───▼──┐            ┌───▼──┐            ┌───▼──┐
    │ AZ-A │            │ AZ-B │            │ AZ-C │
    │ (N/A)│            │      │            │      │
    └──────┘            └──────┘            └──────┘
        │                    │                    │
        │    Frontend ECS    │    Frontend ECS   │
        │    Fargate Tasks   │    Fargate Tasks  │
        │   (Port 80)        │   (Port 80)       │
        │                    │                    │
        └────────────────────┼────────────────────┘
                             │
                    ┌────────▼────────┐
                    │ Internal ALB    │
                    │ (Port 8080)     │
                    └────────┬────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
    ┌───▼──┐            ┌───▼──┐            ┌───▼──┐
    │ AZ-A │            │ AZ-B │            │ AZ-C │
    │      │            │      │            │      │
    │Backend ECS        │Backend ECS       │      │
    │ Tasks (8080)      │ Tasks (8080)     │      │
    └──────┘            └──────┘            └──────┘
        │                    │
        └────────────────────┼────────────────────┐
                             │                    │
                    ┌────────▼────────┐   ┌──────▼─────┐
                    │  RDS Primary    │   │ Read Replica│
                    │  (AZ-A, Multi)  │   │  (AZ-B)    │
                    │  MySQL + Backup │   │ (Read-only)│
                    └────────┬────────┘   └────────────┘
                             │
                    ┌────────▼────────┐
                    │  Secrets Manager│
                    │  KMS Encryption │
                    └─────────────────┘
                             │
                    ┌────────▼────────┐
                    │   SQS Queues    │
                    │ (with DLQ)      │
                    └─────────────────┘
```

---

## 🎯 Availability

### **99.99% SLA Target**

#### **Load Balancing & Edge**
- **CloudFront CDN**: Caches content at edge locations globally, reducing latency and origin load.
- **AWS WAF**: Applied at CloudFront to filter out malicious requests and provide an additional DDoS defense.
- **Public ALB** (Frontend): Distributes traffic across multiple AZs behind CloudFront
  - Health checks every 30 seconds
  - Automatic unhealthy target removal
  - Connection draining (300s)
  
- **Internal ALB** (Backend): Private load balancer for service-to-service communication
  - Spans multiple AZs
  - Ensures backend scalability

#### **ECS Fargate Services**
- **Frontend**: Minimum 2 tasks across different AZs
  - Auto-scaling: 2-4 instances based on CPU (70%) and memory (80%)
  - Containerized deployment ensures consistent environments
  
- **Backend**: Minimum 2 tasks across different AZs
  - Auto-scaling: 2-4 instances with same metrics
  - Larger instance size (512 CPU, 1024 MB) for heavier workloads

#### **Database Layer**
- **Multi-AZ RDS MySQL**: Primary + standby in different AZ
  - Automatic failover in <120 seconds
  - Synchronous replication to standby
  - **Read Replica**: Separate instance in different AZ for read-heavy workloads
  - Zero downtime patching during maintenance windows

#### **Regional Resilience**
- **VPC Spanning**: Two Public + Six Private subnets across AZs
  - Public Subnets: ALBs and NAT Gateways
  - Private Subnets: ECS tasks, RDS database
  - Isolated networks improve security and availability

---

## 🛡️ Reliability

### **Key Reliability Features**

#### **Data Protection**
- **RDS Automated Backups**
  - 30-day retention period
  - Automated daily snapshots (03:00-04:00 UTC)
  - Point-in-time recovery capability
  - Final snapshots on instance deletion
  
- **Encryption**
  - KMS encryption for RDS data (at-rest)
  - SQS messages encrypted with AWS managed keys
  - Secrets Manager stores credentials securely

#### **Resilience Patterns**

| Component | Strategy | Recovery |
|-----------|----------|----------|
| **Database** | Multi-AZ + Read Replica | Automatic failover + manual promotion |
| **Frontend** | ECS Auto-scaling + ALB | Automatic task replacement |
| **Backend** | ECS Auto-scaling + ALB | Automatic task replacement |
| **Queues** | SQS DLQ | Manual inspection and replay |
| **Credentials** | Secrets Manager | Version history + recovery window |

#### **Monitoring & Alerting**
- **CloudWatch Logs**: All containers send logs to CloudWatch
  - Frontend: Error, general logs
  - Backend: Error, general logs
  - RDS: Error, slow query, general logs
  
- **Performance Insights**: 7-day retention for RDS and ECS
  - Identify bottlenecks
  - Monitor resource utilization
  
- **DLQ Alarms**: CloudWatch alarm triggers when messages enter DLQ
  - Early notification of processing failures

#### **Graceful Degradation**
- SQS with DLQ: Failed messages automatically moved after 3 retries
- Health checks: Unhealthy tasks automatically replaced
- Connection pooling: Prevents database connection exhaustion

---

## 💰 Cost Optimization

### **Cost Breakdown (Monthly Estimate - us-east-1)**

#### **Compute - ECS Fargate**
```
Frontend:  2 tasks × 256 CPU × $0.01520/hour ≈ $220/month
Frontend:  2 tasks × 512 MB × $0.00167/hour ≈ $24/month
Backend:   2 tasks × 512 CPU × $0.03048/hour ≈ $440/month
Backend:   2 tasks × 1024 MB × $0.00335/hour ≈ $48/month
────────────────────────────────────────────────────
Subtotal Compute:                          ≈ $732/month
```

#### **Load Balancing**
```
Public ALB:    $16.20 + requests           ≈ $25/month
Internal ALB:  $16.20 + requests           ≈ $25/month
Data transfer: ~100GB/month × $0.02        ≈ $2/month
────────────────────────────────────────────────────
Subtotal ALB: ≈ $52/month
```

#### **Database - RDS MySQL**
```
Primary (db.t3.micro):     $0.022/hour     ≈ $16/month
Read Replica (db.t3.micro): $0.022/hour    ≈ $16/month
Storage (40 GB gp3):       $4.60           ≈ $9/month
Backup Storage:            30GB × $0.023   ≈ $7/month
────────────────────────────────────────────────────
Subtotal Database:                         ≈ $48/month
```

#### **Edge & Security Services**
```
CloudFront (100GB):                       ≈ $8.50/month
AWS WAF (web ACL + rules + requests):     ≈ $10-15/month
```

#### **Other Services**
```
Secrets Manager:                           ≈ $0.40/secret × 2 = $0.80/month
SQS (2 main + 2 notification queues):      ≈ $0.40/million requests
KMS Key:                                   ≈ $1.00/month
NAT Gateway:                               ≈ $32.00/month
CloudWatch Logs:                           ≈ $10/month
────────────────────────────────────────────────────
Subtotal Other:                            ≈ $44/month
```

**Total Estimated Monthly Cost: ~$910**

### **Cost Optimization Strategies**

---

## 🔐 Security

### **Defense in Depth Strategy**

This architecture implements multiple layers of security controls following the **AWS Well-Architected Security Pillar**.

#### **1. Network Security**

**VPC Isolation**
- Dedicated VPC (10.0.0.0/16) for complete network isolation
- Public and private subnet separation
- No direct internet access to sensitive resources

**Security Groups** (Stateful Firewall)

| Resource | Inbound Rules | Outbound Rules | Purpose |
|----------|--------------|----------------|----------|
| **Public ALB** | HTTP (80), HTTPS (443) from 0.0.0.0/0 | All traffic | Internet-facing frontend |
| **Frontend ECS** | All traffic from Public ALB SG | All traffic | Container workloads |
| **Backend ALB** | Port 8080 from Frontend ECS | All traffic | Internal service communication |
| **Backend ECS** | All traffic from Backend ALB SG | All traffic | Internal service workloads |
| **RDS MySQL** | Port 3306 from ECS SGs only | All traffic | Database access control |

**Network ACLs** (Stateless Firewall)
- Default rules allowing all traffic within VPC
- Can be enhanced with custom deny rules per subnet

**NAT Gateway**
- Outbound internet access for private instances
- Masks internal IP addresses from internet
- Single point of egress for audit logging

#### **2. Data Security**

**Encryption at Rest**
```
Component          | Encryption | Key Management
─────────────────┼────────────┼──────────────────
RDS MySQL        | AES-256    | AWS KMS (Customer Managed)
SQS Messages     | AES-256    | AWS Managed Key
Secrets Manager  | AES-256    | AWS KMS
EBS Volumes      | AES-256    | AWS KMS
S3 Backups       | AES-256    | AWS KMS
```

**Encryption in Transit**
- Load Balancer → ECS: HTTP (recommendation: upgrade to HTTPS with TLS 1.3)
- Frontend → Backend: HTTP over private ALB (VPC-internal)
- RDS Replication: SSL/TLS encrypted
- Application → Database: SSL required

**Backup Encryption**
- All RDS snapshots encrypted with same KMS key
- Final snapshots retained with encryption
- Read replica shares same encryption key

#### **3. Access Control**

**IAM Roles & Policies**

```
Service                | Role              | Permissions
─────────────────────┼──────────────────┼──────────────────────────
ECS Task Execution   | ecsTaskExecution | CloudWatch Logs, ECR pull
ECS Application      | ecsTaskRole      | S3, SQS, Secrets Manager
RDS Enhanced Monitor | rds-monitoring   | CloudWatch, Logs
```

**Secrets Manager**
- Master password stored encrypted
- Connection string includes all credentials
- 7-day recovery window for accidental deletion
- Version control for credential rotation
- Access restricted via IAM policies only

**RDS Authentication Methods**
```bash
# Standard method
mysql -h kasha-mysql-db.xxxxx.rds.amazonaws.com -u admin -p

# IAM Database Authentication (Enhanced)
aws rds generate-db-auth-token --hostname kasha-mysql-db.xxxxx.rds.amazonaws.com \
  --port 3306 --region us-east-1 --username admin
```

#### **4. Logging & Auditing**

**CloudWatch Logs**

| Source | Logs Exported | Retention | Use Case |
|--------|---------------|-----------|----------|
| Frontend ECS | Error, General | 7 days | Application debugging |
| Backend ECS | Error, General | 7 days | Service debugging |
| RDS MySQL | Error, Slow Query, General | 7 days | Query performance, issues |

**Query Logging**
- Slow Query Log: Queries > 2 seconds logged
- General Log: All queries (disable in production)
- Error Log: Connection failures, warnings


#### **5. Compliance & Monitoring**


**Security Monitoring**
- CloudWatch Alarms on DLQ message arrival
- Performance Insights for anomaly detection
- VPC Flow Logs for network traffic analysis

**Compliance Frameworks**
- **SOC 2 Type II**: Covered by AWS attestation
- **PCI DSS**: Requires payment card data masking
- **HIPAA**: Requires additional controls (BAA)
- **GDPR**: Requires data residency and consent logs

#### **6. DDoS & Rate Limiting**

**AWS Shield Standard** (Automatic)
- Layer 3 & 4 DDoS protection
- Free tier included
- Protection against SYN floods, UDP floods

**CloudFront Edge**
- First line of defense with edge caching
- Absorbs and filters large-scale traffic spikes before reaching the ALB

**AWS WAF** (enabled at CloudFront)
```terraform
rules = [
  AWSManagedRulesCommonRuleSet,
  AWSManagedRulesKnownBadInputsRuleSet,
  RateLimitRule (2000 requests/5 minutes)
]
```

#### **7. Secrets Rotation**

**Database Password Rotation**
```bash
# Manual rotation every 90 days
aws secretsmanager rotate-secret \
  --secret-id kasha/rds/mysql/admin-password
```

**KMS Key Rotation**
- Automatic annual rotation enabled
- Previous key versions retained for decryption
- No application downtime

#### **8. Disaster Recovery & Backup Security**

**Backup Strategy**
- **Retention**: 30 days automated + 7-year archive
- **Encryption**: All snapshots encrypted
- **Testing**: Monthly restore tests to separate account
- **Cross-Region**: Optional replication for regional disaster

**Final Snapshots**
- Created before any instance termination
- Timestamped and retained indefinitely
- Can be restored to new instance if needed

#### **9. Container Security**

**ECS Fargate Best Practices**
- ✅ No SSH access to tasks (stateless)
- ✅ Images from private ECR repositories
- ✅ Image scanning enabled
- ✅ Resource limits enforced (CPU, memory)
- ✅ Read-only root filesystem (recommended)

**Container Image Security**
```dockerfile
# Recommendations
FROM public.ecr.aws/docker/library/node:18-alpine  # Minimal base image
RUN apk add --no-cache curl  # Avoid unnecessary packages
USER node  # Don't run as root
RUN npm ci --only=production  # Dependencies only
```


### **Security Best Practices by Component**

#### **Frontend (Public facing)**
```
Threat          | Mitigation
────────────────┼──────────────────────────────────
DDoS           | AWS Shield + WAF rate limiting
SQL Injection   | Parameterized queries
XSS Attacks    | Input validation, CSP headers
SSL/TLS        | ACM certificate on ALB
Data Exposure  | No sensitive data in frontend
```

#### **Backend (Private network)**
```
Threat          | Mitigation
────────────────┼──────────────────────────────────
Unauth Access  | Security group restrictions
Data Exfil     | VPC Flow Logs monitoring
API Attacks    | Rate limiting, API keys
Container Esc  | Resource limits, read-only FS
Log Injection  | CloudWatch Logs validation
```

#### **Database (Highly Restricted)**
```
Threat          | Mitigation
────────────────┼──────────────────────────────────
Unauth Access  | Security group (port 3306 only)
Data at Rest   | KMS encryption
Data in Transit| SSL/TLS required connections
Backup Theft   | Encrypted snapshots
Priv Escalation| IAM DB authentication
```

---

#### **✅ Already Implemented**
- **Spot Instances**: Use Fargate EC2 capacity providers for 70% savings on compute
- **Right-sizing**: db.t3.micro for non-production, scale as needed
- **Data Transfer**: Keep traffic within region to avoid cross-region charges
- **Reserved Capacity**: Pre-purchase for stable baseline workloads
- **Storage Optimization**: gp3 volumes are 20% cheaper than gp2

#### **🎯 Cost Saving Opportunities**

| Optimization | Current | Savings | Effort |
|-------------|---------|---------|--------|
| Switch to Fargate Spot for devtest | $732 | $512/mo | Low |
| Multi-region read replicas removal | +$48 | -$48/mo | Medium |
| Decrease backup retention to 7 days | 30 days | $2-3/mo | Low |
| Use ElastiCache for session store | None | $5-10/mo | Medium |
| Auto-shutdown non-prod at nights | Full 24/7 | $60-80/mo | Low |
| Consolidate to single AZ (staging) | Multi-AZ | $25/mo | Low |

#### **Pricing Factors by Usage Tier**
- **0-10M requests/month**: Current setup is optimal
- **10-50M requests/month**: Consider Aurora MySQL for auto-scaling
- **50M+ requests/month**: Evaluate DynamoDB or ElastiCache

---

## 🔧 Infrastructure Components

| Component | Configuration | Purpose |
|-----------|---------------|---------|
| **VPC** | 10.0.0.0/16 | Network isolation, CIDR room for 65,536 IPs |
| **Public Subnets** | 2 (AZ-A, AZ-B) | ALBs, NAT Gateways |
| **Private Subnets** | 6 (3 per AZ) | ECS tasks, RDS (isolated) |
| **IGW** | 1 per VPC | Internet access |
| **NAT Gateway** | 1 (HA via ALB) | Outbound internet for private instances |
| **Public ALB** | Port 80/443 | External traffic distribution |
| **Internal ALB** | Port 8080 | Service-to-service communication |
| **Frontend ECS** | nginx:latest | Containerized frontend (replace image) |
| **Backend ECS** | nginx:latest | Containerized backend (replace image) |
| **RDS Primary** | MySQL 8.0.35 | Data persistence with auto-backup |
| **RDS Read Replica** | MySQL 8.0.35 | Read scaling and DR |
| **Secrets Manager** | 2 secrets | Password + connection string |
| **SQS Queues** | 2 main + 2 notification | Async processing with DLQ |
| **KMS Keys** | 2 (RDS + default) | Encryption at-rest |
| **CloudWatch** | Logs + Alarms | Monitoring and alerting |
| **AWS WAF Web ACL** | Managed rules + rate-limit | Edge security for ALB |
| **CloudFront Distribution** | Origin = Public ALB | Global CDN and caching |

---

## 🚀 Deployment

### **Prerequisites**
```bash
- AWS Account with appropriate IAM permissions
- Terraform >= 1.0
- AWS CLI configured with credentials
```

### **Quick Start**
```bash
cd /home/marcrine/Documents/Terraform-Exercise2A

# Initialize Terraform
terraform init

# Review planned changes
terraform plan

# Apply configuration
terraform apply

# Retrieve outputs
terraform output
```

### **Key Outputs**
```
✓ ALB DNS Name:           kasha-alb-xxxx.elb.amazonaws.com
✓ Backend ALB DNS:        kasha-backend-alb-xxxx.elb.amazonaws.com
✓ Database Endpoint:      kasha-mysql-db.xxxxx.rds.amazonaws.com:3306
✓ Read Replica Endpoint:  kasha-mysql-read-replica.xxxxx.rds.amazonaws.com:3306
✓ SQS Queue URLs:         https://sqs.us-east-1.amazonaws.com/xxxx/kasha-queue
✓ Secrets Manager ARNs:   arn:aws:secretsmanager:us-east-1:xxxx:secret/kasha/rds/...
✓ CloudFront Domain Name:  d123456abcdef8.cloudfront.net
```

### **Next Steps**
1. **Update Container Images**: Replace `nginx:latest` with your application images
2. **Configure Database**: Update initial schema and user credentials in Secrets Manager
3. **Setup DNS**: Create Route53 records pointing to ALB
4. **Enable SSL/TLS**: Add HTTPS listener to frontend ALB with ACM certificate
5. **Implement CI/CD**: Setup CodePipeline for automated deployments
6. **Configure Monitoring**: Create custom CloudWatch dashboards and SNS alerts

---

## 📊 Architecture Pillars

### **Availability**
✅ Multi-AZ deployment across 2+ availability zones
✅ Auto-scaling based on CPU and memory metrics
✅ Automatic health checks and failure recovery
✅ Load balancing with connection draining
✅ Database failover in <2 minutes

### **Reliability**
✅ Encrypted data at-rest and in-transit
✅ 30-day automated backups with point-in-time recovery
✅ Dead Letter Queues for failed message handling
✅ CloudWatch monitoring and alarming
✅ Version control for secrets and configuration

### **Cost Efficiency**
✅ Right-sized instances for workload
✅ Spot instance eligibility for non-critical workloads
✅ Reserved capacity recommendations available
✅ Automatic scaling prevents over-provisioning
✅ Pay-per-use model (no upfront costs)

### **Security**
✅ VPC isolation with security groups
✅ KMS encryption for databases and queues
✅ Secrets Manager for credential management
✅ IAM roles with least privilege access
✅ Private subnets for sensitive workloads

---


