#!/bin/bash
GC_BIN="/home/hubcap/Downloads/google-cloud-sdk/bin"
GC_ZONE=us-east1-b
GC_PROJECT=`$GC_BIN/gcloud config get-value project`
GC_MOUNT_POINT=/mnt
# gcloud compute images list <---- pick an "image" from one of these.
#
# For this script to work, the image needs:
#   linux to be configured to support ext4
#   linux to be configured to support orangefs
#   orangefs userspace to be installed in /opt/orangefs
#         
GC_IMAGE=hubcap-linuxbcf87687-orangefs65ab0d29
