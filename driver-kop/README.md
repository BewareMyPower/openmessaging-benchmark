# driver-kop

This directory contains scripts that make you create resources and deploy [KoP](https://github.com/streamnative/kop) on Azure.

## Prerequisites

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- [Terraform](https://terraform.io/)
- [Ansible](http://docs.ansible.com/ansible/latest/intro_installation.html)

## Create resources from Azure

First, you should login Azure:

```bash
$ az login
```

Then generate the `.terraform` directory that contains the terraform providers:

```bash
$ terraform init
```

Run following command to create resources including virtual machines from Azure.


```bash
$ terraform apply
```

## Prepare Ansible

Ansible use [inventory file](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html) to specify the hosts. So we must generate the inventory file first:

```bash
$ ./generate_inventory.sh > inventory.ini
```

In addition, we should save the `tls_private_key` to `~/.ssh/azure_ssh_key` so that Ansible could log in to Azure:

```bash
$ terraform output tls_private_key | sed '1d;$d' > ~/.ssh/azure_ssh_key
$ chmod 644 ~/.ssh/azure_ssh_key
```

## Deploy KoP

Run `prepare.yaml` to setup basic environment for each VM:

```bash
$ ansible-playbook -i inventory.ini prepare.yaml
```

Then run `deploy.yaml` to deploy KoP's components and prometheus:

```bash
$ ansible-playbook -i inventory.ini deploy.yaml
```

## Destroy the resources

If you want to destroy these resources, run

```bash
$ terraform destroy
```

Make sure you have already logged in to Azure.
