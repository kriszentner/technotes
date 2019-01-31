# Overview
This article was originally written for HPC operations, but has other applications as well. I focused on installation in containers so the package lists may be more than would would be needed on a full OS. Also the container instalations aren't Dockerfile snippits, so adapt them as needed.

# Getting Data to Your Docker Container in a Azure Storage Account Only Paradigm
There are a few options in getting data to and from your container using a bring your own storage (BYOS) paradigm. With both solutions, for better or worse, file permissions are eliminated.

## Performance - TL;DR
If you look at the benchmarks in this article, AzCopy is the fastest method of all presented. If you must have a filesystem, then blobfuse is your best option.

## Using Copy Tools
Features:
* Provides a stateless method of copying your data.
* Blob storage allows for very large containers for data (PB scale)
* No Docker plugin needed, no state or permissions to worry about.

**AzCopy (Windows and Linux - .Net Based)**|**blobxfer (python based)**|
------------ |------------|
Has concurrent operations by default but can be tuned with --parallel-level|Blobxfer allows some performance tweaks
Can copy files or directories|Copies directories only
Can use keys or SAS tokens|Can use keys or SAS tokens
 | Can exclude files based on patterns
Has a resume feature| Has a resume-file feature
Gives live summary of transfer by default|Gives summary before and after

### Installing AzCopy on an Ubuntu Docker Container
```bash
apt-get update
apt-get install $(apt-cache search libicu[0-9][0-9]|cut -d' ' -f 1) rsync libunwind-dev wget libssl1.0.0 -y
wget -O azcopy.tar.gz https://aka.ms/downloadazcopylinux64
tar -xf azcopy.tar.gz
./install.sh
rm -rf azcopy azcopy.tar.gz
```
### Installing Blobxfer on an Ubuntu Docker Container
```bash
apt-get update
apt-get install python3 python3-dev
wget -O get-pip.py https://bootstrap.pypa.io/get-pip.py
python3 ./get-pip.py
pip install blobxfer 
```

## Using Mount Tools

### Using Azure Files
Features/Limitations:
* Currently the slowest option of all for file transfers on Linux
* Uses a native OS operations read/write/append. Can use like a filesystem
* 5TB limit on file shares
* Azure Premium File Shares (currently in preview only) will allow for 
  * 612MB/s vs 60MB/s
  * 100TB vs 5TB

When creating a storage account suitable for Azure Files. You'll need to ensure the below options are selected:
* Performance: Standard
* Replication: LRS
* Access Tier: Hot

#### Docker mount Azure Files with CIFS using Docker Plugin
Replace:
*  `mystorageaccount` with your storage account name 
* The password with your storage account key.
* `mnttest` with your container name
```bash
# Create a docker volume using your Storage key as a credential.
# (this does not persist across reboots)
docker volume create -d cifs --name mystorageaccount.file.core.windows.net/mnttest --opt username=mystorageaccount--opt password=WT+ostf3YWq9n8rIZuczYpa6QCFrCZhhzHLipTpEfURomG31MmJzaQFh3xvS70E4dBA1FK+nDiE+pOBIjuMN4A== --opt fileMode=0777 --opt dirMode=0777
```
##### Ensure your docker volume is listed
```bash
$ docker volume list
DRIVER              VOLUME NAME
cifs                mystorageaccount.file.core.windows.net/mnttest
```

##### Run and mount your docker container
```bash
docker run --rm -it -v mystorageaccount.file.core.windows.net/mnttest:/mnttest ubuntu /bin/bash
```

#### Docker mount Azure Files with CIFS inside container
Be aware this is the slowest storage option tested.

You'll need to extend the container privs to allow CIFS mounting:
```bash
docker run --cap-add SYS_ADMIN --cap-add DAC_READ_SEARCH --security-opt apparmor:unconfined --rm -it ubuntu /bin/bash
```
Inside the container you'll need to install cifs-utils:
```bash
apt-get update && apt-get install cifs-utils -y
```

From here you can mount as usual. Killing the container will remove the mount.
```bash
mount -t cifs //mystorageaccount.file.core.windows.net/mnttest/mnttest -o user=mystorageaccount,password=WT+ostf3YWq9n8rIZuczYpa6QCFrCZhhzHLipTpEfURomG31MmJzaQFh3xvS70E4dBA1FK+nDiE+pOBIjuMN4A==
```

