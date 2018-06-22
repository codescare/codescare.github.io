---
title: "Google Cloud Basics"
date: 2018-06-22T22:59:25+05:30
---

Documentation for cloud computing platforms such as Google Cloud, AWS or Azure can sometimes be hard to understand. I've tried to enlist a few features and explain them in short below.

# Compute Instances
These are virtual machines running on physical servers in whichever region you choose running the OS of your choice (generally GNU/Linux). When you make and turn on a new compute instance, you choose a certain amount of "ephemeral" or temporary storage that you "attach" to this instance. You also get an (optionally and chargeably static) external IP address and an internal IP address for the instance which you can use to connect to the instance. For all practical purposes, you can treat this instance as any other server. The only difference is that once you shut it down, the server will transfer your ephemeral storage to another storage server, from where it can be transferred again to somewhere else when you restart your instance. This allows you to just swap hardware after shutting down your instance, allowing a crazy amount of flexibility.

### Connecting to Instances
You can connect to compute instances in two ways:

* Shell in browser
* SSH Client

While you can theorotically work with a shell in your browser, you will soon find yourself getting frustrated over this. A better way is to add your SSH public key to the compute instance (check [this page](https://docs.gitlab.com/ee/ssh/#generating-a-new-ssh-key-pair) if you're unsure what this is). To add a SSH key in GCP, **do not** add it to `~/.ssh/authorized_keys` as you normally would for any other server, since this file is overwritten by Google if you open a browser shell. Instead go to the instance page in your browser, edit the instance and add your public key in `SSH Keys`. Note that you need to have your e-mail set to the one you're using for GCP (your GMail). If this is not the case, just change your e-mail in the public key and everything should still work fine.

Once you have the private key added in your SSH client (you will have to do more work if you're one Windows), you can now connect to the instance using it's external IP address (which can also be found on the instance page) and it should log you in directly.

# Storage Buckets
*Bucket* in Google Cloud, *S3* in AWS and *Azure Storage* are all blob storage services, which allow you to store huge and lots of arbitrary files for fast access. So if you are running an instance on Google Cloud and create a bucket in the same region, it is physically present on a different storage server, from where you can easily access or write data. This allows multiple instances to share data, and data in buckets is also permanent, so removing instances will not get rid of the data. It is recommended to use buckets where you need to store a lot of data or need to access it from elsewhere. For example, if you are training an ML model on a Cloud TPU, since the TPU is on a separate machine, it cannot access the ephemeral storage of your compute instance. Instead, you can give it a URL of the bucket, which it can write to if it has the proper permissions.

### Using Buckets

Google Cloud allows mounting buckets as local directories, which usually makes life much easier. To do this, in your instance, install `gcsfuse` by following the instructions [here](https://github.com/GoogleCloudPlatform/gcsfuse/blob/master/docs/installing.md). If you're on a Debian-like system, this means you want to run

```bash
export GCSFUSE_REPO=gcsfuse-`lsb_release -c -s`
echo "deb http://packages.cloud.google.com/apt $GCSFUSE_REPO main" | sudo tee /etc/apt/sources.list.d/gcsfuse.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo apt-get update
sudo apt-get install gcsfuse
```

You can now make a local directory and mount a bucket in it as follows. Note that it is usually better to mount it in a subdirectory of your home as below, since this will ensure you don't run into unix permission issues. If you don't have permissions on the *bucket*, this will throw up an error.

```bash
mkdir ~/mnt_bucket
gcsfuse gec_data ~/my_bucket
```

This will mount the bucket `my_bucket` in the folder `mnt_bucket` in your home directory. You can now access this like any other folder, with `gcsfuse` doing all the magic. Note that the bucket might have to be in the same project and region for this to work. To unmount the bucket when you're done, just run,

```bash
fusermount -u my_bucket/
```

Note: If you don't see some folders in the bucket after mounting, but they are visible in your browser, just run `mkdir name_of_folder` and the folder should become visible. This is a bug due to there being no real concept of a folder in the internal workings of blob storage.

# Cloud Shell
Cloud shell is a feature of Google Cloud which lets you manage hardware, instances and other cloud infrastructure from the command line. You do not create a compute instance when you connect to the cloud shell, but you can use cloud commands such as `ctpu` etc.

# Snapshots
Snapshots allow you to backup the entire state of a compute instance, you can restore the instance to the same state if anything goes bad. These are an especially useful feature of running stuff in the cloud when you are experimenting with things that could break your system.

# Conclusion
Overall, this should be enough to get you started on understanding the documentation and getting some stuff done. I'll keep adding here if I feel I missed something important.

Happy Computing!
