# Becoming a Hacker Kali Linux Image

This Terraform config builds a Kali Linux image for Becoming a Hacker
Foundations.

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
