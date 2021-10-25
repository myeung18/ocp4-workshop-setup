# Secret Management with CyberArk Conjur and Secretless Broker

## Prequisites
* Linux Fedora (not tested in other environment)
* Openshift 4.x 
* keyring

## Installation

### Customize `dap-service.config` with your environment information
```shell script
#Preapre an Openshift cluster server and add the location of the config in `dap-service.config`
#e.g.
export KUBECONFIG=<~/.kube/config>   
#Add the Openshift cluster domain
export CLUSTER_DOMAIN=cluster-436d.436d.sandbox1159.opentlc.com

#Prepare one or two AWS users, and add the credentials to the `dap-service.config` 
export AWS_ACCESS_KEY=<acess_key1>
export AWS_SECRET_KEY=<secret_key1>
export AWS_ACCESS_KEY_2=<acess_key2>
export AWS_SECRET_KEY_2=<secret_key2>

#Run the setup script to install the Conjur Enterprise, POC applications with Secretless Brokers
$./SETUP-POC.sh

#Three projects are created as shown below:
#the project:`cyberlab` has the Conjur server and the Conjur cli tool installed
$oc get po -n cyberlab  
NAME                                READY   STATUS    RESTARTS   AGE
conjur-cli-5969fcdcf5-dg2b5         1/1     Running   0          5m41s
dap-service-node-7fc7967665-prx2g   1/1     Running   0          8m26s

#project `user1` has the POC Jupyter Notebook one installed
$oc get po -n user1   
NAME                                    READY   STATUS    RESTARTS   AGE
os-climate-app-team1-6cd566f8b6-5x5jf   2/2     Running   0          6m22s

#project `user2` has the POC Jupyter Notebook one installed
$oc get po -n user2
NAME                                    READY   STATUS    RESTARTS   AGE
os-climate-app-team2-84cbb66994-cnfjf   2/2     Running   0          6m23s
```
### Launch the Conjur UI with its route from the project `cyberlab`
username: `admin`; password is the one you input while the `./SETUP-POC.sh` was running. You can also retrieve with `keyring get conjur adminpwd` after the setup is done.

<img_login>
### Conjur UI, we can view all the policies which define the authn and authz of this POC

<img_admin_ui>

### Launch Jupyter Notebook application with the routes in the project `user1` or `user2`

To login, you can find the jupyter token in POC application container log in the corresponding pod in those application projects. e.g. `os-climate-app-team1`, put the token in the `password or token` field and click `Log in`
<jupyter login>

select `Secretless Demo with Conjur.ipynb` and run the program

You can see the notebooks is requesting AWS login from the secretless broker and eventually it retrieved the a list of buckets from one of the AWS user you input
  in the beginning.
  
<jupyter no>

  

```shell
oc exec -it os-climate-app-team1-848f9b5484-7k6b2 -n user1 -- bash -c "python secretless.py"

Defaulting container name to os-climate-app-team1.
Use 'oc describe pod/os-climate-app-team1-848f9b5484-7k6b2 -n user1' to see all of the containers in this pod.
{'Name': 'book2021', 'CreationDate': datetime.datetime(2021, 10, 17, 21, 57, 39, tzinfo=tzlocal())}
{'Name': 'books', 'CreationDate': datetime.datetime(2021, 10, 17, 22, 26, 52, tzinfo=tzlocal())}
{'Name': 'bucket', 'CreationDate': datetime.datetime(2017, 2, 19, 16, 47, 24, tzinfo=tzlocal())}
{'Name': 'test-os', 'CreationDate': datetime.datetime(2021, 10, 16, 18, 55, 19, tzinfo=tzlocal())}
```


https://github.com/cyberark/conjur/blob/master/app/domain/authentication/authn_k8s/TROUBLESHOOTING.md
