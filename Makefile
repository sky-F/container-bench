mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
current_dir := $(dir $(mkfile_path))
# import config.
# You can change the default config with `make cnf="config_special.env" build`
cnf ?= config.env
include $(cnf)
export $(shell sed 's/=.*//' $(cnf))

# HELP
# This will output the help for each task
# thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help clean4 waiting test_ddd

help: ## This help.
	echo $(dir $(mkfile_path))
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_0-9-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help


image: ## build image
	docker build -f $(current_dir)/dockerfiles/Dockerfile.fortio -t $(swr)/$(fortioimage) $(current_dir)/script
	docker push $(swr)/$(fortioimage)
	docker rmi $(swr)/$(fortioimage)

base_image: ## build image
	cd $(current_dir)/script; docker build -t $(swr)/$(fortioimage) - < $(current_dir)/dockerfiles/Dockerfile.fortio
	docker push $(swr)/$(fortioimage)
	docker rmi $(swr)/$(fortioimage)
	cd $(current_dir)/script; docker build -t $(swr)/$(baseimage) - < $(current_dir)/dockerfiles/Dockerfile.perf-nginx
	docker push $(swr)/$(baseimage)
	docker rmi $(swr)/$(baseimage)
	cd $(current_dir)/script; docker build -t $(swr)/$(prometheusimage) - < $(current_dir)/dockerfiles/Dockerfile.prometheus
	docker push $(swr)/$(prometheusimage)
	docker rmi $(swr)/$(prometheusimage)
	cd $(current_dir)/script; docker build -t $(swr)/$(grafanaimage) -< $(current_dir)/dockerfiles/Dockerfile.grafana
	docker push $(swr)/$(grafanaimage)
	docker rmi $(swr)/$(grafanaimage)
	cd $(current_dir)/script; docker build -t $(swr)/$(processimage)  -< $(current_dir)/dockerfiles/Dockerfile.process 
	docker push $(swr)/$(processimage)
	docker rmi $(swr)/$(processimage)
	cd $(current_dir)/script; docker build -t $(swr)/$(nodeimage) -<  $(current_dir)/dockerfiles/Dockerfile.node
	docker push $(swr)/$(nodeimage)
	docker rmi $(swr)/$(nodeimage)
	cd $(current_dir)/script; docker build -t $(swr)/$(sysbench) -<  $(current_dir)/dockerfiles/Dockerfile.sysbench
	docker push $(swr)/$(sysbench)
	docker rmi $(swr)/$(sysbench)
	cd $(current_dir)/script; docker build -t $(swr)/$(memtier) -<  $(current_dir)/dockerfiles/Dockerfile.memtier
	docker push $(swr)/$(memtier)
	docker rmi $(swr)/$(memtier)
	cd $(current_dir)/script; docker build -t $(swr)/busybox -<  $(current_dir)/dockerfiles/Dockerfile.busybox
	docker push $(swr)/busybox
	docker rmi $(swr)/busybox
	cd $(current_dir)/script; docker build -t $(swr)/$(dnsperf) -<  $(current_dir)/dockerfiles/Dockerfile.dnsperf
	docker push $(swr)/$(dnsperf)
	docker rmi $(swr)/$(dnsperf)
	cd $(current_dir)/script; docker build -t $(swr)/$(resource) -<  $(current_dir)/dockerfiles/Dockerfile.resource
	docker push $(swr)/$(resource)
	docker rmi $(swr)/$(resource)

moreimage: ## build image special l layer and c size
	dd if=/dev/urandom of=sample bs=1M count=$(c)
	bash $(current_dir)/script/create_image.sh $(l) $(swr)/$(baseimage) $(swr)/$(image)
	docker push $(swr)/$(image)
	docker rmi $(swr)/$(image)

server: ## create a server for ping
	bash $(current_dir)/script/benchmark-create-pod.sh --pod-num 1 --name perf-server --namespace $(namespace) --pod-template $(current_dir)/pod-template/pod.json --image $(swr)/$(serverimage)
        
metrics: ## create a grafana and process-exporter
	make monit; make process; make node

cert:
	python pys/get_certs.py
	mkdir -p cert
	mv client.key client.crt cert
	kubectl create cm cert --from-file=cert

monit: cert
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --pod-num 1 --name grafana-server --namespace $(namespace) --pod-template $(current_dir)/deploy-template/grafana-server.json --image $(swr)/$(grafanaimage)
	bash $(current_dir)/script/benchmark-create-svc.sh --deploy-num 1 --pod-num 1 --name grafana-server --namespace $(namespace) --pod-template $(current_dir)/svc-template/grafana_svc.json 
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --pod-num 1 --name prometheus-server --namespace $(namespace) --pod-template $(current_dir)/deploy-template/promethus-server.json --image $(swr)/$(prometheusimage)
	bash $(current_dir)/script/benchmark-create-svc.sh --deploy-num 1 --pod-num 1 --name prometheus-server --namespace $(namespace) --pod-template $(current_dir)/svc-template/prometheus_svc.json 

