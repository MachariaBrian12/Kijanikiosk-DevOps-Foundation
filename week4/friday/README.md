# KijaniKiosk Week 4 — Full IaC Pipeline

## What This Is
A fully reproducible infrastructure pipeline that provisions three servers
on AWS using Terraform and configures them using Ansible.

## Structure
- `terraform/` — provisions api, payments, logs servers via reusable module
- `ansible/` — configures all three servers across 7 phases
- `pipeline.sh` — runs the full pipeline end to end
- `hardening-decisions.md` — security decisions written for non-technical stakeholders
- `reflection.md` — engineering reasoning and lessons learned

## How To Run
```bash
# One command runs everything
./pipeline.sh

# Run twice to prove idempotency
./pipeline.sh
```

## Key Decisions
- Dynamic inventory: Terraform IPs feed directly into Ansible — no hardcoded values
- SSH restricted to operator IP only via security group
- kk-payments systemd unit scores 1.8 (target: below 2.5)
- Remote state in S3 with DynamoDB locking
