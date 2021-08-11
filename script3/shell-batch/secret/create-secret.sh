#!/bin/bash
#usage:bash create-secret.sh nums
#nums:需要创建secret的数量

TMP_FILE=./tmp-secret-yaml
NAMESPACE=default
nums=$1

#循环构造secret的yaml文件
function gen_secret_yaml(){
  for i in `seq 1 $nums`
    do 
      \cp -x  secret.yaml $TMP_FILE/secret-$i.yaml
      new_file=$TMP_FILE/secret-$i.yaml
      sed -i s/NUMS/$i/g $new_file
      sed -i s/NAMESPACE/$NAMESPACE/g $new_file
    done
}

#判断secret是否创建完成
function check_secret_created(){
  while true
    created=`kubectl get secret -n $NAMESPACE | grep "test-secret" | wc -l`
    do
      if [ $created != $nums ];then
        echo "`date +%Y-%m-%d' '%H:%M:%S.%N` $created secret is created!"
        sleep 0.5
      else
        break
      fi
    done
echo "`date  +%Y-%m-%d' '%H:%M:%S.%N` all secret ($nums) created ok!"
}


#main函数
mkdir -p $TMP_FILE
gen_secret_yaml
echo "`date +%Y-%m-%d' '%H:%M:%S.%N` begin to create secret"
kubectl apply -f $TMP_FILE > /dev/null
check_secret_created

