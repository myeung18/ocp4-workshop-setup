#!/bin/bash

source ../dap-service.config
source ../conjur_utils.sh

main() {
    oc login -u $CLUSTER_ADMIN
    clean_poc_app
    if [[ "$1" == "clean" ]]; then
        exit 0
    fi
    create_namespace_with_rbac
    create_dap_config_cm
    create_secretless_config_cm
    deploy_poc_app
    create_host_permission
}

clean_poc_app() {
  for (( unum=1; unum<=$NUM_ATTENDEES; unum++ ))	# apply manifest for namespace and user 
  do
    uname=$(echo user${unum})
    oc delete -f $uname-app-poc-manifest.yaml -n $uname --ignore-not-found --force=true --grace-period=0
    rm -rf $uname-app-poc-manifest.yaml
    oc delete -f $uname-app-namespace.rbac.yaml -n $uname --ignore-not-found --force=true --grace-period=0
    rm -rf $uname-app-namespace.rbac.yaml
    oc delete cm secretless-config -n $uname --ignore-not-found --force=true --grace-period=0
    rm -rf $uname-secretless.yaml
    oc delete cm dap-config -n $uname --ignore-not-found --force=true --grace-period=0
    rm -rf $uname-policy-permission.yaml
  done
}

create_namespace_with_rbac() {
  for (( unum=1; unum<=$NUM_ATTENDEES; unum++ ))	# apply manifest for namespace and user 
  do
    uname=$(echo user${unum})
    cat ./templates/app-namespace-rbac.template.yaml				\
    | sed -e "s#{{ APP_NAMESPACE_NAME }}#$uname#g" 				\
    | sed -e "s#{{ APP_NAMESPACE_ADMIN }}#$uname#g"				\
    | sed -e "s#{{ APP_NUM }}#$unum#g"				\
    | sed -e "s#{{ CYBERARK_NAMESPACE_NAME }}#$CYBERARK_NAMESPACE_NAME#g" 	\
    > ./$uname-app-namespace.rbac.yaml
    oc apply -f ./$uname-app-namespace.rbac.yaml -n $uname
  done
}

deploy_poc_app() {
  for (( unum=1; unum<=$NUM_ATTENDEES; unum++ ))	# apply manifest for namespace and user 
  do
    uname=$(echo user${unum})

    oc adm policy add-scc-to-user anyuid -z $(echo os-climate-app-team${unum}) -n $uname
    cat ./templates/app-poc-manifest.template.yaml				\
    | sed -e "s#{{ APP_NAMESPACE_NAME }}#$uname#g" 				\
    | sed -e "s#{{ APP_NAMESPACE_ADMIN }}#$uname#g"				\
    | sed -e "s#{{ APP_NUM }}#$unum#g"				\
    > ./$uname-app-poc-manifest.yaml
    oc apply -f ./$uname-app-poc-manifest.yaml -n $uname

  done
}

create_dap_config_cm() {
  for (( unum=1; unum<=$NUM_ATTENDEES; unum++ ))
  do
    uname=$(echo user${unum})
						    	# deploy dap config map in APP_NAMESPACE
    oc get cm dap-config -n $CYBERARK_NAMESPACE_NAME -o yaml		\
    | sed "s/namespace: $CYBERARK_NAMESPACE_NAME/namespace: $uname/"	\
    | oc apply -f - -n $uname

  done
}

create_secretless_config_cm() {
  for (( unum=1; unum<=$NUM_ATTENDEES; unum++ ))
  do
    uname=$(echo user${unum})

    echo "Create secretless config map... ${uname}"
    cat ./templates/secretless-cm.template.yaml			\
        | sed -e "s#{{ VAULT_NAME }}#$VAULT_NAME#g"		 		\
        | sed -e "s#{{ LOB_NAME }}#$LOB_NAME#g" 				\
        | sed -e "s#{{ SAFE_NAME }}#$SAFE_NAME#g" 			\
        | sed -e "s#{{ APP_NUM }}#$unum#g" 			\
        | sed -e "s#{{ ACCOUNT_NAME }}#$ACCOUNT_NAME#g" 			\
    > ./$uname-secretless.yaml
    oc create cm secretless-config --from-file=secretless.yaml=$uname-secretless.yaml -n $uname
  done
}

create_host_permission() {
  export CONJUR_AUTHN_LOGIN=admin
  export CONJUR_AUTHN_API_KEY=$DAP_ADMIN_PASSWORD

  echo "Creating user permission.."
  for (( unum=1; unum<=$NUM_ATTENDEES; unum++ ))
  do
    uname=$(echo user${unum})
    cat ./templates/user-policy-permission.template.yaml  \
        | sed -e "s#{{ APP_NUM }}#$unum#g" 			\
    > ./$uname-policy-permission.yaml
    conjur_append_policy root ./$uname-policy-permission.yaml
  done
}

main "$@"