process:
	bash $(current_dir)/script/benchmark-create-ds.sh --pod-num 1 --name process-exporter --namespace $(namespace) --pod-template $(current_dir)/ds-template/process-exporter.json --image $(swr)/$(processimage)

cadvisor:
	bash $(current_dir)/script/benchmark-create-ds.sh --pod-num 1 --name cadvisor-exporter --namespace $(namespace) --pod-template $(current_dir)/ds-template/cadvisor-exporter.json --image $(swr)/$(fortioimage)

node:
	bash $(current_dir)/script/benchmark-create-ds.sh --pod-num 1 --name node-exporter --namespace $(namespace) --pod-template $(current_dir)/ds-template/node-exporter.json --image $(swr)/$(nodeimage)

fortio:
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 1 --pod-num 1 --name fortio --namespace $(namespace) --pod-template $(current_dir)/deploy-template/fortio.json --image $(swr)/$(fortioimage)

asm_server: 
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 1 --pod-num 1 --name asm-server --namespace $(namespace) --pod-template $(current_dir)/deploy-template/fortio.json --image $(swr)/$(fortioimage)
	bash $(current_dir)/script/benchmark-create-svc.sh --deploy-num 1 --pod-num 1 --name asm-server --namespace $(namespace) --pod-template $(current_dir)/svc-template/fortio_svc.json 

asm_client:
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 1 --pod-num 1 --name asm-client --namespace $(namespace) --pod-template $(current_dir)/deploy-template/fortio.json --image $(swr)/$(fortioimage)
	bash $(current_dir)/script/benchmark-create-svc.sh --deploy-num 1 --pod-num 1 --name asm-client --namespace $(namespace) --pod-template $(current_dir)/svc-template/fortio_svc.json 

asm_server_inject_http:
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 1 --pod-num 1 --name asm-server --namespace $(namespace) --pod-template $(current_dir)/deploy-template/fortio_inject.json --image $(swr)/$(fortioimage)
	bash $(current_dir)/script/benchmark-create-svc.sh --deploy-num 1 --pod-num 1 --name asm-server --namespace $(namespace) --pod-template $(current_dir)/svc-template/fortio_svc.json 
	KUBECONFIG=$(control_plane) bash $(current_dir)/script/benchmark-create-dr.sh --deploy-num 1 --pod-num 1 --name asm-server --namespace $(namespace) --pod-template $(current_dir)/svc-template/dr.json 
	KUBECONFIG=$(control_plane) bash $(current_dir)/script/benchmark-create-vs.sh --deploy-num 1 --pod-num 1 --name asm-server --namespace $(namespace) --pod-template $(current_dir)/svc-template/vs_http.json 

asm_forword_inject_http:
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 1 --pod-num 1 --name asm-forword --namespace $(namespace) --pod-template $(current_dir)/deploy-template/fortio_forword_inject.json --image $(swr)/$(fortioimage)
	bash $(current_dir)/script/benchmark-create-svc.sh --deploy-num 1 --pod-num 1 --name asm-forword --namespace $(namespace) --pod-template $(current_dir)/svc-template/fortio_forword_svc.json 
	KUBECONFIG=$(control_plane) bash $(current_dir)/script/benchmark-create-dr.sh --deploy-num 1 --pod-num 1 --name asm-forword --namespace $(namespace) --pod-template $(current_dir)/svc-template/dr.json 
	KUBECONFIG=$(control_plane) bash $(current_dir)/script/benchmark-create-vs.sh --deploy-num 1 --pod-num 1 --name asm-forword --namespace $(namespace) --pod-template $(current_dir)/svc-template/vs_forword_http.json 

asm_client_inject_http:
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 1 --pod-num 1 --name asm-client --namespace $(namespace) --pod-template $(current_dir)/deploy-template/fortio_inject.json --image $(swr)/$(fortioimage)
	bash $(current_dir)/script/benchmark-create-svc.sh --deploy-num 1 --pod-num 1 --name asm-client --namespace $(namespace) --pod-template $(current_dir)/svc-template/fortio_svc.json 
	KUBECONFIG=$(control_plane) bash $(current_dir)/script/benchmark-create-dr.sh --deploy-num 1 --pod-num 1 --name asm-client --namespace $(namespace) --pod-template $(current_dir)/svc-template/dr.json 
	KUBECONFIG=$(control_plane) bash $(current_dir)/script/benchmark-create-vs.sh --deploy-num 1 --pod-num 1 --name asm-client --namespace $(namespace) --pod-template $(current_dir)/svc-template/vs_http.json 

