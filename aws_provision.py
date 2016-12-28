#
# Copyright (c) 2015-2016 Pivotal Software, Inc. All Rights Reserved.
#
# note: this is python3!
import boto3
import botocore.exceptions
import jinja2
import json
import os
import os.path
import sys
import threading
import time

def renderTemplate(directory, templateFile, context):
    env = jinja2.Environment(loader=jinja2.FileSystemLoader(directory))
    env.trim_blocks = True
    env.lstrip_blocks = True
    outputFile = templateFile[:-4]
    template = env.get_template(templateFile)
    with open(os.path.join(directory,outputFile), 'w') as outf:
        template.stream(context).dump(outf)
 
       
def deployCFStack( cloudformation, stackName, stackDef, deployFailedEvent):
    try:
        cloudformation.create_stack(StackName = stackName, TemplateBody = stackDef)
    except botocore.exceptions.ClientError as x:
        print('cloudformation deploy failed with message: {0}'.format(x.response['Error']['Message']))
        deployFailedEvent.set()

def updateCFStack( cloudformation, stackName, stackDef, deployFailedEvent):
    try:
        cloudformation.update_stack(StackName = stackName, TemplateBody = stackDef)
    except botocore.exceptions.ClientError as x:
        print('cloudformation deploy failed with message: {0}'.format(x.response['Error']['Message']))
        deployFailedEvent.set()

   
def printStackEvent(event):
    print('{0} {1} {2} {3}'.format(event['Timestamp'],event['ResourceType'],event['LogicalResourceId'],event['ResourceStatus']))

def monitorCFStack(boto3client, stackName, failedEvent, NotFoundOK = False):
    lastSeenEventId = None
    stackStatus = None #CREATE_IN_PROGRESS | CREATE_FAILED | CREATE COMPLETE
    
    time.sleep(5)
    if failedEvent.is_set():
        return False
    
    while True:
        # loop over all events, possibly using multiple calls, don't
        # don't print the ones that have already been seen
        nextToken = None
        eventList = [] #will be used to reverse the order of returned events
        eventListFilled = False
        try: 
            describeEventsResponse = cf.describe_stack_events(StackName = context['EnvironmentName'])
        except botocore.exceptions.ClientError as x:
            if NotFoundOK and x.response['Error']['Message'].endswith('does not exist'):
                print('stack does not exist - continuing')
                return True
            else:
                sys.exit('boto3 describe_stack_events api failed with message: {0}'.format( x.response['Error']['Message']))
            
        if 'NextToken' in describeEventsResponse:
            nextToken = describeEventsResponse['NextToken']
        
        for event in describeEventsResponse['StackEvents']:
            if lastSeenEventId is not None and event['EventId'] == lastSeenEventId:
                eventListFilled = True
                break
            
            eventList.insert(0,event)
                                                
        while not eventListFilled and nextToken is not None:
            try:
                describeEventsResponse = cf.describe_stack_events(StackName = context['EnvironmentName'], NextToken = nextToken)
            except botocore.exceptions.ClientError as x:
                if NotFoundOK and x.response['Error']['Message'].endswith('does not exist'):
                    print('stack does not exist - continuing')
                    return True
                else:
                    sys.exit('boto3 describe_stack_events api failed with message: {0}'.format( x.response['Error']['Message']))

            if 'NextToken' in describeEventsResponse:
                nextToken = describeEventsResponse['NextToken']
                            
            for event in describeEventsResponse['StackEvents']:
                if lastSeenEventId is not None and event['EventId'] == lastSeenEventId:
                    eventListFilled = True
                    break
                
                eventList.insert(0,event)

        # now eventList has all unseen events in chrono order
        # this can be empty if no new events have occurred since the last time they were checked
        if len(eventList) > 0:
            lastSeenEventId = eventList[-1]['EventId']
            for event in eventList:
                printStackEvent(event)
                if event['ResourceType'] == 'AWS::CloudFormation::Stack':
                    stackStatus = event['ResourceStatus']
            
        if stackStatus is not None and not stackStatus.endswith('_IN_PROGRESS'):
            break
        
        if failedEvent.is_set():
            return False
        
        time.sleep(5)
    
    if stackStatus.endswith('COMPLETE'):
        return True
    else:
        return False
    
    
if __name__ == '__main__':
    assert sys.version_info >= (3,0)

    #read the environment file 
    env = jinja2.Environment(loader=jinja2.FileSystemLoader('.'))
    with open('env.json', 'r') as contextFile:
        context = json.load(contextFile)

    if os.path.exists('storage.json'):
        with open('storage.json','r') as f:
            storageTable = json.load(f)
    
        for server in context['Servers']:        
            for blockDevice in server['BlockDevices']:
                if blockDevice['DeviceType'] == 'EBS':
                    blockDevice['EBSVolumeId'] = storageTable[server['Name']][blockDevice['Device']]
        
    here = os.path.dirname(sys.argv[0])
    if len(here) == 0:
        here = '.'

    # render the cloud formation template
    renderTemplate(here,'cloudformation.json.tpl', context)
    print('cloudformation.json rendered')
    
    
    # set up boto3 clients for ec2 and cloudformation
    ec2 = boto3.client('ec2',
                       region_name=context['RegionName'])
 
    
    cf = boto3.client('cloudformation',
                       region_name=context['RegionName'])

    stacks = cf.list_stacks()
    # TODO - currently not handling paginated results from this API!
    
    stackSummary = None
    stackName = context['EnvironmentName']
    for stack in stacks['StackSummaries']:
        if stack['StackName'] == stackName:
            status = stack['StackStatus']
            if status == 'DELETE_COMPLETE':
                continue
            
            if status.endswith('IN_PROGRESS'):
                sys.exit('{0} stack is currently being modified ({1})- please try later'.format(stackName, status))

            print('{0} stack current status is {1}'.format(stackName, status))
            stackSummary = stack
            break
        
    with open('cloudformation.json', 'r') as cfFile:
        stackDef = cfFile.read()

    #deploy the new stack or update the existing one
    if stackSummary is None:
        print('deploying cloudformation stack ... this could take a while')    
        tgt = deployCFStack
    
    else:
        print('updating cloudformation stack ... this could take a while')    
        tgt = updateCFStack        
        
    deployFailedEvent = threading.Event()
    deployThread = threading.Thread(target = tgt, args=(cf,context['EnvironmentName'],stackDef, deployFailedEvent))
    deployThread.start()
    
    stackStatus = monitorCFStack(cf, context['EnvironmentName'], deployFailedEvent)
    if not stackStatus:
        sys.exit('Exiting - Cloud Formation Stack Create or Update Failed')
    else:
        print('stack provisioned successfully')
            
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
                    shortName = tag['Value'][len(context['EnvironmentName'] + 'Server'):]
                    ipTable[shortName] = instance['PublicIpAddress']
                    break

    with open('runtime.json', 'w') as runtimeFile:
        json.dump(ipTable, runtimeFile, indent = 3)
        
    print('runtime information written to "runtime.json"')
    
