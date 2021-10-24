#!/bin/bash
pushd ./1-lab-service-setup
  ./0-namespace-init.sh 
  ./1-master-deploy.sh 
popd
pushd ./2.2-poc-app-setup
    ./0-poc-app-setup.sh
popd
