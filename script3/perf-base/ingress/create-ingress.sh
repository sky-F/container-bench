#!/bin/bash
###usage:bash create-ingress.sh nums namespace
###nodeport:需要绑定的nodeprt类型service名称前缀----暂不使用
###nums:需要创建ingress的数量
###namespace:需要部署所在的namespace

help(){
  sed -rn 's/^### ?//;T;p;' "$0"
}
if [[ $# == 0 ]] || [[ "$1" == "-h" ]];then
  help
  exit 1
fi


TMP_FILE=./tmp-ingress-yaml
#nodeport=$1
nums=$1
NAMESPACE=$2

#循环构造service的yaml文件
function gen_ingress_yaml(){
  for i in `seq 1 $nums`
    do
      \cp -x  ingress.yaml $TMP_FILE/ingress-$i.yaml
      new_file=$TMP_FILE/ingress-$i.yaml
      sed -i s/NUMS/$i/g $new_file
      sed -i s/NAMESPACE/$NAMESPACE/g $new_file
      sed -i s/PORTS/$((43000+$i))/g $new_file
    done
}

#判断ingress是否创建完成
function check_ingress_created(){
  while true
    created=`kubectl get ingress -n $NAMESPACE | grep "ingress" | wc -l`
    do
      if [ $created != $nums ];then
        echo "`date +%Y-%m-%d' '%H:%M:%S.%N` $created ingress is created!"
        sleep 0.5
      else
        break
      fi
    done
echo "`date  +%Y-%m-%d' '%H:%M:%S.%N` all ingress ($nums) created ok!"
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
gen_ingress_yaml
echo "`date +%Y-%m-%d' '%H:%M:%S.%N` begin to create ingress"
start_time=`date +%s.%N`
kubectl apply -f $TMP_FILE > /dev/null
check_ingress_created
end_time=`date +%s.%N`
get_time_ms $start_time $end_time
echo "total_time is $total_time ms"
