# note: this is python3!
import jinja2
import json
import os
import os.path
import subprocess
import sys
import threading
import time

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
    env.trim_blocks = True
    env.lstrip_blocks = True
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
    assert sys.version_info >= (3,0)
    
    #read the environment file 
    env = jinja2.Environment(loader=jinja2.FileSystemLoader('.'))
    with open('env.json', 'r') as contextFile:
        context = json.load(contextFile)
    
    here = os.path.dirname(sys.argv[0])
    if len(here) == 0:
        here = '.'

    with open('runtime.json','r') as f:
        ipTable = json.load(f)
                
    for templateFile in os.listdir(here):
        if templateFile.endswith('.tpl'):
            if templateFile != 'cloudformation.json.tpl':
                renderTemplate(here, templateFile, context)        
                print('{0} rendered'.format(templateFile[0:-4]))
                
    serverNum = -1
    for server in context['Servers']:
        serverName = context['EnvironmentName'] + 'Server' + server['Name']
        ip = ipTable[serverName]
        server['PublicIpAddress'] = ip
        serverNum += 1
        installationNum = -1
        for installation in server['Installations']:
            installationNum += 1
            for templateFile in os.listdir(installation['Name']):
                if templateFile.endswith('.tpl'):
                    context['ServerNum'] = serverNum
                    context['InstallationNum'] = installationNum
                    renderTemplate(installation['Name'], templateFile, context)
                    
            runQuietly('rsync', '-avz','--delete',
                '-e' ,'ssh -o StrictHostKeyChecking=no -i {0}'.format(context['SSHKeyPath']),
                installation['Name'] + '/', 'root@' + ip + ':/tmp/setup')
            
            runRemote(context['SSHKeyPath'], 'root', ip,
                      'python','/tmp/setup/setup.py')
            
            runRemoteQuietly(context['SSHKeyPath'], 'root', ip,
                      'rm','-rf', '/tmp/setup')
            