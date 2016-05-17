{
  "AWSTemplateFormatVersion": "2010-09-09",
  "Resources": {
    "{{ EnvironmentName }}PlacementGroup": {
      "Type" : "AWS::EC2::PlacementGroup",
      "Properties" : {
        "Tags": [
          {
            "Key": "Name",
            "Value": "{{ EnvironmentName }}PlacementGroup"
          },
          {
            "Key": "Environment",
            "Value": "{{ EnvironmentName }}"
          }
        ]
      }
    },
    "{{ EnvironmentName }}VPC": {
      "Type": "AWS::EC2::VPC",
      "Properties": {
        "CidrBlock": "10.0.0.0/16",
        "InstanceTenancy": "default",
        "EnableDnsSupport": "true",
        "EnableDnsHostnames": "true",
        "Tags": [
          {
            "Key": "Name",
            "Value": "{{ EnvironmentName }}VPC"
          },
          {
            "Key": "Environment",
            "Value": "{{ EnvironmentName }}"
          }
        ]
      }
    },
    "{{ EnvironmentName }}SubnetPublic": {
      "Type": "AWS::EC2::Subnet",
      "Properties": {
        "CidrBlock": "10.0.0.0/24",
        "AvailabilityZone": "us-east-1b",
        "VpcId": {
          "Ref": "{{ EnvironmentName }}VPC"
        },
        "Tags": [
          {
            "Key": "Name",
            "Value": "{{ EnvironmentName }}SubnetPublic"
          },
          {
            "Key": "Environment",
            "Value": "{{ EnvironmentName }}"
          }
        ]
      }
    },
    "{{ EnvironmentName }}InternetGateway": {
      "Type": "AWS::EC2::InternetGateway",
      "Properties": {
        "Tags": [
          {
            "Key": "Name",
            "Value": "{{ EnvironmentName }}InternetGateway"
          },
          {
            "Key": "Environment",
            "Value": "{{ EnvironmentName }}"
          }
        ]
      }
    },
    "{{ EnvironmentName }}DHCPOptions": {
      "Type": "AWS::EC2::DHCPOptions",
      "Properties": {
        "DomainName": "ec2.internal",
        "DomainNameServers": [
          "AmazonProvidedDNS"
        ],
        "Tags": [
          {
            "Key": "Name",
            "Value": "{{ EnvironmentName }}DHCPOptions"
          },
          {
            "Key": "Environment",
            "Value": "{{ EnvironmentName }}"
          }
        ]
      }
    },
    "{{ EnvironmentName }}NetworkAcl": {
      "Type": "AWS::EC2::NetworkAcl",
      "Properties": {
        "VpcId": {
          "Ref": "{{ EnvironmentName }}VPC"
        },
        "Tags": [
          {
            "Key": "Name",
            "Value": "{{ EnvironmentName }}NetworkAcl"
          },
          {
            "Key": "Environment",
            "Value": "{{ EnvironmentName }}"
          }
        ]
      }
    },
    "{{ EnvironmentName }}RouteTable1": {
      "Type": "AWS::EC2::RouteTable",
      "Properties": {
        "VpcId": {
          "Ref": "{{ EnvironmentName }}VPC"
        },
        "Tags": [
          {
            "Key": "Name",
            "Value": "{{ EnvironmentName }}RouteTable1"
          },
          {
            "Key": "Environment",
            "Value": "{{ EnvironmentName }}"
          }
        ]
      }
    },
    "{{ EnvironmentName }}RouteTable2": {
      "Type": "AWS::EC2::RouteTable",
      "Properties": {
        "VpcId": {
          "Ref": "{{ EnvironmentName }}VPC"
        },
        "Tags": [
          {
            "Key": "Name",
            "Value": "{{ EnvironmentName }}RouteTable2"
          },
          {
            "Key": "Environment",
            "Value": "{{ EnvironmentName }}"
          }
        ]
      }
    },
    {% for Server in Servers %}
    {% if not loop.first %}, {% endif %}
    "{{ EnvironmentName }}{{ Server.Name }}": {
      "Type": "AWS::EC2::Instance",
      "Properties": {
        "DisableApiTermination": "false",
        "InstanceInitiatedShutdownBehavior": "terminate",
        "ImageId": "{{ Server.ImageId }}",
        "InstanceType": "{{ Server.InstanceType }}",
        "KeyName": "{{ KeyPair }}",
        "Monitoring": "false",
        "PlacementGroupName": {
          "Ref" : "{{ EnvironmentName }}PlacementGroup"
        },
        "NetworkInterfaces": [
          {
            "DeleteOnTermination": "true",
            "Description": "Primary network interface",
            "DeviceIndex": 0,
            "SubnetId": {
              "Ref": "{{ EnvironmentName }}SubnetPublic"
            },
            "PrivateIpAddresses": [
              {
                "PrivateIpAddress": "10.0.0.{{ Server.ServerNumber }}",
                "Primary": "true"
              }
            ],
            "GroupSet": [
              {
                "Ref": "{{ EnvironmentName }}SecurityGroup"
              }
            ],
            "AssociatePublicIpAddress": "true"
          }
        ],
        "Tags": [
          {
            "Key": "Name",
            "Value": "{{ EnvironmentName }}Server{{ Server.Name }}"
          },
          {
            "Key": "Environment",
            "Value": "{{ EnvironmentName }}"
          }
        ]
      }
    }
    {% endfor %},
    "{{ EnvironmentName }}SecurityGroup": {
      "Type": "AWS::EC2::SecurityGroup",
      "Properties": {
        "GroupDescription": "{{ EnvironmentName }} Security Group",
        "VpcId": {
          "Ref": "{{ EnvironmentName }}VPC"
        },
        "Tags": [
          {
            "Key": "Name",
            "Value": "{{ EnvironmentName }}SecurityGroup"
          },
          {
            "Key": "Environment",
            "Value": "{{ EnvironmentName }}"
          }
        ]
      }
    },
    "acl3": {
      "Type": "AWS::EC2::NetworkAclEntry",
      "Properties": {
        "CidrBlock": "0.0.0.0/0",
        "Egress": "true",
        "Protocol": "-1",
        "RuleAction": "allow",
        "RuleNumber": "100",
        "NetworkAclId": {
          "Ref": "{{ EnvironmentName }}NetworkAcl"
        }
      }
    },
    "acl4": {
      "Type": "AWS::EC2::NetworkAclEntry",
      "Properties": {
        "CidrBlock": "0.0.0.0/0",
        "Protocol": "-1",
        "RuleAction": "allow",
        "RuleNumber": "100",
        "NetworkAclId": {
          "Ref": "{{ EnvironmentName }}NetworkAcl"
        }
      }
    },
    "subnetacl2": {
      "Type": "AWS::EC2::SubnetNetworkAclAssociation",
      "Properties": {
        "NetworkAclId": {
          "Ref": "{{ EnvironmentName }}NetworkAcl"
        },
        "SubnetId": {
          "Ref": "{{ EnvironmentName }}SubnetPublic"
        }
      }
    },
    "gw2": {
      "Type": "AWS::EC2::VPCGatewayAttachment",
      "Properties": {
        "VpcId": {
          "Ref": "{{ EnvironmentName }}VPC"
        },
        "InternetGatewayId": {
          "Ref": "{{ EnvironmentName }}InternetGateway"
        }
      }
    },
    "subnetroute4": {
      "Type": "AWS::EC2::SubnetRouteTableAssociation",
      "Properties": {
        "RouteTableId": {
          "Ref": "{{ EnvironmentName }}RouteTable2"
        },
        "SubnetId": {
          "Ref": "{{ EnvironmentName }}SubnetPublic"
        }
      }
    },
    "route2": {
      "Type": "AWS::EC2::Route",
      "Properties": {
        "DestinationCidrBlock": "0.0.0.0/0",
        "RouteTableId": {
          "Ref": "{{ EnvironmentName }}RouteTable2"
        },
        "GatewayId": {
          "Ref": "{{ EnvironmentName }}InternetGateway"
        }
      },
      "DependsOn": "gw2"
    },
    "dchpassoc2": {
      "Type": "AWS::EC2::VPCDHCPOptionsAssociation",
      "Properties": {
        "VpcId": {
          "Ref": "{{ EnvironmentName }}VPC"
        },
        "DhcpOptionsId": {
          "Ref": "{{ EnvironmentName }}DHCPOptions"
        }
      }
    },
    "ingress1": {
      "Type": "AWS::EC2::SecurityGroupIngress",
      "Properties": {
        "GroupId": {
          "Ref": "{{ EnvironmentName }}SecurityGroup"
        },
        "IpProtocol": "-1",
        "SourceSecurityGroupId": {
          "Ref": "{{ EnvironmentName }}SecurityGroup"
        }
      }
    },
    "ingress2": {
      "Type": "AWS::EC2::SecurityGroupIngress",
      "Properties": {
        "GroupId": {
          "Ref": "{{ EnvironmentName }}SecurityGroup"
        },
        "IpProtocol": "tcp",
        "FromPort": "22",
        "ToPort": "22",
        "CidrIp": "0.0.0.0/0"
      }
    },
    "ingress3": {
      "Type": "AWS::EC2::SecurityGroupIngress",
      "Properties": {
        "GroupId": {
          "Ref": "{{ EnvironmentName }}SecurityGroup"
        },
        "IpProtocol": "tcp",
        "FromPort": "10000",
        "ToPort": "19999",
        "CidrIp": "0.0.0.0/0"
      }
    },
    "egress1": {
      "Type": "AWS::EC2::SecurityGroupEgress",
      "Properties": {
        "GroupId": {
          "Ref": "{{ EnvironmentName }}SecurityGroup"
        },
        "IpProtocol": "-1",
        "CidrIp": "0.0.0.0/0"
      }
    }
  },
  "Description": "{{ EnvironmentName }} stack"
}