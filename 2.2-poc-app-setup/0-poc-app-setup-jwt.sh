#!/bin/bash

source ../dap-service-jwt.config
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
    creating_policies_secrets
}

clean_poc_app() {
  for (( unum=1; unum<=$NUM_ATTENDEES; unum++ ))	# apply manifest for namespace
  do
    uname=$(echo data-team${unum})
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

  for (( unum=1; unum<=$NUM_ATTENDEES; unum++ ))	# apply manifest for namespace
  do
    uname=$(echo data-team${unum})
    echo "Creating namespace and rbac... ${uname}"
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
  for (( unum=1; unum<=$NUM_ATTENDEES; unum++ ))	# apply manifest for namespace
  do
    uname=$(echo data-team${unum})
    echo "Creating poc application... ${uname}"
    oc adm policy add-scc-to-user anyuid -z $(echo ${uname}) -n $uname
    cat ./templates/app-poc-manifest.template.yaml				\
    | sed -e "s#{{ APP_NAMESPACE_NAME }}#$uname#g" 				\
    | sed -e "s#{{ APP_NAMESPACE_ADMIN }}#$uname#g"				\
    | sed -e "s#{{ APP_NUM }}#$unum#g"				\
    | sed -e "s#{{ CONFIG_MAP }}#jwt-dap-config#g"				\
    | sed -e "s#{{ CONJUR_AUTHN_LOGIN }}##g"				\
    > ./$uname-app-poc-manifest.yaml
    oc apply -f ./$uname-app-poc-manifest.yaml -n $uname

  done
}

create_dap_config_cm() {
  for (( unum=1; unum<=$NUM_ATTENDEES; unum++ ))
  do
    uname=$(echo data-team${unum})
						    	# deploy dap config map in APP_NAMESPACE
    oc get cm jwt-dap-config -n $CYBERARK_NAMESPACE_NAME -o yaml		\
    | sed "s/namespace: $CYBERARK_NAMESPACE_NAME/namespace: $uname/"	\
    | oc apply -f - -n $uname

  done
}

create_secretless_config_cm() {
  for (( unum=1; unum<=$NUM_ATTENDEES; unum++ ))
  do
    uname=$(echo data-team${unum})

    echo "Create secretless config map... ${uname}"
    cat ./templates/secretless-cm.template.yaml			\
        | sed -e "s#{{ APP_NUM }}#$unum#g" 			\
    > ./$uname-secretless.yaml
    oc create cm secretless-config --from-file=secretless.yaml=$uname-secretless.yaml -n $uname
  done
}

creating_policies_secrets() {
  echo "Creating policies and secrets..."

  DAP_ADMIN_PASSWORD=$(retrieve_admin_password)
  AUTHN_PASSWORD=$DAP_ADMIN_PASSWORD
  echo "retrieved admin password: $DAP_ADMIN_PASSWORD"

  export CONJUR_AUTHN_LOGIN=admin
  export CONJUR_AUTHN_API_KEY=$DAP_ADMIN_PASSWORD

  ../load_policy.sh root jwt-policies/poc-teams.yaml
  ../load_policy.sh os-climate jwt-policies/poc-sub-teams.yaml
  ../load_policy.sh os-climate/team1 jwt-policies/poc-aws-secrets.yaml
  ../load_policy.sh root jwt-policies/sa-app-id.yaml
  ../load_policy.sh root jwt-policies/poc-entitlements.yaml
  
  ../get_set.sh set os-climate/team1/awscredentials/aws-accesskey $AWS_ACCESS_KEY
  ../get_set.sh set os-climate/team1/awscredentials/aws-secretkey $AWS_SECRET_KEY
}

# create_host_permission() {
#   export CONJUR_AUTHN_LOGIN=admin
#   export CONJUR_AUTHN_API_KEY=$DAP_ADMIN_PASSWORD

#   echo "Creating user permission.."
#   for (( unum=1; unum<=$NUM_ATTENDEES; unum++ ))
#   do
#     uname=$(echo user${unum})
#     cat ./templates/user-policy-permission.template.yaml  \
#         | sed -e "s#{{ APP_NUM }}#$unum#g" 			\
#     > ./$uname-policy-permission.yaml
#     conjur_append_policy root ./$uname-policy-permission.yaml
#   done
# }

main "$@"