asm_client_inject_tcp: ## client inject tcp proxy
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 1 --pod-num 1 --name asm-client --namespace $(namespace) --pod-template $(current_dir)/deploy-template/fortio_inject.json --image $(swr)/$(fortioimage)
	bash $(current_dir)/script/benchmark-create-svc.sh --deploy-num 1 --pod-num 1 --name asm-client --namespace $(namespace) --pod-template $(current_dir)/svc-template/fortio_svc_tcp.json 
	KUBECONFIG=$(control_plane) bash $(current_dir)/script/benchmark-create-dr.sh --deploy-num 1 --pod-num 1 --name asm-client --namespace $(namespace) --pod-template $(current_dir)/svc-template/dr.json 
	KUBECONFIG=$(control_plane) bash $(current_dir)/script/benchmark-create-vs.sh --deploy-num 1 --pod-num 1 --name asm-client --namespace $(namespace) --pod-template $(current_dir)/svc-template/vs_tcp.json 

asm_forword_inject_tcp: ## forword inject tcp proxy
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 1 --pod-num 1 --name asm-forword --namespace $(namespace) --pod-template $(current_dir)/deploy-template/fortio_forword_inject.json --image $(swr)/$(fortioimage)
	bash $(current_dir)/script/benchmark-create-svc.sh --deploy-num 1 --pod-num 1 --name asm-forword --namespace $(namespace) --pod-template $(current_dir)/svc-template/fortio_forword_svc_tcp.json 
	KUBECONFIG=$(control_plane) bash $(current_dir)/script/benchmark-create-dr.sh --deploy-num 1 --pod-num 1 --name asm-forword --namespace $(namespace) --pod-template $(current_dir)/svc-template/dr.json 
	KUBECONFIG=$(control_plane) bash $(current_dir)/script/benchmark-create-vs.sh --deploy-num 1 --pod-num 1 --name asm-forword --namespace $(namespace) --pod-template $(current_dir)/svc-template/vs_forword_tcp.json 

asm_server_inject_tcp: ## server inject tcp proxy
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 1 --pod-num 1 --name asm-server --namespace $(namespace) --pod-template $(current_dir)/deploy-template/fortio_inject.json --image $(swr)/$(fortioimage)
	bash $(current_dir)/script/benchmark-create-svc.sh --deploy-num 1 --pod-num 1 --name asm-server --namespace $(namespace) --pod-template $(current_dir)/svc-template/fortio_svc_tcp.json 
	KUBECONFIG=$(control_plane) bash $(current_dir)/script/benchmark-create-dr.sh --deploy-num 1 --pod-num 1 --name asm-server --namespace $(namespace) --pod-template $(current_dir)/svc-template/dr.json 
	KUBECONFIG=$(control_plane) bash $(current_dir)/script/benchmark-create-vs.sh --deploy-num 1 --pod-num 1 --name asm-server --namespace $(namespace) --pod-template $(current_dir)/svc-template/vs_tcp.json 

asm_sc: clean4 waiting asm_client asm_server  ## create s->c module
	make waiting
	mkdir -p $(current_dir)\logs
	prometheus_url=$(prometheus_url) default_cluster=$(default_cluster) bash -x $(current_dir)/script/asm_latency_http.sh $(namespace) http://asm-server-1:8080 2>logs/sc_http.log 1>&2
	prometheus_url=$(prometheus_url) default_cluster=$(default_cluster) bash -x $(current_dir)/script/asm_latency_grpc.sh $(namespace) http://asm-server-1:8079 2>logs/sc_grpc.log 1>&2
asm_scp_http: clean4 waiting asm_client asm_server_inject_http ## create s->cp module
	make waiting
	mkdir -p $(current_dir)\logs
	prometheus_url=$(prometheus_url) default_cluster=$(default_cluster) bash -x $(current_dir)/script/asm_latency_http.sh $(namespace) http://asm-server-1:8080 2>logs/http_scp_http.log 1>&2
	prometheus_url=$(prometheus_url) default_cluster=$(default_cluster) bash -x $(current_dir)/script/asm_latency_grpc.sh $(namespace) http://asm-server-1:8079 2>logs/scp_grpc.log 1>&2
asm_spcp_http: clean4 waiting asm_client_inject_http asm_server_inject_http ## create sp->cp module
	make waiting
	mkdir -p $(current_dir)\logs
	prometheus_url=$(prometheus_url) default_cluster=$(default_cluster) bash -x $(current_dir)/script/asm_latency_http.sh $(namespace) http://asm-server-1:8080 2>logs/http_spcp_http.log 1>&2
	prometheus_url=$(prometheus_url) default_cluster=$(default_cluster) bash -x $(current_dir)/script/asm_latency_grpc.sh $(namespace) http://asm-server-1:8079 2>logs/spcp_grpc.log 1>&2
