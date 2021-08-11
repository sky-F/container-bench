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
    echo  "`date`: pod is deleted  ${count} pod "
    if [ $count -eq $pod_num ]; then
	end_time=`date +%s`
        echo "`date`: pod is delete all OK"
        break
    else
        sleep 0.5
    fi
done
}

deploy_name=$1
pod_num=$2

start_time=`date +%s`
echo "`date`: pod is start to delete"
kubectl get deploy | grep ${deploy_name}  | awk '{print $1}' | xargs -I {} kubectl delete deploy {} > /dev/null
check_pod_delete
echo "total_time is $((${end_time}-${start_time})) seconds"
