#Prerequesites#
jina2
boto3

awscli should be configured with the access key id and secret access key
and default region, or corresponding config files
(~/.aws/config, ~/.aws/credentials) should be manually created

#Overview#

Creates an AWS environment with the following characteristics.

One VPC with 2 subnets, one with IP addresses in the 10.0.0.* range and
one with IP addresses in the 10.0.1.* range.

The 10.0.0.* range, hereafer called the "public subnet" routes to an internet
gateway and has public ip addresses associated. It can connect to itself,
the internet and the 10.0.1.* subnet and can receive connections from the
internet on ports 22, 80 and 8000-8999.

The 10.0.1.* range can receive connections from itself and the public subnet but
not from the internet.  It can open connections to itself and the public subnet
but has not route to internet addresses.

All machines have one network interface in the public subnet and one in the
private subnet.  The public network interface is associated with one public
IP address and one 10.0.0.* IP address.

The pivate interface will be associated with an IP address in the 10.0.1.*
subnet.  The 2 private IP addresses for one ec2 instance will have the same
last octet.  For example, 10.0.0.101 and 10.0.1.101

All machines are launched in the same placement group.