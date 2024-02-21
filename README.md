# Becoming a Hacker Kali Linux Image

This Terraform config builds a Kali Linux image for Becoming a Hacker
Foundations.

## Troubleshooting

* If you want to replace the Kali Linux image with a new one, you must
  **stop**, **wipe**, **delete** all pods, **delete** the node, image
  definitions, and delete the 
  [Uploaded Images](https://becomingahacker.com/manage_image_uploads/).  

  E.g.  To delete the pods, from the `bah-foundations-lab` repository:

```
terraform destroy -target module.pod
```

This will destroy the pods, and **leave the users and groups alone**.
