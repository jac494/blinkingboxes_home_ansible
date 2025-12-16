#!/bin/sh

# This script bootstraps Ansible on a fresh system.

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Use sudo." >&2
    exit 1
fi

if command -v ansible >/dev/null 2>&1; then
    echo "Ansible is already installed. Version: $(ansible --version | head -n 1)"
    exit 0
fi

apt-get update
apt-get install -y software-properties-common
add-apt-repository --yes --update ppa:ansible/ansible
apt-get install -y ansible
ansible --version