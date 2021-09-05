while true
do
  kubectl get networkpolicy | awk '{print $1}' | xargs kubectl delete networkpolicy &
  sleep 30 
done
