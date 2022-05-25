#!/bin/bash

# This scripts configures a DAP primary node and sets it up to act as both Primary and Follower.
# A worker node is selected to host the Primary and pinned to it using a nodeSelector.
# This greatly simplifies lab setup by making each lab cluster self-contained.

source ../dap-service.config

if [ -z "${AUTHN_USERNAME}" ]; then
  echo "You must set values for env vars AUTHN_USERNAME and AUTHN_PASSWORD."
  exit -1
fi

main() {
  oc login -u $CYBERARK_NAMESPACE_ADMIN
  clean_master
  if [[ "$1" == "clean" ]]; then
    exit 0
  fi

  label_node
  start_master
  MASTER_POD_NAME=$(oc get pods -n $CYBERARK_NAMESPACE_NAME | grep dap-service-node | grep Running | awk '{print $1}')
  init_cluster_authn
  enable_authn_on_master
  initialize_verify_k8s_api_secrets
  create_configmaps
  install_conjur_client
}

########################
clean_master() {
  oc delete -f dap-cm-manifest.yaml -n $CYBERARK_NAMESPACE_NAME --ignore-not-found
  oc delete -f master-deployment-manifest.yaml -n $CYBERARK_NAMESPACE_NAME --ignore-not-found
  oc delete -f conjur-cli-deployment-manifest.yaml -n $CYBERARK_NAMESPACE_NAME --ignore-not-found
  rm -f dap-cm-manifest.yaml master-deployment-manifest.yaml master-authenticator-policy.yaml master-secrets-policy.yaml conjur-cli-deployment-manifest.yaml jwt-authn-policy.yaml
}

########################
label_node() {
  echo "Labeling node for master..."
  # list worker nodes, get name of first one, label it as the master host
  first_worker="$(oc get nodes | grep worker | cut -d " " -f 1 | head -n 1)"
  oc label nodes $first_worker $DAP_MASTER_NODE_LABEL=true
}

########################
start_master() {
  echo "Starting and configuring primary..."
  oc create route passthrough --service=dap-service-node --port=https -n $CYBERARK_NAMESPACE_NAME
  conjur_follower_route=$(oc get routes | grep conjur-follower | awk '{ print $2 }')
  FOLLOWER_ALTNAME="$FOLLOWER_ALTNAMES,$conjur_follower_route"

  cat ./templates/master-deployment-manifest.template.yaml 			\
  | sed -e "s#{{ CONJUR_APPLIANCE_IMAGE }}#$REGISTRY_APPLIANCE_IMAGE#g" 	\
  | sed -e "s#{{ DAP_MASTER_NODE_LABEL }}#$DAP_MASTER_NODE_LABEL#g" 		\
  > ./master-deployment-manifest.yaml
  oc apply -f ./master-deployment-manifest.yaml -n $CYBERARK_NAMESPACE_NAME

  MASTER_POD_NAME=""				# variable used globally
  while [[ "$MASTER_POD_NAME" == "" ]]; do	# wait till pod is running
    echo -n "."
    sleep 3
    MASTER_POD_NAME=$(oc get pods -n $CYBERARK_NAMESPACE_NAME | grep dap-service-node | grep Running | awk '{print $1}')
  done
  echo

  oc exec -it $MASTER_POD_NAME -n $CYBERARK_NAMESPACE_NAME -- \
	evoke configure master				\
		-h $CONJUR_FOLLOWER_SERVICE_NAME	\
		-p $DAP_ADMIN_PASSWORD			\
		--accept-eula				\
		$CONJUR_ACCOUNT

  wait_till_node_is_responsive
}

########################
install_conjur_client() {
  echo "Install conjur cli ... "
  cat ./templates/conjur-cli.template.yaml \
  | sed -e "s#{{ CYBERARK_NAMESPACE_NAME }}#$CYBERARK_NAMESPACE_NAME#g" 	\
  | sed -e "s#{{ CONJUR_ACCOUNT }}#$CONJUR_ACCOUNT#g" 		\
  > ./conjur-cli-deployment-manifest.yaml
  oc apply -f ./conjur-cli-deployment-manifest.yaml -n $CYBERARK_NAMESPACE_NAME

  CLI_POD_NAME=""				
  while [[ "$CLI_POD_NAME" == "" ]]; do	# wait till pod is running
    echo -n "."
    sleep 3
    CLI_POD_NAME=$(oc get pods -n $CYBERARK_NAMESPACE_NAME | grep conjur-cli | grep Running | awk '{print $1}')
  done
  echo
}

########################
init_cluster_authn() {
  echo "Initializing jwt authentication..."
  cat ./templates/jwt-authn-policy.template.yaml		\
    | sed -e "s#{{ CLUSTER_AUTHN_ID }}#$CLUSTER_AUTHN_ID#g" 		\
    | sed -e "s#{{ CYBERARK_NAMESPACE_NAME }}#$CYBERARK_NAMESPACE_NAME#g" \
    > jwt-authn-policy.yaml
  ../load_policy.sh root ./jwt-authn-policy.yaml
}

