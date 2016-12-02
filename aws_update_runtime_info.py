#
# Copyright (c) 2015-2016 Pivotal Software, Inc. All Rights Reserved.
#
# note: this is python3!
import boto3
import botocore.exceptions
import json
import os
import os.path
import sys
import threading
import time

    
if __name__ == '__main__':
    assert sys.version_info >= (3,0)

    #read the environment file 
    with open('env.json', 'r') as contextFile:
        context = json.load(contextFile)
    
    here = os.path.dirname(sys.argv[0])
    if len(here) == 0:
        here = '.'

    # set up boto2 clients for ec2 and cloudformation
    ec2 = boto3.client('ec2',
                       region_name=context['RegionName'])
             
    # only returns running instances - its important to wait for everything
    # to be running or it could be skipped
    result = ec2.describe_instances( Filters=[
        { 'Name':'tag:Environment', 'Values': [context['EnvironmentName']]},
        { 'Name':'instance-state-name', 'Values': ['running']}
        ])
    
    # create a lookup table for public ip addresses
    ipTable = dict()
    for reservation in result['Reservations']:
        for instance in reservation['Instances']:
            for tag in instance['Tags']:
                if tag['Key'] == 'Name':
                    ipTable[tag['Value']] = instance['PublicIpAddress']
                    break

    with open('runtime.json', 'w') as runtimeFile:
        json.dump(ipTable, runtimeFile, indent = 3)
        
    print('runtime information written to "runtime.json"')
    
