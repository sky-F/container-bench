#!/bin/bash
###usage:bash create-service.sh deploy nums namespace
###deploy:需要绑定的负载名称前缀
###nums:需要创建deploy的数量
###namespace:需要部署所在的namespace

help(){
  sed -rn 's/^### ?//;T;p;' "$0"
}
if [[ $# == 0 ]] || [[ "$1" == "-h" ]];then
  help
  exit 1
fi


TMP_FILE=./tmp-service-yaml
deploy=$1
nums=$2
NAMESPACE=$3

#循环构造service的yaml文件
function gen_service_yaml(){
  for i in `seq 1 $nums`
    do
      \cp -x  service-lb.yaml $TMP_FILE/service-lb-$i.yaml
      new_file=$TMP_FILE/service-lb-$i.yaml
      sed -i s/NUMS/$i/g $new_file
      sed -i s/DEPLOY-NAME/$deploy/g $new_file
      sed -i s/PORTS/$(($i+20000))/g $new_file
      sed -i s/NAMESPACE/$NAMESPACE/g $new_file
    done
}

#main函数
mkdir -p $TMP_FILE
gen_service_yaml
echo "`date +%Y-%m-%d' '%H:%M:%S.%N` begin to service"
kubectl apply -f $TMP_FILE > /dev/null

