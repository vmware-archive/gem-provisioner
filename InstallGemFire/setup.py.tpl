import shutil
import subprocess

def runQuietly(*args):
    p = subprocess.Popen(list(args), stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
    output = p.communicate()
    if p.returncode != 0:
        raise Exception('"{0}" failed with the following output: {1}'.format(' '.join(list(args)), output[0]))

if __name__ == '__main__':
    ip = '{{ Servers[ServerNum].PublicIpAddress }}'
    clusterHome = '{{ Servers[ServerNum].Installations[InstallationNum].ClusterHome }}'
    runQuietly('aws', 'configure', 'set', 'aws_access_key_id', '{{ AWSAccessKeyId }}')
    runQuietly('aws', 'configure', 'set', 'aws_secret_access_key', '{{ AWSSecretAccessKey }}')
    runQuietly('aws', 'configure', 'set', 'default.region', 'us-west-2')
    runQuietly('aws', 's3', 'cp', 's3://rmay.pivotal.io.software/jdk-8u92-linux-x64.tar.gz', '/tmp/setup')
    runQuietly('tar', '-C', '/runtime', '-xzf', '/tmp/setup/jdk-8u92-linux-x64.tar.gz')
    runQuietly('ln', '-s', '/runtime/jdk1.8.0_92', '/runtime/java')
    print '{0} - downloaded and installed java'.format(ip)
    runQuietly('aws', 's3', 'cp', 's3://rmay.pivotal.io.software/Pivotal_GemFire_820_b17919_Linux.tar.gz', '/tmp/setup')
    runQuietly('tar', '-C', '/runtime', '-xzf', '/tmp/setup/Pivotal_GemFire_820_b17919_Linux.tar.gz')
    runQuietly('ln', '-s', '/runtime/Pivotal_GemFire_820_b17919_Linux', '/runtime/gemfire')
    print '{0} - downloaded and installed GemFire'.format(ip)

    #TODO the cluster home and location of cluster control scripts should be parameterized
    runQuietly('mkdir','/runtime/cluster')
    shutil.copyfile('/tmp/setup/cluster.py','/runtime/cluster.py')
    shutil.copyfile('/tmp/setup/clusterdef.py','/runtime/clusterdef.py')
    shutil.copyfile('/tmp/setup/gemprops.py','/runtime/gemprops.py')
    shutil.copyfile('/tmp/setup/cluster.json','/runtime/cluster.json')
    print '{0} - install GemFire cluster scripts'.format(ip)
    