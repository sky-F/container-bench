#!/bin/bash
#usage:bash create-deploy.sh nums
#nums:需要创建deploy的数量

TMP_FILE=./tmp-deploy-yaml
NAMESPACE=default
IMAGE=swr.cn-south-1.whitetiger.com/cce/perf-nginx:v10.1
nums=$1

#循环构造deploy的yaml文件
function gen_deploy_yaml(){
  for i in `seq 1 $nums`
    do 
      \cp -x  deploy.yaml $TMP_FILE/deploy-$i.yaml
      new_file=$TMP_FILE/deploy-$i.yaml
      sed -i s/NUMS/$i/g $new_file
      sed -i s/NAMESPACE/$NAMESPACE/g $new_file
      sed -i s!IMAGE!$IMAGE!g $new_file  
    done
}

#判断deploy是否创建完成
function check_deploy_created(){
  while true
    created=`kubectl get pod -n $NAMESPACE | grep "test-deploy" | grep Running | wc -l`
    do
      if [ $created != $nums ];then
        echo "`date +%Y-%m-%d' '%H:%M:%S.%N` $created pod is Running!"
        sleep 1
      else
        break
      fi
    done
echo "`date  +%Y-%m-%d' '%H:%M:%S.%N` all pod ($nums) Running ok!"
}


#main函数
mkdir -p $TMP_FILE
gen_deploy_yaml
echo "`date +%Y-%m-%d' '%H:%M:%S.%N` begin to create deploy"
kubectl apply -f $TMP_FILE > /dev/null
check_deploy_created

