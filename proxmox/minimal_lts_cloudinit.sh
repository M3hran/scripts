#!/bin/bash
#
#

IMG_PATH="./ubuntu-24.04-minimal-cloudimg-amd64.img"
SSH_KEY_PATH="./pubkey.rsa"
STORAGE_NAME="FAST"
#must place cloudinit config in PVE snippets path
CI_PATH="/var/lib/vz/snippets/ci_ubuntu.yaml"

# --bios ovmf \
# --machine q35 --efidisk0 FAST:0,pre-enrolled-keys=0 \
qm create 8000 \
    --name "ubuntu-2404-ci" \
    --ostype l26 \
    --memory 1024 \
    --agent 1 \
    --cpu host --socket 1 --cores 1 \
    --vga serial0 --serial0 socket  \
    --net0 virtio,bridge=vmbr0 \
    --onboot 1

# normal image (this one works)
#qm importdisk 8010 noble-server-cloudimg-amd64.img local-lvm

# minimal image (this one does not work)
qm importdisk 8000 $IMG_PATH $STORAGE_NAME

#qm set 8010 --scsihw virtio-scsi-pci --virtio0 FAST:vm-8010-disk-1,discard=on
qm set 8000 --scsihw virtio-scsi-pci --scsi0 $STORAGE_NAME:vm-8000-disk-0
#qm set 8000 --boot order=scsi0
qm set 8000 --boot c --bootdisk scsi0
qm set 8000 --scsi2 $STORAGE_NAME:cloudinit
qm set 8000 --cicustom "user=local:snippets/ci-ubuntu.yaml"
qm set 8000 --tags ubuntu-template,24.04-minimal,cloudinit
#qm set 8000 --ciuser "ubuntu"
#qm set 8000 --cipassword $(openssl passwd -6 $ubuntu)
qm set 8000 --sshkeys $SSH_KEY_PATH
qm set 8000 --ipconfig0 ip=dhcp
qm resize 8000 scsi0 "16G"
#qm cloudinit update 8000

