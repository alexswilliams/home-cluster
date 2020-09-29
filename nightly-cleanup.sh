#!/usr/bin/env bash

set -e

echo "Space before cleanup:"
df -h | grep "/dev/sda1 "

echo ""
echo "Cleaning apt..."
apt autoremove -y
apt clean -y

echo ""
echo "Cleaning out kubeadm backups..."
rm -rf /etc/kubernetes/tmp/kubeadm-backup-*

echo ""
echo "Removing old journal entries..."
journalctl --vacuum-size=32M

echo ""
echo "Forcing a log rotation..."
systemctl restart logrotate

echo ""
echo "Removing stale prometheus temp folders..."
rm -rf /mnt/k8s-pv/prometheus-pv/*.tmp

echo ""
echo "Cleaning docker"
docker rm -f $(docker ps --all --filter "status=exited" --quiet) || true
docker image prune -af
docker volume prune -f
docker system prune -af

echo ""
echo "Space after cleanup:"
df -h | grep "/dev/sda1 "

