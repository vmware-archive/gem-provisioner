# note: this is python3!
import boto3
import jinja2
import json
import os
import os.path
import subprocess
import sys

#args should be a list
def runListQuietly(args):
    p = subprocess.Popen(args, stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
    output = p.communicate()
    if p.returncode != 0:
        raise Exception('"{0}" failed with the following output: {1}'.format(' '.join(list(args)), output[0]))
    
def runQuietly(*args):
    runListQuietly(list(args))
    
def runRemote(sshKeyPath, user, host, *args):
    prefix = ['ssh', '-o','StrictHostKeyChecking=no',
                        '-t',
                        '-i', sshKeyPath,
                        '{0}@{1}'.format(user, host)]
    
    subprocess.check_call(prefix + list(args))
    
    
def runRemoteQuietly(sshKeyPath, user, host, *args):
    prefix = ['ssh', '-o','StrictHostKeyChecking=no',
                        '-t',
                        '-i', sshKeyPath,
                        '{0}@{1}'.format(user, host)]
    
    runListQuietly( prefix + list(args))
    
def renderTemplate(directory, templateFile, context):
    env = jinja2.Environment(loader=jinja2.FileSystemLoader(directory))
    outputFile = templateFile[:-4]
    template = env.get_template(templateFile)
    with open(os.path.join(directory,outputFile), 'w') as outf:
        template.stream(context).dump(outf)
 
    
# def runRemoteQuietly(sshKeyPath, user, host, *args):
#     newargs = ['ssh', '-o', 'StrictHostKeyChecking=no',
#                '-t',
#                '-i', sshKeyPath,
#                user + '@' + host] + list(args)
#     
#     cmd = ' '.join(newargs)
#     
#     p = subprocess.Popen(newargs, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
#     output = p.communicate()
#     if p.returncode != 0:
#         msg = '"' + cmd + '" failed with the following output: \n\t' + output[0]
#         raise Exception(msg)    
    
if __name__ == '__main__':
    with open('env.json', 'r') as contextFile:
        context = json.load(contextFile)
        
    ec2 = boto3.client('ec2',
                       region_name=context['RegionName'],
                       aws_access_key_id = context['AWSAccessKeyId'],
                       aws_secret_access_key = context['AWSSecretAccessKey'])

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
    serverNum = -1
    for server in context['Servers']:
        serverNum += 1
        serverName = context['EnvironmentName'] + 'Server' + server['Name']
        ip = ipTable[serverName]
        installationNum = -1
        for installation in server['Installations']:
            installationNum += 1
            for templateFile in os.listdir(installation['Name']):
                if templateFile.endswith('.tpl'):
                    context['ServerNum'] = serverNum
                    context['InstallationNum'] = installationNum
                    context['Servers'][serverNum]['PublicIpAddress'] = ip
                    renderTemplate(installation['Name'], templateFile, context)
                    
            runQuietly('rsync', '-avz','--delete',
                '-e' ,'ssh -o StrictHostKeyChecking=no -i {0}'.format(context['SSHKeyPath']),
                installation['Name'] + '/', 'root@' + ip + ':/tmp/setup')
            
            runRemote(context['SSHKeyPath'], 'root', ip,
                      'python','/tmp/setup/setup.py')
            
            runRemoteQuietly(context['SSHKeyPath'], 'root', ip,
                      'rm','-rf', '/tmp/setup')
            