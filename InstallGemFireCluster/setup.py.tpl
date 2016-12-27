#
# Copyright (c) 2015-2016 Pivotal Software, Inc. All Rights Reserved.
#
import json
import os
import os.path
import pwd
import shutil
import subprocess

def basename(url):
    i = url.rindex('/')
    return url[i+1:]

def runQuietly(*args):
    p = subprocess.Popen(list(args), stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
    output = p.communicate()
    if p.returncode != 0:
        raise Exception('"{0}" failed with the following output: {1}'.format(' '.join(list(args)), output[0]))

if __name__ == '__main__':
    ip = '{{Servers[ServerNum].PublicIpAddress }}'

    # locate the parent of cluster-home
    # unpack gemfire-manager into that directory, then rename it so that
    # the newly unpacked scripts are in cluster-home
    # move  cluster.json into cluster-home
    # unpack gemtools into cluster-home
    
    with open('/tmp/setup/cluster.json','r') as f:
        config = json.load(f)
        
    clusterHome = '{{ Servers[ServerNum].Installations[InstallationNum].ClusterHome }}'
    clusterParent = os.path.dirname(clusterHome)
    
    # configure AWS
    AWS_ACCESS_KEY_ID = '{{ Servers[ServerNum].Installations[InstallationNum].AWSAccessKeyId }}'
    AWS_SECRET_ACCESS_KEY = '{{ Servers[ServerNum].Installations[InstallationNum].AWSSecretAccessKey }}'
    AWS_S3_BUCKET_REGION = '{{ Servers[ServerNum].Installations[InstallationNum].AWSS3Region }}'
    runQuietly('aws', 'configure', 'set', 'aws_access_key_id', AWS_ACCESS_KEY_ID)
    runQuietly('aws', 'configure', 'set', 'aws_secret_access_key', AWS_SECRET_ACCESS_KEY)
    runQuietly('aws', 'configure', 'set', 'default.region', AWS_S3_BUCKET_REGION)

    clusterScriptsS3Bucket = '{{ Servers[ServerNum].Installations[InstallationNum].ClusterScriptsS3Bucket }}'
    clusterScriptsArchive = basename(clusterScriptsS3Bucket)
    gemtoolsS3Bucket = '{{ Servers[ServerNum].Installations[InstallationNum].GemToolsS3Bucket }}'
    gemtoolsArchive = basename(gemtoolsS3Bucket)
    
    if os.path.exists(clusterHome):
        print '{0} cluster home directory already exists, skipping cluster script installation'.format(ip)
    else:
        runQuietly('aws', 's3', 'cp', clusterScriptsS3Bucket, '/tmp/setup')
        if clusterScriptsArchive.endswith('.tar.gz'):
            runQuietly('tar', '-C', clusterParent, '-xzf', '/tmp/setup/' + clusterScriptsArchive)
            moveFrom = os.path.join(clusterParent,clusterScriptsArchive)[:-1 * len('.tar.gz')]
        elif clusterScriptsArchive.endswith('.zip'):
            runQuietly('unzip', '/tmp/setup/' + clusterScriptsArchive, '-d', clusterParent)     
            moveFrom = os.path.join(clusterParent,clusterScriptsArchive)[:-1 * len('.zip')]
        
        runQuietly('mv', moveFrom, clusterHome)        
        print '{0} gemfire cluster control scripts installed in {1}'.format(ip, clusterHome)
        
        
    if os.path.exists(os.path.join(clusterHome,'gemtools')):
        print '{0} gemfire toolkit alread found in {1} - skipping intallation'.format(ip, clusterHome)
    else:
        runQuietly('aws', 's3', 'cp', gemtoolsS3Bucket, '/tmp/setup')
        if gemtoolsArchive.endswith('.tar.gz'):
            runQuietly('tar', '-C', clusterHome, '-xzf', '/tmp/setup/' + gemtoolsArchive)
        elif gemtoolsArchive.endswith('.zip'):
            runQuietly('unzip', '/tmp/setup/' + gemtoolsArchive, '-d', clusterHome)
            
        print '{0} gemfire toolkit installed in {1}'.format(ip, os.path.join(clusterHome,'gemtools'))
        
    shutil.copy('/tmp/setup/cluster.json', clusterHome)
    if os.path.exists('/tmp/setup/config'):
      targetDir = os.path.join(clusterHome,'config')
      if os.path.exists(targetDir):
         shutil.rmtree(targetDir)
         
      shutil.copytree('/tmp/setup/config',targetDir)
      
    runQuietly('chown', '-R', '{0}:{0}'.format('{{ Servers[ServerNum].SSHUser }}'), clusterHome)
    print '{0} copied cluster definition into {1}'.format(ip, clusterHome)
    