########################
enable_authn_on_master() {
  echo "Enabling(allowlist) authentication..."
  oc exec $MASTER_POD_NAME -n $CYBERARK_NAMESPACE_NAME --		\
	evoke variable set CONJUR_AUTHENTICATORS authn-jwt/$CLUSTER_AUTHN_ID

  oc exec $MASTER_POD_NAME -n $CYBERARK_NAMESPACE_NAME --		\
	chpst -u conjur conjur-plugin-service possum 			\
        rake authn_k8s:ca_init["conjur/authn-jwt/$CLUSTER_AUTHN_ID"]

  wait_till_node_is_responsive
}

########################
initialize_verify_k8s_api_secrets() {
  echo "Initializing cluster API URL & credentials..."

  echo "Adding JWKS json to variable public-keys ..."
  JWKS_JSON="$(oc get --raw $(kubectl get --raw /.well-known/openid-configuration | jq -r '.jwks_uri'))"
  ../get_set.sh set \
     conjur/authn-jwt/$CLUSTER_AUTHN_ID/public-keys \
     $JWKS_JSON

  echo "Adding JWT issuer json to variable issuer ..."
  ISSUER=$(kubectl get --raw /.well-known/openid-configuration | jq -r '.issuer')
  ../get_set.sh set \
     conjur/authn-jwt/$CLUSTER_AUTHN_ID/issuer \
     $ISSUER

  echo "Adding variable token-app-property ..."
  ../get_set.sh set \
     conjur/authn-jwt/$CLUSTER_AUTHN_ID/token-app-property "sub"

  echo "Adding variable identity-path ..."
  ../get_set.sh set \
     conjur/authn-jwt/$CLUSTER_AUTHN_ID/identity-path "app-path"
  
  echo "Adding variable audience ..."
  ../get_set.sh set \
     conjur/authn-jwt/$CLUSTER_AUTHN_ID/audience "https://dap-service-node.cyberlab.svc.cluster.local"

  echo
  echo
  echo "Validating K8s API values." 
  echo
  echo "Get k8s cert..."
  ISSUER="$(../get_set.sh get conjur/authn-jwt/$CLUSTER_AUTHN_ID/issuer)"
  echo "issuer : $ISSUER"
  echo
  echo "Get DAP service account token..."
  TOKEN=$(../get_set.sh get conjur/authn-jwt/$CLUSTER_AUTHN_ID/public-keys)
  echo
  echo "keys got: " $TOKEN
  echo
  echo "Get Audience..."
  AUD=$(../get_set.sh get conjur/authn-jwt/$CLUSTER_AUTHN_ID/audience)
  echo
  echo "aud: $AUD"
}

########################
create_configmaps() {
  echo "Creating config map..."
  cat ./templates/dap-config-map-manifest.template.yaml 			\
    | sed -e "s#{{ CONJUR_ACCOUNT }}#$CONJUR_ACCOUNT#g" 				\
    | sed -e "s#{{ CONJUR_MASTER_HOSTNAME }}#$CONJUR_MASTER_HOSTNAME#g" 	\
    | sed -e "s#{{ CYBERARK_NAMESPACE_NAME }}#$CYBERARK_NAMESPACE_NAME#g"	\
    | sed -e "s#{{ CLUSTER_AUTHN_ID }}#$CLUSTER_AUTHN_ID#g" 			\
    > ./dap-cm-manifest.yaml

  # append entries for master & follower certs
  echo "  CONJUR_MASTER_CERTIFICATE: |" >> dap-cm-manifest.yaml
  ../get_cert_REST.sh $CONJUR_MASTER_HOSTNAME $CONJUR_MASTER_PORT	\
    | awk '{ print "    " $0 }'						\
    >> dap-cm-manifest.yaml

  echo "  CONJUR_FOLLOWER_CERTIFICATE: |" >> dap-cm-manifest.yaml
  ../get_cert_REST.sh $CONJUR_MASTER_HOSTNAME $CONJUR_MASTER_PORT	\
    | awk '{ print "    " $0 }'						\
    >> dap-cm-manifest.yaml

  oc apply -f ./dap-cm-manifest.yaml -n $CYBERARK_NAMESPACE_NAME
}

############################
wait_till_node_is_responsive() {
  set +e
  node_is_healthy=""
  while [[ "$node_is_healthy" == "" ]]; do
    sleep 2
    node_is_healthy=$(curl -sk $CONJUR_APPLIANCE_URL/health | grep "ok" | tail -1 | grep "true")
  done
  set -e
}

main "$@"
