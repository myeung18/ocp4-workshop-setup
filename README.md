
```shell
oc exec -it os-climate-app-team1-848f9b5484-7k6b2 -n user1 -- bash -c "python secretless.py"

Defaulting container name to os-climate-app-team1.
Use 'oc describe pod/os-climate-app-team1-848f9b5484-7k6b2 -n user1' to see all of the containers in this pod.
{'Name': 'book2021', 'CreationDate': datetime.datetime(2021, 10, 17, 21, 57, 39, tzinfo=tzlocal())}
{'Name': 'books', 'CreationDate': datetime.datetime(2021, 10, 17, 22, 26, 52, tzinfo=tzlocal())}
{'Name': 'bucket', 'CreationDate': datetime.datetime(2017, 2, 19, 16, 47, 24, tzinfo=tzlocal())}
{'Name': 'test-os', 'CreationDate': datetime.datetime(2021, 10, 16, 18, 55, 19, tzinfo=tzlocal())}
```