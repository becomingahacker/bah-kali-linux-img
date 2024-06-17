# Becoming a Hacker Kali Linux Image

This Google Cloud Build config builds a Kali Linux image for Becoming a Hacker
Foundations.

> [!NOTE]
> Creating a pristine image takes about 25-30 minutes.

## GCE Base Kali Image

> [!IMPORTANT]
> These are manual steps you must do before starting the CloudBuild process to
> make the image available for use with Google Compute Engine.  If the image
> is already present (image family: `kali-linux-cloud-gce-amd64`), you can skip
> these.

Image families flow thusly:
`kali-linux-cloud-genericcloud-amd64` -> `kali-linux-cloud-gce-amd64` -> `kali-linux-cloud-cml-amd64`

* Import https://kali.download/cloud-images/kali-2024.2/ as an image.  You can do this by hand or use Cloud Builder.
* Create instance using [kali-linux-2024-2-cloud-genericcloud-amd64](https://console.cloud.google.com/compute/imagesDetail/projects/gcp-asigbahgcp-nprd-47930/global/images/kali-linux-2024-2-cloud-genericcloud-amd64?project=gcp-asigbahgcp-nprd-47930) as a base, enable SSH control of serial console. 
* Disable cloud-init control of the network.  The bootstrapped network interferes with it.
* In `/etc/cloud/cloud.cfg.d/99_disable_networking_config.cfg`:
```
network: {config: disabled}
```
* Remove `/etc/network/interfaces.d/50-cloud-init`
```
rm /etc/network/interfaces.d/50-cloud-init
```
* Fix initramfs so growroot works:
	* https://unix.stackexchange.com/questions/777527/debian-12-cloud-image-deployment-issue-growpart-can-not-find-grep-and-other-ba
	* In `/usr/share/initramfs-tools/hooks/growroot`:
```
#!/bin/sh

PREREQ=""

prereqs()
{
        echo "$PREREQ"
}

case $1 in
# get pre-requisites
prereqs)
        prereqs
        exit 0
        ;;
esac

. /usr/share/initramfs-tools/hook-functions

copy_exec /usr/bin/grep /bin
copy_exec /usr/bin/sed /bin
copy_exec /usr/bin/rm /bin
copy_exec /usr/bin/awk /bin

exit 0
```
```
chmod u+x /usr/share/initramfs-tools/hooks/growroot
update-initramfs -u
```
* Add to `/etc/default/grub`:
```
GRUB_TERMINAL_INPUT="serial console"
```
* Update grub
```
update-grub
```
* Install `linux-image-amd64`
```
apt-get update
apt-get install -y linux-image-amd64
```
* Reboot, run new image
```
-> Advanced options for Kali GNU/Linux
-> Kali GNU/Linux, with Linux 6.8.11-amd64 (or whatever version is available that isn't the cloud image)
```
* Remove `linux-image-cloud-amd64`:
```
apt-get remove --purge -y linux-image-cloud-amd64
apt-get remove --purge -y linux-image-*-cloud-amd64
# Don't abort removal
```
* Reboot, make sure new image still works and is chosen by default.
```
root@kali:~# uname -a   
Linux kali 6.8.11-amd64 #1 SMP PREEMPT_DYNAMIC Kali 6.8.11-1kali2 (2024-05-30) x86_64 GNU/Linux
```
* Change the root user's shell to `bash`:
```
chsh -s /usr/bin/bash root
```
* Remove `/etc/hosts` and `/etc/hostname`
```
rm /etc/hosts
rm /etc/hostname
```
* Reset cloud-init
```
cloud-init clean -l --machine-id -c all
```
* Remove zsh history
```
rm .zsh_history
^D
history -c
rm .bash_history
rm .zsh_history
^D
```
* Shutdown machine
```
shutdown -P now
```
* Make sure Google recognizes VM status as stopped
* Create image in console from instance disk:
```
Name: kali-linux-{{ date }}-cloud-gce-amd64
e.g.
Name: kali-linux-2024-06-16-cloud-gce-amd64
Location: Regional, us-east1
Family: kali-linux-cloud-gce-amd64
Description: (same as name)
```
* Wait for image to be created
* Delete instance and disk

## Troubleshooting

### Replacing the Image in CML

* If you want to replace the Kali Linux image with a new one, you must
  **STOP**, **WIPE**, **DELETE** all pods, **DELETE** the node & image
  definitions, and **DELETE** the 
  [Uploaded Images](https://becomingahacker.com/manage_image_uploads/).  

  E.g.  To delete the pods, from the `bah-foundations-lab` repository:

```
terraform destroy -target module.pod
```

This will destroy the pods, and **leave the users, passwords and groups alone**.

### Stopping an Errant Build

* To stop an in-progress build, use the `aws imagebuilder cancel-image-creation`
  command.  You will need the build version ARN from the UI or Terraform.  You can
  do this in most states, up to but not including the terminal state, which
  includes making an AMI.

```
aws imagebuilder cancel-image-creation --image-build-version-arn \
  'arn:aws:imagebuilder:us-east-2:181171279649:image/bah-kali-linux-image-recipe/1.0.0/1'
{
    "requestId": "a84c8f41-82f6-4520-97b8-529a24988cf8",
    "clientToken": "16528a94-81bd-488d-b17a-e65dc801f07c",
    "imageBuildVersionArn": "arn:aws:imagebuilder:us-east-2:181171279649:image/bah-kali-linux-image-recipe/1.0.0/1"
}
```

* This is useful also for interrupting the image exporter after uploading
  the Kali image to CML, since completion isn't needed after that, nor is making
  its AMIs important.  E.g.  after you see these events in CloudWatch:

```
* Connection #0 to host cml-0.becomingahacker.com left intact
CmdExecution: ExitCode 0
ExecuteBash: FINISHED EXECUTION
Executor: FINISHED EXECUTION OF ALL DOCUMENTS
TOE has completed execution successfully
```
Run this:
```
aws imagebuilder cancel-image-creation --image-build-version-arn \
  'arn:aws:imagebuilder:us-east-2:181171279649:image/bah-kali-linux-exporter-recipe/1.0.0/1'
```
