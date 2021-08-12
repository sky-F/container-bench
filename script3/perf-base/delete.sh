#!/bin/bash
dir=`pwd`
cd $dir/deploy;kubectl delete -f tmp-deploy-yaml;rm -rf tmp-deploy-yaml
cd $dir/service;kubectl delete -f tmp-service-yaml;rm -rf tmp-service-yaml
cd $dir/configmap;kubectl delete -f tmp-configmap-yaml;rm -rf tmp-configmap-yaml
cd $dir/secret;kubectl delete -f tmp-secret-yaml;rm -rf tmp-secret-yaml
cd $dir/pvc-sfs;kubectl delete -f tmp-pvcsfs-yaml;rm -rf tmp-pvcsfs-yaml
