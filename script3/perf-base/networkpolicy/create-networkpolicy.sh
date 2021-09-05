#!/bin/bash
###usage:bash create-networkpolciy.sh nums
###nums:带创建的数量

help(){
  sed -rn 's/^### ?//;T;p;' "$0"
}
if [[ $# == 0 ]] || [[ "$1" == "-h" ]];then
  help
  exit 1
fi

TMP_FILE=tmp-networkpolicy-yaml
nums=$1

function gen_networkpolicy_yaml(){
  for i in `seq 1 $nums`
    do 
      \cp -x  networkpolicy.yaml $TMP_FILE/networkpolicy-$i.yaml
      new_file=$TMP_FILE/networkpolicy-$i.yaml
      sed -i s/NUMS/$i/g $new_file
    done
}


function check_np_created(){
  while true
    created=`kubectl get networkpolicy |grep np| wc -l`
    do
      if [ $created != $nums ];then
        echo "`date +%Y-%m-%d' '%H:%M:%S.%N` $created networkpolicy is created!"
        sleep 0.5
      else
        break
      fi
    done
echo "`date  +%Y-%m-%d' '%H:%M:%S.%N` all networkpolicy ($nums) created ok!"
}



mkdir -p $TMP_FILE
gen_networkpolicy_yaml
echo "`date +%Y-%m-%d' '%H:%M:%S.%N` begin to create networkpolicy"
kubectl apply -f $TMP_FILE > /dev/null &
check_np_created

