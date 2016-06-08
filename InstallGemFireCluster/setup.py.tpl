import os.path
import shutil
import subprocess

JDK_FILE = 'jdk-8u92-linux-x64.tar.gz'
GEMFIRE_FILE = 'Pivotal_GemFire_820_b17919_Linux.tar.gz'

def runQuietly(*args):
    p = subprocess.Popen(list(args), stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
    output = p.communicate()
    if p.returncode != 0:
        raise Exception('"{0}" failed with the following output: {1}'.format(' '.join(list(args)), output[0]))

if __name__ == '__main__':
    to = '{{Servers[ServerNum].Installations[InstallationNum].Directory }}'
    ip = '{{Servers[ServerNum].PublicIpAddress }}'
    
    runQuietly('cp', '-r', '/tmp/setup', to)
    print '{0} - installed GemFire cluster scripts in {1}'.format(ip, to)
    