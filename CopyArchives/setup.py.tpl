#
# Copyright (c) 2015-2016 Pivotal Software, Inc. All Rights Reserved.
#
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
    ip = '{{ Servers[ServerNum].PublicIpAddress }}'

    {% if "AWSAccessKeyId" in Servers[ServerNum].Installations[InstallationNum] %}
    
    AWS_ACCESS_KEY_ID = '{{ Servers[ServerNum].Installations[InstallationNum].AWSAccessKeyId }}'
    AWS_SECRET_ACCESS_KEY = '{{ Servers[ServerNum].Installations[InstallationNum].AWSSecretAccessKey }}'
    AWS_S3_BUCKET_REGION = '{{ Servers[ServerNum].Installations[InstallationNum].AWSS3Region }}'
    runQuietly('aws', 'configure', 'set', 'aws_access_key_id', AWS_ACCESS_KEY_ID)
    runQuietly('aws', 'configure', 'set', 'aws_secret_access_key', AWS_SECRET_ACCESS_KEY)
    runQuietly('aws', 'configure', 'set', 'default.region', AWS_S3_BUCKET_REGION)
    
    {% endif %}
    
    {% for Archive in Servers[ServerNum].Installations[InstallationNum].Archives %}

    parentDir = '{{ Archive.UnpackInDir }}'
    archiveDir = '{{ Archive.RootDir }}'
    name = '{{ Archive.Name }}'
    archiveURL = '{{ Archive.ArchiveURL }}'
    archiveFile = basename(archiveURL)
    
    if os.path.exists(os.path.join( parentDir, archiveDir)):
        print '{0} is already installed - continuing'.format(name)
    else:
        if archiveURL.startswith('s3:'):
            runQuietly('aws', 's3', 'cp', archiveURL, '/tmp/setup')
        else:
            runQuietly('wget', '-P', '/tmp/setup', archiveURL)
        
        if archiveFile.endswith('.tar.gz'):
            runQuietly('tar', '-C', parentDir, '-xzf', '/tmp/setup/' + archiveFile)
        elif archiveFile.endswith('.zip'):
            runQuietly('unzip', '/tmp/setup/' + archiveFile, '-d', parentDir)
            
        runQuietly('chown', '-R', '{0}:{0}'.format('{{ Servers[ServerNum].SSHUser }}'), os.path.join(parentDir,archiveDir))
        
        {% if 'LinkName' in Archive %}
        linkName = '{{ Archive.LinkName }}'
        runQuietly('ln', '-s', os.path.join(parentDir,archiveDir), os.path.join(parentDir, linkName))
        {% endif %}
        
        print '{0} - downloaded and installed {1}'.format(ip, name)
        
    {% endfor %}

    