# Becoming a Hacker Kali Linux Image

This Google Cloud Build config builds a Kali Linux image for Becoming a Hacker
Foundations.

> [!NOTE]
> Creating a pristine image takes about 25-30 minutes.

## Creating a Kali Linux Image

* Edit `scripts/setup.sh` or `scripts/tweaks.sh` with your desired changes.
* Edit `cloudbuild.yaml` and change the `_BUILD_TYPE` to `pristine` or `tweaks`.
  Depending on the setting, either `scripts/setup.sh` or `scripts/tweaks.sh`
  will be run by Packer.
* Commit and push this repository and cloud-build will run.

## Troubleshooting

### Replacing the Image in CML

* If you want to replace the Kali Linux image with a new one, you must
  **STOP**, **WIPE**, **DELETE** all pods, then log into the CML controller
  and restart the `virl2.target` systemd unit after the image is built.

E.g.  To delete the pods, from the `bah-foundations-lab` repository:

```
terraform destroy -target module.pod
```

This will destroy the pods, and **leave the users, passwords and groups alone**.

```
gcloud compute ssh cml-controller --tunnel-through-iap --plain --ssh-flag='-p1122'
sudo -i

journalctl -f &
systemctl stop virl2.target
systemctl start virl2.target
```
