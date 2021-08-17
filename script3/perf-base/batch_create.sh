#!/bin/bash
#bash test.sh nums podnums
#创建nums个configmap及secret,且关联至nums个deploy,每个deploy副本数为podnums
nums=$1
podnums=$2
dir=`pwd`
# 第一步，，创建PVC
cd $dir/pvc-sfs;bash create-pvc-sfs.sh $nums > pvc-sfs-create.log
sleep 5
## 第二步，，创建configmap
cd $dir/configmap;bash create-cm.sh $nums  > configmap-create.log
sleep 3
# 第三步，，创建secret
cd $dir/secret;bash create-secret.sh $nums > secret-create.log
sleep 3
# 第四步，，创建deploy
cd $dir/deploy;bash create-deploy.sh $nums $podnums > deploy-create.log
# 第五步，，创建svc
cd $dir/service;bash create-svc.sh test-deploy $nums > svc-create.log
