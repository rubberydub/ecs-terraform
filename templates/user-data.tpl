#!/bin/sh

set -e

# Set the ECS cluster name.
echo ECS_CLUSTER='${cluster_name}' > /etc/ecs/ecs.config

# Install iptables-services.
yum install -y iptables-services

# Prevent containers running in the ECS cluster from assuming the IAM
# permissions of the host instance.
iptables \
    --insert FORWARD 1 \
    --in-interface docker+ \
    --destination 169.254.169.254/32 \
    --jump DROP

# Save iptables rules.
iptables-save | /etc/sysconfig/iptables

# Enable and start iptables.
systemctl enable --now iptables
