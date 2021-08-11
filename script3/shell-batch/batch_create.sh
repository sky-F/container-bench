#!/bin/bash
#bash test.sh nums
#创建nums个configmap及secret,且关联至nums个deploy
nums=$1
dir=`pwd`
cd $dir/configmap;bash create-cm.sh $nums
cd $dir/secret;bash create-secret.sh $nums
sleep 3
cd $dir/deploy;bash create-deploy.sh $nums
root@trunkport-f00475147-1:~/container-benc
