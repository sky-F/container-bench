
podserver_name=`kubectl get pods --selector app=$server -o jsonpath='{.items[0].metadata.name}'`
podserver_ip=`kubectl get pods --selector app=$server -o jsonpath='{.items[0].status.podIP}'`
nodeserver_ip=`kubectl get pods --selector app=$server -o jsonpath='{.items[0].status.hostIP}'`

podsclient_name=`kubectl get pods -l app=$client -ojsonpath="{range .items[*]}{..metadata.name}{' '}{end}"|tr ' ' '\n'|sort|uniq`
nodesclient_ip=`kubectl get pods -l app=$client -ojsonpath="{range .items[*]}{..hostIP}{' '}{end}"|tr ' ' '\n'|sort|uniq`

kubectl exec $podserver_name -- sh -c 'pkill bash; pkill iperf'
kubectl exec $podclient_name -- pkill iperf
sleep 60
currentTimeStamp=`date +%s.%2N`
sleep 60
python query_csv.py $prometheus_url $currentTimeStamp $nodeserver_ip
for nodeclient_ip in $nodesclient_ip; do
python query_csv.py $prometheus_url $currentTimeStamp $nodeclient_ip
done


currentTimeStamp=`date +%s.%2N`
kubectl exec $podserver_name -- sh -c 'cd /home/paas; bash ./pps_server_iperf.sh 1>/logs.iperf 2>&1; bash ./get_pps.sh eth0 1>pps.log 2>&1 &'
for podclient_name in $podsclient_name; do
{
kubectl exec $podclient_name -- sh -c 'cd /home/paas; bash ./pps_client_iperf.sh '$podserver_ip' 1>/logs.iperf 2>&1'
} &
done
wait 

sleep 120

python query_csv.py $prometheus_url $currentTimeStamp $nodeserver_ip
for nodeclient_ip in $nodesclient_ip; do
python query_csv.py $prometheus_url $currentTimeStamp $nodeclient_ip
done


kubectl exec $podserver_name -- sh -c 'pkill bash; pkill iperf'
for podclient_name in $podsclient_name; do
kubectl exec $podclient_name -- pkill iperf
done
kubectl exec $podserver_name -- sh -c 'cd /home/paas; cat pps.log'


