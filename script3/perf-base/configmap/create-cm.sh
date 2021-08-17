#!/bin/bash
###usage:bash create-cm.sh nums namespace
###namespace：：需要部署所在的namespace
###nums:需要创建configmap的数量

help(){
  sed -rn 's/^### ?//;T;p;' "$0"
}
if [[ $# == 0 ]] || [[ "$1" == "-h" ]];then
  help
  exit 1
fi

TMP_FILE=./tmp-configmap-yaml
nums=$1
NAMESPACE=$2

#循环构造cm的yaml文件
function gen_cm_yaml(){
  for i in `seq 1 $nums`
    do 
      \cp -x  configmap.yaml $TMP_FILE/configmap-$i.yaml
      new_file=$TMP_FILE/configmap-$i.yaml
      sed -i s/NUMS/$i/g $new_file
      sed -i s/NAMESPACE/$NAMESPACE/g $new_file
    done
}

#判断cm是否创建完成
function check_cm_created(){
  while true
    created=`kubectl get cm -n $NAMESPACE | grep "test-configmap" | wc -l`
    do
      if [ $created != $nums ];then
        echo "`date +%Y-%m-%d' '%H:%M:%S.%N` $created configmap is created!"
        sleep 0.5
      else
        break
      fi
    done
echo "`date  +%Y-%m-%d' '%H:%M:%S.%N` all configmap ($nums) created ok!"
}


#main函数
mkdir -p $TMP_FILE
gen_cm_yaml
echo "`date +%Y-%m-%d' '%H:%M:%S.%N` begin to create configmap"
kubectl apply -f $TMP_FILE > /dev/null &
check_cm_created
