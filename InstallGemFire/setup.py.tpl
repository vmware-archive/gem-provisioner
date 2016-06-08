import os.path
import shutil
import subprocess

# these hard coded keys have (only) read access to the software buckets
AWS_ACCESS_KEY_ID = 'AKIAJXWLAUH63ULBFOPA'
AWS_SECRET_ACCESS_KEY = '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'
AWS_S3_BUCKET_REGION = 'us-west-2'
AWS_S3_BUCKET = 's3://rmay.pivotal.io.software/'
JDK_FILE = 'jdk-8u92-linux-x64.tar.gz'
JDK='jdk1.8.0_92' # this is the name of the root directory in the java tar
GEMFIRE_FILE = 'Pivotal_GemFire_820_b17919_Linux.tar.gz'

def runQuietly(*args):
    p = subprocess.Popen(list(args), stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
    output = p.communicate()
    if p.returncode != 0:
        raise Exception('"{0}" failed with the following output: {1}'.format(' '.join(list(args)), output[0]))

if __name__ == '__main__':
    ip = '{{ Servers[ServerNum].PublicIpAddress }}'
    
    runQuietly('aws', 'configure', 'set', 'aws_access_key_id', AWS_ACCESS_KEY_ID)
    runQuietly('aws', 'configure', 'set', 'aws_secret_access_key', AWS_SECRET_ACCESS_KEY)
    runQuietly('aws', 'configure', 'set', 'default.region', AWS_S3_BUCKET_REGION)
    runQuietly('aws', 's3', 'cp', AWS_S3_BUCKET + JDK_FILE, '/tmp/setup')
    runQuietly('tar', '-C', '/runtime', '-xzf', '/tmp/setup/' + JDK_FILE)
    runQuietly('ln', '-s', '/runtime/' + JDK, '/runtime/java')
    print '{0} - downloaded and installed java'.format(ip)
    
    runQuietly('aws', 's3', 'cp', AWS_S3_BUCKET + GEMFIRE_FILE, '/tmp/setup')
    runQuietly('tar', '-C', '/runtime', '-xzf', '/tmp/setup/' + GEMFIRE_FILE)
    GEMFIRE = GEMFIRE_FILE[0:GEMFIRE_FILE.find('.tar.gz')]
    runQuietly('ln', '-s', '/runtime/Pivotal_GemFire_820_b17919_Linux', '/runtime/gemfire')
    print '{0} - downloaded and installed GemFire'.format(ip)
    