asm_spfpcp_http: clean4 waiting asm_server_inject_http asm_client_inject_http asm_forword_inject_http ## create sp->fp->cp module
	make waiting
	mkdir -p $(current_dir)\logs
	prometheus_url=$(prometheus_url) default_cluster=$(default_cluster) bash -x $(current_dir)/script/asm_latency_http.sh $(namespace) http://asm-forword-1:8888 2>logs/http_spfpcp_http.log 1>&2
asm_scp_tcp: clean4 waiting asm_client asm_server_inject_tcp ## create s->cp module
	make waiting
	mkdir -p $(current_dir)\logs
	prometheus_url=$(prometheus_url) default_cluster=$(default_cluster) bash -x $(current_dir)/script/asm_latency_http.sh $(namespace) http://asm-server-1:8080 2>logs/tcp_scp_http.log 1>&2
asm_spcp_tcp: clean4 waiting asm_client_inject_tcp asm_server_inject_tcp ## create tcp sp->cp module
	make waiting
	mkdir -p $(current_dir)\logs
	prometheus_url=$(prometheus_url) default_cluster=$(default_cluster) bash -x $(current_dir)/script/asm_latency_http.sh $(namespace) http://asm-server-1:8080 2>logs/tcp_spcp_http.log 1>&2
asm_spfpcp_tcp: clean4 waiting asm_server_inject_tcp asm_client_inject_tcp asm_forword_inject_tcp ## create tcp sp->fp->cp module
	make waiting
	mkdir -p $(current_dir)\logs
	prometheus_url=$(prometheus_url) default_cluster=$(default_cluster) bash -x $(current_dir)/script/asm_latency_http.sh $(namespace) http://asm-forword-1:8888 2>logs/tcp_spfpcp_http.log 1>&2

all_u_gi: 
	make asm_sc; make asm_scp_http; make asm_spcp_http; make asm_spfpcp_http; make asm_scp_tcp; make asm_spcp_tcp; make asm_spfpcp_tcp

waiting:
	sleep 120

clean4: 
	kubectl get deploy -n $(namespace) -o=jsonpath='{.items[*].metadata.name}'|tr ' ' '\n'|grep -e 'asm' |xargs -i kubectl delete deploy -n $(namespace) --wait=true {}
	kubectl get svc -n $(namespace) -o=jsonpath='{.items[*].metadata.name}'|tr ' ' '\n'|grep -e 'asm' |xargs -i kubectl delete svc -n $(namespace) --wait=true {}
	KUBECONFIG=$(control_plane) sh -c "kubectl get dr -n $(namespace) -o=jsonpath='{.items[*].metadata.name}'|tr ' ' '\n'|grep -e 'asm' |xargs -i kubectl delete dr -n $(namespace) --wait=true {}"
	KUBECONFIG=$(control_plane) sh -c "kubectl get vs -n $(namespace) -o=jsonpath='{.items[*].metadata.name}'|tr ' ' '\n'|grep -e 'asm' |xargs -i kubectl delete vs -n $(namespace) --wait=true {}"

clean3: 
	kubectl get deploy -n $(namespace) -o=jsonpath='{.items[*].metadata.name}'|tr ' ' '\n'|grep -e 'grafana' -e 'prometheus'|xargs -i kubectl delete deploy -n $(namespace) --wait=true {}
	kubectl get ds -n $(namespace) -o=jsonpath='{.items[*].metadata.name}'|tr ' ' '\n'|grep -e process -e cadvisor|xargs -i kubectl delete ds -n $(namespace) --wait=true {}
	kubectl delete pods -n $(namespace) perf-server-1

clean2:
	kubectl get pods -n $(namespace) -o=jsonpath='{.items[*].metadata.name}'|tr ' ' '\n'|grep 'perf-hostnetwork'|xargs -i kubectl delete pod -n $(namespace) --ignore-not-found=true --wait=true {}

