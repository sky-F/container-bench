#!/bin/bash
###usage:bash create-ns.sh nums
###nums:需要创建namespace的数量

help(){
  sed -rn 's/^### ?//;T;p;' "$0"
}
if [[ $# == 0 ]] || [[ "$1" == "-h" ]];then
  help
  exit 1
fi

BASENAME="test-ns"
TMP_FILE=./tmp-namespace-yaml
nums=$1



function check_ns_delete(){
while true
do
    num=`kubectl get ns | grep ${BASENAME}| wc -l`
    count=$(($nums-$num))
    echo  "`date +%Y-%m-%d' '%H:%M:%S.%N` ${count} namespace is deleted!"
    if [ $count -eq $nums ]; then
	    echo "`date +%Y-%m-%d' '%H:%M:%S.%N`: All namespace($nums) is deleted OK"
        break
    else
        sleep 0.1
    fi
done
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
start_time=`date +%s.%N`
echo "`date +%Y-%m-%d' '%H:%M:%S.%N` begin to delete namesapce"
kubectl delete -f $TMP_FILE > /dev/null &
check_ns_delete
end_time=`date +%s.%N`
get_time_ms $start_time $end_time
echo "total_time is $total_time ms"
rm -rf ${TMP_FILE}