### Blobfuse
Features/Limitations:
* Currently the fastest option for a mounted Azure Storage Account filesystem option on Linux
* Uses a native OS operations read/write/append. Can use like a filesystem
* Uses a cache to speed up operations. This can cause temporary inconsistencies in certain situations.
  * 2PB limit on file shares
  * Over 4TB file sizes
  * About 500MB/s down 200MB/s up speeds.

This accesses an Azure Blob using the Linux FUSE driver. There is no docker plugin, so you'll need to make your mount inside the container.

#### Installing blobfuse on a container
```bash
source /etc/os-release
apt-get update
apt-get install wget -y
wget https://packages.microsoft.com/config/ubuntu/${VERSION_ID}/packages-microsoft-prod.deb
dpkg -i packages-microsoft-prod.deb
apt-get update
apt-get install libcurl3-gnutls $(apt-cache search libgnutls[0-9][0-9]|cut -d' ' -f 1)  libfuse2 blobfuse -y
rm packages-microsoft-prod.deb
```

#### Starting a container with blobfuse capability
You'll need to give your docker container extended permissions in order to mount your blobfuse device. Specifically with the `--security-opt apparmor:unconfined --cap-add=SYS_ADMIN --device /dev/fuse` options. Also note that I'm mounting the Azure ephemeral drive via `-v /mnt:/mnt` to use as a caching drive later. If the cluster has a /data drive, this can also be used for this purpose.
```bash
docker run --security-opt apparmor:unconfined --cap-add=SYS_ADMIN --device /dev/fuse -it ubuntu -v/mnt:/mnt /bin/bash
```
#### Mounting Blobfuse from inside a container
```bash
mkdir /mnt/resource/blobfusetmp/$(hostname)
blobfuse /mnttest --tmp-path=/mnt/resource/blobfusetmp/$(hostname)  --config-file=/root/fuse_connection.cfg -o attr_timeout=240 -o entry_timeout=240 -o negative_timeout=120
```
**Note** When your container is finished, please delete the tmp directory you've created above. This directory is not automatically cleaned.

##Benchmarks
* Using LRS Blob account from Internet 1st EastUS NC24_Standard VM to EastUS storage account
* Using 100GB transfers as test cases
* Reads/Writes using Azure VM ephemeral SSD disk (/mnt)

**Native Baseline (Effectively copying from /mnt to /mnt via container)**  
917MB/s Copy from /mnt to / (1 100G file @1:49)  
1.01GB/s Copy from / to /mnt (1 100G file @1:31)  
  
**Azure Files (using Docker Plugin)**  
10MB/sec write from container to Azure Files (1 100G file @16m17s)  
10MB/sec write from Azure Files to container (1 100G file @16m17s)  
  
**Azure Files (Mounted inside container)**  
9MB/sec write from container to Azure Files (1 100G file @17m31s)  
6MB/sec write from Azure Files (1 100G file @25m20s)  
  
**AzCopy (no optimizations)**  
1GB/s transfer from container to Azure Blob (100 1G files @1m:21s)  
1.4GB/s transfer from Azure Blob to Container  (100 1G files @1m:06)  
  
400MB/s transfer from container to Azure Blob (Single 100G file @ 4m:18s)  
1GB/s transfer from Azure Blob to container (Single 100G file @ 1m:42s)  
  
**blobxfer (no optimizations)**  
147MB/s transfer from container to Azure Blob using AzCopy (100 1G files @11m:35s)  
974MB/s transfer from Azure Blob to Container using AzCopy (100 1G files @1m:45s)  
  
**blobfuse**  
203MB/sec write from container to blob (100 1G files @8m11s)  
502MB/sec write from blob to container (100 1G files @3m19s)  
206MB/sec write from container to blob (1 100G file @8m04s)  
595MB/sec write from blob to container (1 100G file @2m48s)  
  
# References
* [Azure Storage Scalability and Performance Targets](https://docs.microsoft.com/en-us/azure/storage/common/storage-scalability-targets)
* [AzCopy on Linux Documentation](https://docs.microsoft.com/en-us/azure/storage/common/storage-use-azcopy-linux)
* [Blobxfer Documentation](https://blobxfer.readthedocs.io/en/latest/)
* [Azure Files Premium Annoucement](https://azure.microsoft.com/en-us/blog/premium-files-pushes-azure-files-limits-by-100x/)
* [How to mount Blob storage as a file system with blobfuse](https://github.com/MicrosoftDocs/azure-docs/blob/master/articles/storage/blobs/storage-how-to-mount-container-linux.md)