clean: ## clean deploy pod and pvc
	echo "Clean start:              `date +%Y-%m-%d' '%H:%M:%S.%N`"
	#kubectl get svc -n $(namespace) -o=jsonpath='{.items[*].metadata.name}'|tr ' ' '\n'|grep 'perf-test'|xargs -i kubectl delete svc -n $(namespace) --ignore-not-found=true --wait=true {}
	kubectl get deploy -n $(namespace) -o=jsonpath='{.items[*].metadata.name}'|tr ' ' '\n'|grep -e 'perf-test' -e 'fortio'|xargs -i kubectl delete deploy -n $(namespace) --wait=true {}
	kubectl get pods -n $(namespace) -o=jsonpath='{.items[*].metadata.name}'|tr ' ' '\n'|grep 'perf-test'|xargs -i kubectl delete pod -n $(namespace) --ignore-not-found=true --wait=true {}
	kubectl get pvc -n $(namespace) -o=jsonpath='{.items[*].metadata.name}'|tr ' ' '\n'|grep 'perf-test'|xargs -i kubectl delete pvc -n $(namespace) --ignore-not-found=true --wait=true {}
	kubectl get pv -o=jsonpath='{.items[*].metadata.name}'|tr ' ' '\n'|grep 'perf-test'|xargs -i kubectl delete pv --ignore-not-found=true --wait=true {}
	echo "Clean end:                `date +%Y-%m-%d' '%H:%M:%S.%N`"

count: ## count node for each pod
	kubectl get pods -n $(namespace) -owide|awk '{print $$7}'|tr -s ' ' '\n'|sort |uniq -c|sort -r |awk '{print $$2, $$1}'
count2: 
	kubectl get pods -n $(namespace) -owide|awk '{print $$7"-"$$3}'|tr -s ' ' '\n'|sort |uniq -c|sort -r |awk '{print $$2, $$1}'
count3:
	kubectl get pni -ojsonpath='{range .items[*]}{.metadata.name}{"\t"}{..labels}{"\t"}{.spec.securityGroup.defaultSecurityGroupIDs}{"\t"}{.status.securityGroupIDs}{"\t"}{.spec.securityGroup.securityGroupNames}{"\n"}{end}' -nkube-system|grep -oE -e 'pni-node-name":"[^\"]+' -e 'pni-phase":"\w+'|xargs|sed 's/pni-node-name:/\n/g'|awk '{print $$1" "$$2}'|sort|uniq -c|awk '{print $$2" "$$3" "$$1}'|sort -r

1: ## create one pod
	. $(current_dir)/script/get_token.sh; \
	bash $(current_dir)/script/benchmark-create-pod.sh --pod-num 1 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/pod-template/pod-network.json --image $(swr)/$(image)

1000: ## create 1000 pod
	. $(current_dir)/script/get_token.sh; \
	bash $(current_dir)/script/benchmark-create-pod.sh --pod-num 1000 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/pod-template/pod-network.json --image $(swr)/$(image)

deploy1: ## create one deploy with one pod
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 1 --pod-num 1 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test.json --image $(swr)/$(image)
	#bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 1 --pod-num 1 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/fortio.json --image $(swr)/$(fortioimage)
	bash $(current_dir)/script/benchmark-create-svc.sh --deploy-num 1 --pod-num 1 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/svc-template/svc.json 
	bash $(current_dir)/script/benchmark-create-svc.sh --deploy-num 1 --pod-num 1 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/svc-template/svc-nodeport-local.json 
	bash $(current_dir)/script/benchmark-create-svc.sh --deploy-num 1 --pod-num 1 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/svc-template/svc-nodeport-cluster.json 

deploy20: ## create one deploy with 20 pod
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 1 --pod-num 20 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test.json --image $(swr)/$(image)

deploy1000: ## create one deploy with 1000 pod
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 1 --pod-num 1000 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test.json --image $(swr)/$(image)

deploy2: ## create Two deploy with one pod
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 2 --pod-num 1 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test.json --image $(swr)/$(image)

host2: ## create Two deploy with one pod
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 2 --pod-num 1 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test-hostnetwork.json --image $(swr)/$(image)

eni: ## create one deploy with 1 pod
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 1 --pod-num 1 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test_eni.json --image $(swr)/$(image)

eni20: ## create one deploy with 20 pod
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 1 --pod-num 20 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test_eni.json --image $(swr)/$(image)

eni30: ## create one deploy with 20 pod
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 1 --pod-num 30 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test_eni.json --image $(swr)/$(image)

eni40: ## create one deploy with 20 pod
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 1 --pod-num 40 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test_eni.json --image $(swr)/$(image)

eni50: ## create one deploy with 20 pod
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 1 --pod-num 50 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test_eni.json --image $(swr)/$(image)

eni60: ## create one deploy with 20 pod
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 1 --pod-num 60 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test_eni.json --image $(swr)/$(image)

eni80: ## create one deploy with 20 pod
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 1 --pod-num 80 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test_eni.json --image $(swr)/$(image)

eni100: ## create one deploy with 20 pod
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 1 --pod-num 100 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test_eni.json --image $(swr)/$(image)

eni200: ## create one deploy with 20 pod
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 1 --pod-num 200 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test_eni.json --image $(swr)/$(image)

eni400: ## create one deploy with 20 pod
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 1 --pod-num 400 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test_eni.json --image $(swr)/$(image)

