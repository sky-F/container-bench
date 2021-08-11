#!/bin/bash
###usage:bash delete.sh deploy_name pod_num
###deploy_name：pod名称前缀（deployment名称）
###pod_num：所有pod总数

help(){
  sed -rn 's/^### ?//;T;p;' "$0"
} 
if [[ $# == 0 ]] || [[ "$1" == "-h" ]];then
  help
  exit 1
fi


function check_pod_delete(){
while true
do
    num=`kubectl get pod | grep ${deploy_name} | wc -l`
    count=$(($pod_num-$num))
    echo  "`date  +%Y-%m-%d' '%H:%M:%S.%N`: pod is deleted  ${count} pod "
    if [ $count -eq $pod_num ]; then
        echo "`date +%Y-%m-%d' '%H:%M:%S.%N`: pod is delete all OK"
	break
    else
        sleep 0.1
    fi
done
}

function get_time_ms(){
    start_time=$1
    end_time=$2
    start_time_s=`echo $start_time | cut -d '.' -f 1`
    start_time_ns=`echo $start_time | cut -d '.' -f 2`
    end_time_s=`echo $end_time | cut -d '.' -f 1`
    end_time_ns=`echo $end_time | cut -d '.' -f 2`
    total_time=$(( (10#$end_time_s - 10#$start_time_s) * 1000 + ( 10#$end_time_ns / 1000000 - 10#$start_time_ns / 1000000 ) ))
}


deploy_name=$1
pod_num=$2

start_time=`date +%s.%N`
echo "`date +%Y-%m-%d' '%H:%M:%S.%N`: pod is start to delete"
kubectl get deploy | grep ${deploy_name}  | awk '{print $1}' | xargs -I {} kubectl delete deploy {} --grace-period=0 --force
kubectl get pod | grep ${deploy_name}  | awk '{print $1}' | xargs -I {} kubectl delete pod {} --grace-period=0 --force
check_pod_delete
end_time=`date +%s.%N`
get_time_ms $start_time $end_time
echo "total_time is $total_time ms"

