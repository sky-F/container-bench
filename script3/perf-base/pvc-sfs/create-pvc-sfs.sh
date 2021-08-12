#!/bin/bash
###usage:bash create-pvc-sfs.sh nums
###nums:需要创建pvcsfs的数量

help(){
  sed -rn 's/^### ?//;T;p;' "$0"
}
if [[ $# == 0 ]] || [[ "$1" == "-h" ]];then
  help
  exit 1
fi

BASENAME="pvcsfs"
NAMESPACE="default"
TMP_FILE=./tmp-pvcsfs-yaml
nums=$1

#循环构造ns的yaml文件
function gen_pvc_yaml(){
  for i in `seq 1 $nums`
    do 
      \cp -x  pvcsfs-template.yaml $TMP_FILE/pvcsfs-$i.yaml
      new_file=$TMP_FILE/pvcsfs-$i.yaml
      sed -i s/PVC_EVS_NAME/${BASENAME}-$i/g $new_file
      sed -i s/NAMESPACE/${NAMESPACE}/g $new_file
    done
}

#判断cm是否创建完成
function check_pvc_created(){
  while true
    created=`kubectl get pvc  | grep ${BASENAME} | grep Bound| wc -l`
    do
      if [ $created != $nums ];then
        echo "`date +%Y-%m-%d' '%H:%M:%S.%N` ${created} pvcevs is created!"
        sleep 0.1
      else
        break
      fi
    done
echo "`date  +%Y-%m-%d' '%H:%M:%S.%N` all pvcevs ($nums) created ok!"
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
gen_pvc_yaml
start_time=`date +%s.%N`
echo "`date +%Y-%m-%d' '%H:%M:%S.%N` begin to create pvcevs"
kubectl apply -f $TMP_FILE > /dev/null &
check_pvc_created
end_time=`date +%s.%N`
get_time_ms $start_time $end_time
echo "total_time is $total_time ms"