eni600: ## create one deploy with 20 pod
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 1 --pod-num 600 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test_eni.json --image $(swr)/$(image)

eni1200: ## create one deploy with 20 pod
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 1 --pod-num 1200 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test_eni.json --image $(swr)/$(image)

eni1800: ## create one deploy with 20 pod
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 1 --pod-num 1800 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test_eni.json --image $(swr)/$(image)

eni2400: ## create one deploy with 20 pod
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 1 --pod-num 2400 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test_eni.json --image $(swr)/$(image)

eni3000: ## create one deploy with 20 pod
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 1 --pod-num 3000 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test_eni.json --image $(swr)/$(image)

eni3600: ## create one deploy with 20 pod
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 1 --pod-num 3600 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test_eni.json --image $(swr)/$(image)

15deploy: ## create 20 deploy with pvc
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 15 --pod-num 1 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test-evs_eni.json --image $(swr)/$(image)

20deploy: ## create 20 deploy with pvc
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 20 --pod-num 1 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test-evs_eni.json --image $(swr)/$(image)

40deploy: ## create 40 deploy with pvc
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 40 --pod-num 1 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test-evs_eni.json --image $(swr)/$(image)

50deploy: ## create 50 deploy with pvc
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 50 --pod-num 1 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test-evs_eni.json --image $(swr)/$(image)

60deploy: ## create 60 deploy with pvc
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 60 --pod-num 1 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test-evs_eni.json --image $(swr)/$(image)

100deploy: ## create 100 deploy with pvc
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 100 --pod-num 1 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test-evs_eni.json --image $(swr)/$(image)

20deploy100: ## create 20 deploy with pvc total 100 pod
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 20 --pod-num 5 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test-evs_eni.json --image $(swr)/$(image)

alievs = evs-ssd evs-topology evs-avaliable evs-efficiency evs-essd evs-cce-ssd nfs-cce-perf 
allevs: $(alievs) ## evs-ssd evs-topology evs-avaliable evs-efficiency evs-essd evs-cce-ssd nfs-cce-perf 

alobs = obs-cce-obfs obs-cce-s3fs obs-cce-warm
cceobs: $(alobs) ## obs-cce-obfs obs-cce-s3fs obs-cce-warm

$(alievs):
	make clean
	bash $(current_dir)/script/benchmark-create-evs.sh --deploy-num 1 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/pvc-template/$@.json 
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 1 --pod-num 1 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test-evs_eni.json --image $(swr)/$(image)
	prometheus_url=$(prometheus_url) bash $(current_dir)/script/run_fio.sh 50G  2>logs/$@.log 1>&2

$(alobs):
	make clean
	bash $(current_dir)/script/benchmark-create-evs.sh --deploy-num 1 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/pvc-template/$@.json 
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 1 --pod-num 1 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test-evs_eni.json --image $(swr)/$(image)
	prometheus_url=$(prometheus_url) bash $(current_dir)/script/run_fio.sh 10G 2>logs/$@.log 1>&2

nfs-cce-sfsturbo-perf nfs-cce-sfsturbo nfs-perf nfs-extreme: ## nfs-cce-sfsturbo-perf nfs-cce-sfsturbo nfs-perf nfs-extreme
	make clean
	bash $(current_dir)/script/benchmark-create-pv.sh --deploy-num 1 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/pvc-template/$@-pv.json
	bash $(current_dir)/script/benchmark-create-evs.sh --deploy-num 1 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/pvc-template/$@.json 
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 1 --pod-num 1 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test-evs_eni.json --image $(swr)/$(image)
	prometheus_url=$(prometheus_url) bash $(current_dir)/script/run_fio.sh 10G 2>logs/$@.log 1>&2

oss:
	make clean
	bash $(current_dir)/script/benchmark-create-pv.sh --deploy-num 1 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/pvc-template/oss-pv.json
	bash $(current_dir)/script/benchmark-create-evs.sh --deploy-num 1 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/pvc-template/oss.json 
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 1 --pod-num 1 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test-evs_eni.json --image $(swr)/$(image)
	prometheus_url=$(prometheus_url) bash $(current_dir)/script/run_fio.sh 10G 2>logs/$@.log 1>&2

20evs: ## create 20 evs pvc
	bash $(current_dir)/script/benchmark-create-evs.sh --deploy-num 20 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/pvc-template/$(evs).json 

numevs: ## create num evs pvc    make numevs.pvc-template.pvc-name.pvc-num
	bash $(current_dir)script/benchmark-create-evs.sh --namespace $(namespace) --pod-template $(current_dir)/pvc-template/$(word 2, $(subst ., ,$@)).json --name $(word 3, $(subst ., ,$@)) --pvc-num $(word 4, $(subst ., ,$@)) |tee logs/$@.txt 

