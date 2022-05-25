
###
* https://docs.cyberark.com/Product-Doc/OnlineHelp/AAM-DAP/Latest/en/Content/Integrations/k8s-ocp/k8s-jwt-authn.htm?tocpath=Integrations%7COpenShift%252FKubernetes%7CAdmin%253A%C2%A0Set%20up%20the%20OpenShift%252FKubernetes%20integration%7CSet%20up%20authentication%7CJWT%20Authenticator%20for%20Kubernetes%20(JWT-based)%7C_____0

```shell
# k8s JWT info

$ kubectl get --raw /.well-known/openid-configuration | jq -r '.jwks_uri'
https://api-int.cluster-mk4tk.mk4tk.sandbox1210.opentlc.com:6443/openid/v1/jwks

$ kubectl get --raw $(kubectl get --raw /.well-known/openid-configuration | jq -r '.jwks_uri') > jwks.json

$ kubectl get --raw /.well-known/openid-configuration | jq -r '.issuer'
https://kubernetes.default.svc


conjur --insecure variable set -i conjur/authn-jwt/dev-cluster/public-keys -v "{\"type\":\"jwks\", \"value\":$(cat jwks.json)}"

conjur --insecure variable set -i conjur/authn-jwt/dev-cluster/issuer -v https://kubernetes.default.svc

conjur --insecure variable set -i conjur/authn-jwt/dev-cluster/token-app-property -v "sub"

conjur --insecure variable set -i conjur/authn-jwt/dev-cluster/identity-path -v app-path

conjur --insecure variable set -i conjur/authn-jwt/dev-cluster/audience -v "https://dap-service-node.cyberlab.svc.cluster.local"

```
