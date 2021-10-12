CONJUR_NAMESPACE=conjur
 kubectl create namespace "$CONJUR_NAMESPACE"
 DATA_KEY="$(docker run --rm cyberark/conjur data-key generate)"
 HELM_ARGS="--set dataKey=$DATA_KEY \
              --set image.tag=1.11.0 \
              --set image.pullPolicy=IfNotPresent \
              --set ssl.hostname=custom.domainname.com
 helm install \
   -n "$CONJUR_NAMESPACE" \
   $HELM_ARGS \
   conjur-oss \
   https://github.com/cyberark/conjur-oss-helm-chart/releases/download/v2.0.4/conjur-oss-2.0.4.tgz









CONJUR_NAMESPACE=conjur
oc create namespace "$CONJUR_NAMESPACE"
DATA_KEY="$(docker run --rm cyberark/conjur data-key generate)"
HELM_RELEASE=conjur-oss
helm install \
   -n "$CONJUR_NAMESPACE" \
   --set image.repository=registry.connect.redhat.com/cyberark/conjur \
   --set image.tag=latest \
   --set nginx.image.repository=registry.connect.redhat.com/cyberark/conjur-nginx \
   --set nginx.image.tag=latest \
   --set postgres.image.repository=registry.redhat.io/rhscl/postgresql-10-rhel7 \
   --set postgres.image.tag=latest \
   --set openshift.enabled=true \
   --set dataKey="$DATA_KEY" \
   "$HELM_RELEASE" \
   https://github.com/cyberark/conjur-oss-helm-chart/releases/download/v2.0.4/conjur-oss-2.0.4.tgz



--------------------------------------------------------------------------
#!/usr/bin/env bash

APP_NAME=my-app
APP_NAMESPACE=my-app-ns
APP_SERVICE_ACCOUNT_NAME=my-app-sa
SECRETLESS_CONTAINER_NAME=secretless

AUTHENTICATOR_ID="example-service-id"
APP_POLICY_BRANCH="conjur/authn-k8s/${AUTHENTICATOR_ID}/apps"

APP_SECRETS_POLICY_BRANCH="apps/prod-secrets"
APP_SECRETS_READER_LAYER="apps/prod-secrets/secret-users"

CONJUR_ACCOUNT="default"
CONJUR_SERVICE_NAME="conjur-oss"
CONJUR_SERVICE_ACCOUNT_NAME="conjur-oss"
CONJUR_NAMESPACE=conjur
CONJUR_CLUSTERROLE_NAME="conjur-oss-conjur-authenticator"

CONJUR_APPLIANCE_URL="https://${CONJUR_SERVICE_NAME}.${CONJUR_NAMESPACE}.svc.cluster.local"


AUTHENTICATOR_ID
CONFIGURE_CONJUR_MASTER=
CONJUR_ACCOUNT=myConjurAccount
CONJUR_ADMIN_PASSWORD=26phcjenxw6vh2z9dcya3qcpsnp16k907s1e6trykzqg9hmqea2gx
CONJUR_AUTHN_LOGIN_RESOURCE=deployment
CONJUR_NAMESPACE_NAME=conjur
VALIDATOR_ID
VALIDATOR_NAMESPACE_NAME
APP_VALIDATOR_ID
APP_VALIDATOR_NAMESPACE_NAME
CONJUR_OSS_HELM_INSTALLED=true
USE_DOCKER_LOCAL_REGISTRY
DOCKER_REGISTRY_URL
PULL_DOCKER_REGISTRY_URL
DOCKER_REGISTRY_PATH
PULL_DOCKER_REGISTRY_PATH
PLATFORM=openshift
TEST_APP_DATABASE	
TEST_APP_NAMESPACE_NAME	
TEST_APP_LOADBALANCER_SVCS	

oc get route default-route -n openshift-image-registry -o jsonpath="{.spec.host}"

bash-4.4$ conjurctl account create myConjurAccount
Created new account 'myConjurAccount'
Token-Signing Public Key: -----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEApGgGRhVhpPoQxU2TvQWb
GuxExjYBAT092pvZ3O6rAG0TsVcJo54Bh6uRchRCRHXGeseLeDrJWp5MyxxspDoA
Xul6PzIzd5D/bywel3XfXx7XQ4bDs/P7EIath94K+P6p5adiBX1NYS6UUX9SHdrr
YmEdcOzv/KQK6mD8uIU5dHse03Z0Ei9nKWv7oQ4Fj49Q3iLp9ICNHCLojdU3DI7S
DWr9dw+c9+8hC950ilGPS9ZmTKvGJQmoxYtvcUUW8VnJveouER8qQ/7pt15gd8be
f74Cxkn0bH0Qw52hL8yB+xY2dfPpa5xLts6Ni979rdc5MLlkVVf/d5LgPPjBWPLr
fQIDAQAB
-----END PUBLIC KEY-----
API key for admin: 26phcjenxw6vh2z9dcya3qcpsnp16k907s1e6trykzqg9hmqea2gx