40evs: ## create 40 evs pvc
	bash $(current_dir)/script/benchmark-create-evs.sh --deploy-num 40 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/pvc-template/$(evs).json 

60evs: ## create 40 evs pvc
	bash $(current_dir)/script/benchmark-create-evs.sh --deploy-num 60 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/pvc-template/$(evs).json 

100evs: ## create 100 evs pvc
	bash $(current_dir)/script/benchmark-create-evs.sh --deploy-num 100 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/pvc-template/$(evs).json 

20nfs-pv: ## create 20 nfs pvc
	bash $(current_dir)/script/benchmark-create-pv.sh --deploy-num 20 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/pvc-template/nfs-pv.json 

20nfs: ## create 20 nfs pvc
	bash $(current_dir)/script/benchmark-create-evs.sh --deploy-num 20 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/pvc-template/$(nfs).json 

2svc2: ## create 2 svc for 2 deploy
	bash $(current_dir)/script/benchmark-create-svc.sh --deploy-num 2 --pod-num 2 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/svc-template/svc.json 

20svc: ## create 20 svc
	bash $(current_dir)/script/benchmark-create-svc.sh --deploy-num 20 --pod-num 1 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/svc-template/svc.json 

2000svc: ## create 2000 svc
	bash $(current_dir)/script/benchmark-create-svc.sh --deploy-num 2000 --pod-num 1 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/svc-template/svc.json 

event: ## get events and pods
	bash $(current_dir)/script/get_pods_logs.sh $(namespace)
	kubectl get events -ojson -n $(namespace) > curl-get-event.log

test: ## test svc
	prometheus_url=$(prometheus_url) bash $(current_dir)/script/run_fortio_in_container.sh $(namespace) http://$(url) 2>logs/podto_${prefix}_$(url).log 1>&2

call_pod_test: ## test
	prefix="pod" url=`kubectl get pods -n $(namespace) --selector app=perf-test-1 -o jsonpath='{.items[0].status.podIP}'` make test

call_svc_test:
	prefix="svc" url=perf-test-1 make test

prepare_vm: ## prepare vm
	cat $(current_dir)/script/prepare_vm.sh | sshpass -p Huawei@123 ssh -oStrictHostKeyChecking=no root@$(nodec) bash -s $(swr)/$(fortioimage) $(swr)/$(nodeimage) $(swr)/$(processimage) $(node)

vm: ## test svc
	prometheus_url=$(prometheus_url) bash $(current_dir)/script/run_fortio_in_vm.sh http://$(url) $(nodec) $(node) $(qps) 2>logs/vmto_${prefix}_$(url).log 1>&2

call_node_cluster_aff_same: ## call node port cluster affinity same node
	url=`kubectl get pods -n $(namespace) --selector app=perf-test-1 -o jsonpath='{.items[0].status.hostIP}'`:`kubectl get svc perf-test-1-nodeport-cluster -n $(namespace) -o jsonpath="{.spec.ports[0].nodePort}"` prefix='nodeport_cluster_aff_same' qps=1000 make vm

call_node_local_aff_same: ## call node port node affinity same node
	url=`kubectl get pods -n $(namespace) --selector app=perf-test-1 -o jsonpath='{.items[0].status.hostIP}'`:`kubectl get svc perf-test-1-nodeport-local -n $(namespace) -o jsonpath="{.spec.ports[0].nodePort}"` prefix='nodeport_local_aff' qps=1000 make vm

call_ingress: ## call ingress from node
	url=`kubectl get ingress ingress -ojsonpath='{.status.loadBalancer.ingress[0].ip}'` prefix='ingress' qps=1000 make vm

alielbs = slb.s1.small slb.s2.small slb.s2.medium slb.s3.small slb.s3.medium slb.s3.large
alllbs: $(alielbs) ## slb.s1.small slb.s2.small slb.s2.medium slb.s3.small slb.s3.medium slb.s3.large
$(alielbs):
	bash $(current_dir)/script/benchmark-create-lb.sh --deploy-num 1 --pod-num 1 --name perf-test --namespace $(namespace) --flavor $@ --pod-template $(current_dir)/svc-template/$(lb).json
	sleep 120
	url=`kubectl get svc perf-test-1-lb-auto -ojsonpath='{.status.loadBalancer.ingress[0].ip}'` prefix=$@ qps=1000 make vm
	kubectl delete svc perf-test-1-lb-auto
	sleep 60
	

node_metric200: clean ## node_metric
	prometheus_url=$(prometheus_url) node_ip=$(nodem) bash $(current_dir)/script/get_node_metric.sh 2>logs/$@.log 1>&2
	make eni200
	sleep 60
	prometheus_url=$(prometheus_url) node_ip=$(nodem) bash $(current_dir)/script/get_node_metric.sh 2>>logs/$@.log 1>&2
	
