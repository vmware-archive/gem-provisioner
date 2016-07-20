###Prerequesites###
* jina2
* boto3
* awscli should be configured with the access key id and secret access key
and default region, or corresponding config files
(~/.aws/config, ~/.aws/credentials) should be manually created
* python3

###AWS Notes###
* Creates a Cloud Formation template and deploys it programa
* Launches ec2 instances in a VPC
* Ingress allowed on all ports from within the VPC
* Ingress on ports 22 and 10000-19999 from outside of VPC
* Egress from VPC is unrestricted
* All servers are configured with an ssh key for passwordless ssh

###Walk Through###
As delivered, this project creates a GemFire cluster consisting of 1 locator
and 2 cache servers, as well as 1 ETL server.  All servers are r3.large
instances.

__You may need to request an account limit increase to run this__.

To run this you will need an AWS account, a set of user credentials and a 
The key configuration file is "env.json".

You can either use the access_key_id and secret_access_key for the root account
or you can create an IAM user and a secret access key for that user.  The IAM
user will need to have the following policy attached.

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "ec2:*",
                "cloudformation:*",
                "elasticloudbalancing:*"
            ],
            "Effect": "Allow",
            "Resource": "*"
        }
    ]
}```

You will need a key pair, which can be created in the EC2 console.  You will
need the corresponding ".pem" file on your local machine.

"env.json" is the primary configuration file.  Edit the following keys with
appropriate values for your account.

```
    "EnvironmentName" : "antifraud",
    "RegionName" : "us-east-1",
    "AvailabilityZone" : "us-east-1a",
    "KeyPair" : "antifraud-keypair",
    "AWSAccessKeyId": "AKIATHISISBOGUSPS",
    "AWSSecretAccessKey" : "WCc0mpl3tlyM4d3Up",
    "SSHKeyPath" : "/users/rmay/Downloads/antifraud-keypair.pem",
```

Note that "EnvironmentName" can be anything. It is just a name which acts as
a prefix for all of the cloud formation entities as well as the name of the
stack that is created.

Deploy the cluster:
```
python3 setup.py --delete-existing-stack
```

Start GemFire cluster

```
cd InstallGemFireCluster
python gf.py start
```

To Tear It Down ....
Use the Cloud Formation console to delete the stack.

### Known Issues ###
* Occasionally, after an the Amazon account has not had much deployment
activity, deployment will fail because of a spurious "quota exceeded" error.
This can usually be remedied by re-deploying.
