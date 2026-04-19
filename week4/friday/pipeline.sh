#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="$SCRIPT_DIR/terraform"
ANSIBLE_DIR="$SCRIPT_DIR/ansible"
INVENTORY="$ANSIBLE_DIR/inventory.ini"

echo "============================================"
echo " KijaniKiosk IaC Pipeline"
echo "============================================"

# --- Step 1: Terraform init and apply ---
echo ""
echo "[1/4] Initializing Terraform..."
cd "$TF_DIR"
terraform init -input=false

echo ""
echo "[2/4] Running Terraform apply..."
terraform apply -input=false -auto-approve

if [ $? -ne 0 ]; then
  echo "ERROR: Terraform apply failed. Aborting."
  exit 1
fi

# --- Step 2: Extract IPs from Terraform output ---
echo ""
echo "[3/4] Extracting server IPs and writing inventory..."

API_IP=$(terraform output -raw api_server_ip)
PAYMENTS_IP=$(terraform output -raw payments_server_ip)
LOGS_IP=$(terraform output -raw logs_server_ip)

echo "  api      -> $API_IP"
echo "  payments -> $PAYMENTS_IP"
echo "  logs     -> $LOGS_IP"

# Write inventory.ini dynamically — no hardcoded IPs
cat > "$INVENTORY" << INVENTORY
[kijanikiosk]
api      ansible_host=$API_IP
payments ansible_host=$PAYMENTS_IP
logs     ansible_host=$LOGS_IP

[kijanikiosk:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/kijanikiosk
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
INVENTORY

echo "  inventory.ini written."

# --- Step 3: Wait for SSH to be ready ---
echo ""
echo "  Waiting 30 seconds for servers to be SSH-ready..."
sleep 30

# --- Step 4: Run Ansible ---
echo ""
echo "[4/4] Running Ansible playbook..."
cd "$ANSIBLE_DIR"
ansible-playbook -i inventory.ini kijanikiosk.yml

if [ $? -ne 0 ]; then
  echo "ERROR: Ansible playbook failed."
  exit 1
fi

echo ""
echo "============================================"
echo " Pipeline complete. All servers configured."
echo "============================================"
