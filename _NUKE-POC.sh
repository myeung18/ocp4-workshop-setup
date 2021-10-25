#!/bin/bash
pushd ./2.2-poc-app-setup
  ./0-poc-app-setup.sh clean
popd
pushd ./1-lab-service-setup
  ./2-mysqldb-deploy.sh clean
  ./1-master-deploy.sh clean
  ./0-namespace-init.sh clean
popd
