#!/bin/bash
###usage:bash create-deploy.sh deploynums podnums
###deploynums:需要创建deploy的数量
###podnums:每个deploy的副本数量

help(){
  sed -rn 's/^### ?//;T;p;' "$0"
}
if [[ $# == 0 ]] || [[ "$1" == "-h" ]];then
  help
  exit 1
fi


TMP_FILE=./tmp-deploy-yaml
NAMESPACE=default
IMAGE=swr.cn-south-1.myhuaweicloud.com/fxq/perf-nginx:v10.1
deploynums=$1
podnums=$2
nums=$((${deploynums}*${podnums}))


#循环构造deploy的yaml文件
function gen_deploy_yaml(){
  for i in `seq 1 $deploynums`
    do 
      \cp -x  deploy.yaml $TMP_FILE/deploy-$i.yaml
      new_file=$TMP_FILE/deploy-$i.yaml
      sed -i s/PODNUMS/$podnums/g $new_file
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

#计算时间差（毫秒）
function get_time_ms(){
    start_time=$1
    end_time=$2
    start_time_s=`echo $start_time | cut -d '.' -f 1`
    start_time_ns=`echo $start_time | cut -d '.' -f 2`
    end_time_s=`echo $end_time | cut -d '.' -f 1`
    end_time_ns=`echo $end_time | cut -d '.' -f 2`
    total_time=$(( (10#$end_time_s - 10#$start_time_s) * 1000 + ( 10#$end_time_ns / 1000000 - 10#$start_time_ns / 1000000 ) ))
}


#main函数
mkdir -p $TMP_FILE
gen_deploy_yaml
start_time=`date +%s.%N`
echo "`date +%Y-%m-%d' '%H:%M:%S.%N` begin to create deploy"
kubectl apply -f $TMP_FILE > /dev/null
check_deploy_created
end_time=`date +%s.%N`
get_time_ms $start_time $end_time
echo "total_time is $total_time ms"

