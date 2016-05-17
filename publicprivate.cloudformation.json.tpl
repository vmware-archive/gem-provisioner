{ "AWSTemplateFormatVersion": "2010-09-09",
  "Resources": {
    "{{ EnvironmentName }}PlacementGroup": {
      "Type" : "AWS::EC2::PlacementGroup",
      "Properties" : {}
    },
    "{{ EnvironmentName }}VPC": {
      "Type": "AWS::EC2::VPC",
      "Properties": {
        "CidrBlock": "10.0.0.0/24",
        "InstanceTenancy": "default",
        "EnableDnsSupport": "true",
        "EnableDnsHostnames": "true",
        "Tags": [
          {
            "Key": "Name",
            "Value": "{{ EnvironmentName }}VPC"
          }
        ]
      }
    },
    "{{ EnvironmentName }}SubnetPublic": {
      "Type": "AWS::EC2::Subnet",
      "Properties": {
        "CidrBlock": "10.0.0.0/24",
        "AvailabilityZone": "{{ AvailabilityZone }}",
        "VpcId": {
          "Ref": "{{ EnvironmentName }}VPC"
        },
        "Tags": [
          {
            "Key": "Name",
            "Value": "{{ EnvironmentName }}SubnetPublic"
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
          }
        ]
      }
    },
    "{{ EnvironmentName }}InternetGatewayAttachment": {
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
    "{{ EnvironmentName }}DHCPOptions": {
      "Type": "AWS::EC2::DHCPOptions",
      "Properties": {
        "DomainName": "ec2.internal",
        "DomainNameServers": [
          "AmazonProvidedDNS"
        ]
      },
      "Tags": [
        {
          "Key": "Name",
          "Value": "{{ EnvironmentName }}InternetGateway"
        }
      ]
  },
    "{{ EnvironmentName }}DHCPOptionsAssoc": {
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
    "{{ EnvironmentName }}RouteTableDefault": {
      "Type": "AWS::EC2::RouteTable",
      "Properties": {
        "VpcId": {
          "Ref": "{{ EnvironmentName }}VPC"
        },
        "Tags": [
          {
            "Key": "Name",
            "Value": "{{ EnvironmentName }}RouteTableDefault"
          }
        ]
      }
    },
    "{{ EnvironmentName }}RouteTablePublic": {
      "Type": "AWS::EC2::RouteTable",
      "Properties": {
        "VpcId": {
          "Ref": "{{ EnvironmentName }}VPC"
        },
        "Tags": [
          {
            "Key": "Name",
            "Value": "{{ EnvironmentName }}RouteTablePublic"
          }
        ]
      }
    },
    "{{ EnvironmentName }}RouteTablePublicSubnetAssoc": {
      "Type": "AWS::EC2::SubnetRouteTableAssociation",
      "Properties": {
        "RouteTableId": {
          "Ref": "{{ EnvironmentName }}RouteTablePublic"
        },
        "SubnetId": {
          "Ref": "{{ EnvironmentName }}SubnetPublic"
        }
      }
    },
    "{{ EnvironmentName }}Route1": {
      "Type": "AWS::EC2::Route",
      "Properties": {
        "DestinationCidrBlock": "0.0.0.0/0",
        "RouteTableId": {
          "Ref": "{{ EnvironmentName }}RouteTablePublic"
        },
        "GatewayId": {
          "Ref": "{{ EnvironmentName }}InternetGateway"
        }
      },
      "DependsOn" : "{{ EnvironmentName }}RouteTablePublicSubnetAssoc"
    },
    "{{ EnvironmentName }}SecurityGroup": {
      "Type" : "AWS::EC2::SecurityGroup",
      "Properties" : {
         "GroupDescription" : "{{ EnvironmentName }} Security Group",
         "SecurityGroupIngress" : [
            {
               "CidrIp" : "0.0.0.0/0",
               "IpProtocol" : "tcp",
               "FromPort": 22,
               "ToPort" : 22
            },
            {
               "CidrIp" : "0.0.0.0/0",
               "IpProtocol" : "tcp",
               "FromPort": 80,
               "ToPort" : 80
            },
            {
               "CidrIp" : "0.0.0.0/0",
               "IpProtocol" : "tcp",
               "FromPort": 10000,
               "ToPort" : 19999
            }
        ],
         "Tags" :  [
            {
              "Key": "Name",
              "Value": "{{ EnvironmentName }}SecurityGroup"
            }
         ],
         "VpcId" : {"Ref": "{{ EnvironmentName }}VPC"}
      }
    },
    {% for Server in Servers %}
    "{{ EnvironmentName }}Server{{ Server.Name }}": {
      "Type": "AWS::EC2::Instance",
      "Properties": {
        "DisableApiTermination": "false",
        {% if Server.InstanceInitiatedShutdownBehavior is defined %}
        "InstanceInitiatedShutdownBehavior": "{{ Server.InstanceInitiatedShutdownBehavior }}",
        {% endif %}
        {% if Server.EbsOptimized is defined %}
        "EbsOptimized": "{{ Server.EbsOptimized }}",
        {% endif %}
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
            "AssociatePublicIpAddress": "true",
            "GroupSet": [
              {"Ref": "{{ EnvironmentName }}SecurityGroup"}
            ]
          }
        ],
      "BlockDeviceMappings" : [
      {% for Disk in Server.Disks %}
        {% if not loop.first %},{% endif %}
         {
            {%if Disk.EBS %}
            "DeviceName" : "{{ Disk.DeviceName }}",
            "Ebs" : {
              "VolumeSize" : "{{ Disk.Size }}",
              "VolumeType" : "{{ Disk.VolumeType }}"
            }
            {% else %}
            "DeviceName" : "{{ Disk.DeviceName }}",
            "VirtualName" : "{{ Disk.VirtualName }}"
            {% endif %}
         }
      {% endfor %}
      ] ,
      "Tags" : [
        {
          "Key" : "Name",
          "Value" : "{{ EnvironmentName }}Server{{ Server.Name }}"
        },
        {
          "Key" : "Environment",
          "Value" : "{{ EnvironmentName }}"
        }
      ]
      },
      "DependsOn" : "{{ EnvironmentName }}InternetGatewayAttachment"
    }
    {% if not loop.last %},{% endif %}
  {% endfor %}
  },
  "Description": "{{EnvironmentName}} environment"
}
