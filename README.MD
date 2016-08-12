### Overview ###
This project has 2 functions.
* _aws_provision.py_ : Provision and configure AWS resources for a GemFire cluster.  This includes
ec2 instances, a VPC, Security Groups and multiple other resources.
* _setup.py_ : Install a GemFire cluster onto a set of hosts in a way that allows the
cluster to be managed using the _gemfire-manager_ project: https://github.com/Pivotal-Data-Engineering/gemfire-manager.

There is a clean separation between the 2 functions so that the second function,
cluster setup, can be used with any hosts, not just those provisioned using this
project.  It is anticipated that additional provisioners may be added for
other platforms.

Both functions drive off of a single configuration file: _env.json_
The _env.json_ included with the project provisions 1 locator, 3 cache servers
and 1 ETL server, all on r3.large instances. 


###Prerequesites###
* The local machine requires python3 to be installed and the following python
packages
 * jina2 
 * boto3
 * awscli
* You will need to register a key pair with AWS and you will need the corresponding
.pem file on your local machine.
* You will need to put your AWS AccessKeyId and SecretAccessKey in the _env.json_
configuration file.  You can either use your master key or create an IAM user.
If you create an IAM user then you will need to attach a user policy that grants
access to all EC2 operations.  The following policy definition can be used.
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
}
    ```
 
###_aws_provision.py_###

usage: `python3 aws_provision.py`

_aws_provision_.py generates a Cloud Formation template based on the main
configuration file, _env.json_ and a jinja2 template: _cloudformation.json.tpl_.
All of the details of how the servers are provisioned on AWS can be modified
by editing _cloudformation.json.tpl_.

The script reports status.  You can also follow the status of provisioning the
stack in the AWS Cloud Formation control panel.

#### notes ####
* To add or remove servers, simply edit _env.json_ and re-run _aws_provision.py_.
The script leverages Cloud Formation's ability to update a stack.
* When the provision operation is complete, a file named _runtime.json_ will be
written into the current directory.  This file is a map of logical server names
to IP addresses.  It is used by _setup.py_ to complete the setup.

###setup.py###
_setup.py_ installs all of the software and configuration required to run a
GemFire cluster onto the servers specified in _runtime.json_.  Each step of
the installation is controlled by the scripts and configurations is a subdirectory
of this project.  For example, installing the GemFire cluster control scripts
and configurations is controlled by the contents of the _InstallGemFireCluster_
directory.

_setup.py_ proceeds as follows:
* for each Server in _env.json_
  * for each Installation
    * render all templates (files ending in .tpl) in the corresponding directory
    * upload a copy of the whole directory, including all rendered templates,
    to the /tmp/setup directory on the target server
    * run /tmp/setup/setup.py on the target server

####notes####
* The GemFire cluster definition is specificied by the file: _InstallGemFireCluster/cluster.json.tpl_
* After installation is complete, the file _InstallGemFireCluster/cluster.json_
can be used with the _gemfire-manager_ project (https://github.com/Pivotal-Data-Engineering/gemfire-manager)
to control the installed cluster.  To start the cluster you just need to:
 1. download a copy of the _gemfire_manager_ project to your local machine.
 2. copy _InstallGemFireCluster/cluster.json_ to the _gemfire_manager_ directory.
 3. in the _gemfire_manager_ directory, run `python gf.py start`

###Walk Through###
As delivered, this project creates a GemFire cluster consisting of 1 locator
and 3 cache servers, as well as 1 ETL server.  All servers are r3.large
instances.

__You may need to request an account limit increase to run this__.

1. Create a key pair within the ec2 console that will be used to access the
servers you will provision.  Its also OK to use an existing key pair. In either
case, be sure you have the corresponding .pem file on your local machine.

2. Obtain the AWSAccessKeyId and AWSSecretAccessKey that will be used to provision
the servers.  If you do not use your master account, be sure that the IAM user
that you use has sufficient privileges (see prerequisites above).

3. Download a copy of the _gemfire-manager_ project from github using the link
provided above.  

4. Edit "env.json" to specify the appropriate values for the following keys:

    ```
        "EnvironmentName" : "antifraud",
        "RegionName" : "us-east-1",
        "AvailabilityZone" : "us-east-1a",
        "KeyPair" : "antifraud-keypair",
        "AWSAccessKeyId": "AKIATHISISBOGUSPS",
        "AWSSecretAccessKey" : "WCc0mpl3tlyM4d3Up",
        "SSHKeyPath" : "/users/rmay/Downloads/antifraud-keypair.pem",
    ```

    The "EnvironmentName" can be anything. It is just a name which acts as
    a prefix for all of the cloud formation entities as well as the name of the
    stack that is created.

5. Provision the cluster machines:
    ```
    python3 aws_provision.py 
    ```

6. Install software and configure the cluster machines:

    ```
    python3 setup.py
    ```

7. Start the cluster. Copy _InstallGemFireCluster/cluster.json_ to the _gemfire_manager_ folder
 containing the _gf.py_ and the other cluster control scripts.
 ```
 cd <gemfire-manager-location>
 python gf.py start
 ```

  Done!  You now have a fully functional gemfire cluster on AWS.

8. Tear it down.  Use the AWS CloudFormation console to destroy the stack.

### Known Issues ###
* Occasionally, after an the Amazon account has not had recent deployment
activity, deployment will fail because of a spurious "quota exceeded" error.
Assuming there is not a real issue with your account limits, this can
be remedied by re-deploying.