node_metric400: clean ## node_metric
	prometheus_url=$(prometheus_url) node_ip=$(nodem) bash $(current_dir)/script/get_node_metric.sh 2>logs/$@.log 1>&2
	make eni400
	sleep 60
	prometheus_url=$(prometheus_url) node_ip=$(nodem) bash $(current_dir)/script/get_node_metric.sh 2>>logs/$@.log 1>&2
	
node_metric: clean ## node_metric
	prometheus_url=$(prometheus_url) node_ip=$(nodem) bash $(current_dir)/script/get_node_metric.sh 2>logs/$@.log 1>&2
	make eni100
	sleep 60
	prometheus_url=$(prometheus_url) node_ip=$(nodem) bash $(current_dir)/script/get_node_metric.sh 2>>logs/$@.log 1>&2
	
svc_metric: deploy2 ## svc_metric
	prometheus_url=$(prometheus_url) node_ip=$(nodem) namespace=$(namespace) bash $(current_dir)/script/run_svc.sh 2>logs/$@.log 1>&2

throughput_metric: ##  throughput_metric
	FAST=$(FAST) prometheus_url=$(prometheus_url) bash -x $(current_dir)/script/run_network_throughput.sh 2>logs/$@.log 1>&2

pps_metric: deploy2 ##  pps_metric
	prometheus_url=$(prometheus_url) bash -x $(current_dir)/script/run_network_pps.sh 2>logs/$@.log 1>&2

connect_metric: deploy2 ##  connect_metric
	prometheus_url=$(prometheus_url) bash -x $(current_dir)/script/run_network_connect.sh 2>logs/$@.log 1>&2

run_network_lat: deploy2 ##  connect_metric
	prometheus_url=$(prometheus_url) bash -x $(current_dir)/script/run_network_lat.sh 2>logs/$@.log 1>&2

service_metric: deploy1 fortio ##  service_metric
	prometheus_url=$(prometheus_url) bash -x $(current_dir)/script/run_network_service_short.sh 2>logs/$@.log 1>&2

pod_metric: deploy1 fortio ##  pod_metric
	prometheus_url=$(prometheus_url) bash -x $(current_dir)/script/run_network_nginx.sh 2>logs/$@.log 1>&2

container_invoke: ## call_pod_test call_svc_test service_metric pod_metric
	make call_pod_test
	sleep 120
	make call_svc_test
	sleep 120
	make pod_metric
	sleep 120
	make service_metric
	sleep 120
l4test: ## call l4test of Makefile_network
	$(MAKE) l4test -f $(current_dir)/Makefile_network

l7test: ## call l7test of Makefile_network
	$(MAKE) l7test -f $(current_dir)/Makefile_network

l4testold: 
	make run_network_lat
	sleep 120
	make pps_metric
	sleep 120
	make throughput_metric
	sleep 120
	make connect_metric
	sleep 120
ccestoragetest: ## evs-cce-ssd nfs-cce-perf nfs-cce-sfsturbo-perf nfs-cce-sfsturbo obs-cce-obfs obs-cce-s3fs obs-cce-warm 
	#make evs-cce-ssd
	#make clean
	#make nfs-cce-perf
	#make clean
	make nfs-cce-sfsturbo-perf
	make clean
	make nfs-cce-sfsturbo
	make clean
	make obs-cce-obfs
	make clean
	make obs-cce-s3fs
	make clean
	make obs-cce-warm
	make clean

cce_cluster: ## get cluster
	. $(current_dir)/script/get_token.sh; \
	time bash $(current_dir)/script/get_cce_cluster.sh  $(cluster_name)

ecs: ## get ecs
	. $(current_dir)/script/get_token.sh; \
	time bash $(current_dir)/script/get_ecs.sh 


cce_nodepools: ## get token
	. $(current_dir)/script/get_token.sh; \
	. $(current_dir)/script/get_cce_cluster.sh $(cluster_name); \
	time bash $(current_dir)/script/get_cce_nodepools.sh

scale_nodepools: ## get token
	. $(current_dir)/script/get_token.sh; \
	. $(current_dir)/script/get_cce_cluster.sh $(cluster_name); \
	time bash $(current_dir)/script/scale_nodepools.sh $(size) $(pool_ids)

watchpods: ## monit pods to record scaling
	bash $(current_dir)/script/benchmark-monit-pods2.sh --namespace $(namespace) --name perf-test

watchpods2: ## monit pods to record scaling
	bash $(current_dir)/script/benchmark-monit-pods2.sh --namespace A --name perf-test


