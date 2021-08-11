#!/bin/bash
dir=`pwd`
cd $dir/configmap;kubectl delete -f tmp-configmap-yaml;rm -rf tmp-configmap-yaml
cd $dir/secret;kubectl delete -f tmp-secret-yaml;rm -rf tmp-secret-yaml
cd $dir/deploy;kubectl delete -f tmp-deploy-yaml;rm -rf tmp-deploy-yaml

