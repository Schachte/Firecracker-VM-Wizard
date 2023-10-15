# 🔥🧙 Firecracker MicroVM Wizard

Simplifying the Firecracker VM setup process. Inspired by [gruchalski](https://gruchalski.com/).

---

[![DigitalOcean Referral Badge](https://web-platforms.sfo2.cdn.digitaloceanspaces.com/WWW/Badge%201.svg)](https://www.digitalocean.com/?refcode=ed8d462f1268&utm_campaign=Referral_Invite&utm_medium=Referral_Program&utm_source=badge)

_If my work is helpful to you, please consider using my Digital Ocean referral code above for DO credit_

# Table of contents

- [Usage](#usage)
- [Setting up Firecracker from scratch on Linux](#setting-up-firecracker-from-scratch-on-linux)
  - [Basic setup & pre-reqs](#basic-setup--pre-reqs)
  - [Configuring your custom image](#configuring-your-custom-image)
  - [Generate the VM configuration details](#generate-the-vm-configuration-details)
  - [Run the MVM](#run-the-mvm)
- [Accessing the machine via SSH](#accessing-the-machine-via-ssh)

# Usage

```sh
git clone git@github.com:Schachte/Firecracker-VM-Helper.git && \
cd Firecracker-VM-Helper && \
./wizard
```

```
🧙🔥 Firecracker Setup Wizard

1) Download Linux kernel binary
2) Install Firecracker
3) Install Docker
4) Setup Firecracker filesystem
5) Setup Firecracker config JSON
6) Run Firecracker
7) Exit
Pick a number ➡️ 
```

# Setting up Firecracker from scratch on Linux

⚠️ Note: This entire repo _only_ runs on Linux. You can rent a VM, but it must support virtualization (ie. Google Cloud, Digital Ocean, EC2).

## Basic setup & pre-reqs
1. Download the Linux kernel binary via option `1` of the wizard
2. Install Firecracker onto the `PATH` view option `2` of the wizard
3. Install Docker (if you don't already have) via option `3` of the wizard

## Configuring your custom image

You're free to modify this as you please, but there is a minimal alpine image located in `fs/rootfs.Dockerfile`. This will auto-configure and boot sshd on init so you can SSH into the VM once it boots up. Password-based login is disabled.

You can modify the Dockerfile if needed, but to generate the image, we will leverage Docker, but extract the filesystem from it then remove the image from the local filesystem since it will no longer be needed.

4. Configure the image for Firecracker via option `4` of the wizard

## Generate the VM configuration details

There are a few ways to launch a VM, we will be launching the VM via the `firecracker` binary giving it a JSON path to the dynamically generated configuration. There will be several questions asked during config generation:

```
Enter TAP IP Address (default: 172.16.0.1/24)

Enter Firecracker IP Address (default: 172.16.0.2/24)

Enter guest MAC address (default: 02:FC:00:00:00:05)

Enter VM memory usage (default: 128 mib)

Enter TAP name (default: tap-fc-dev)
```

In this case, at least for testing, defaults should work for you out of the box. I'm automatically generating a TAP interface within the configuration setup. This is the network bridge used between the host and the VM to control the flow of packets in and out of the virtual machine. 

5. Generate config via option `5` of the wizard. 

## Run the MVM

6. Run option `6` and the micro-VM will start and present a login.

> If you'd like to just run the VM manually and in the background so you can SSH within the same terminal session, then run:

```sh
export CONFIG_LOCATION=/firecracker/configs
$ sudo firecracker --no-api --config-file $CONFIG_LOCATION/alpine-config.json 
```

Note: You _will_ be presented with a login screen. This is useless based on the default config in the Dockerfile because I've disabled logging in via password. Kill the session and use SSH to access the VM.

# Accessing the machine via SSH

```sh
ssh -i ~/.ssh/hacker alpine@172.16.0.2
```

You can change the details of the key name in `fs/fs.sh` and the user login username via the Dockerfile in `fs/rootfs.Dockerfile`

```sh
root@vm:~# ssh -i ~/.ssh/hacker alpine@172.16.0.2

The authenticity of host '172.16.0.2 (172.16.0.2)' can't be established.
ED25519 key fingerprint is SHA256:0vI9w7kxgB8hX/J3N5jRWXo5CNxlmryoGYTQEpGpOoI.
This key is not known by any other names
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes

Warning: Permanently added '172.16.0.2' (ED25519) to the list of known hosts.
Welcome to Alpine!

The Alpine Wiki contains a large amount of how-to guides and general
information about administrating Alpine systems.
See <http://wiki.alpinelinux.org/>.

You can setup the system with the command: setup-alpine

You may change this message by editing /etc/motd.

172:~$
```
