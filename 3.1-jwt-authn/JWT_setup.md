
###
* https://docs.cyberark.com/Product-Doc/OnlineHelp/AAM-DAP/Latest/en/Content/Integrations/k8s-ocp/k8s-jwt-authn.htm?tocpath=Integrations%7COpenShift%252FKubernetes%7CAdmin%253A%C2%A0Set%20up%20the%20OpenShift%252FKubernetes%20integration%7CSet%20up%20authentication%7CJWT%20Authenticator%20for%20Kubernetes%20(JWT-based)%7C_____0

```shell
# k8s JWT info

$ kubectl get --raw /.well-known/openid-configuration | jq -r '.jwks_uri'
https://api-int.cluster-mk4tk.mk4tk.sandbox1210.opentlc.com:6443/openid/v1/jwks

$ kubectl get --raw $(kubectl get --raw /.well-known/openid-configuration | jq -r '.jwks_uri') > jwks.json

$ kubectl get --raw /.well-known/openid-configuration | jq -r '.issuer'
https://kubernetes.default.svc


```
