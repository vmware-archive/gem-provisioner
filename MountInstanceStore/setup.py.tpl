#
# Copyright (c) 2015-2016 Pivotal Software, Inc. All Rights Reserved.
#
import json
import os.path
import subprocess

def runQuietly(*args):
    p = subprocess.Popen(list(args), stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
    output = p.communicate()
    if p.returncode != 0:
        raise Exception('"{0}" failed with the following output: {1}'.format(' '.join(list(args)), output[0]))
    

#TODO this script assumes it is running as root , should make sudo an option
if __name__ == '__main__':
    mountPoint = '{{ Servers[ServerNum].Installations[InstallationNum].MountPoint }}'
    device = '{{ Servers[ServerNum].Installations[InstallationNum].Device }}'
    fsType = '{{ Servers[ServerNum].Installations[InstallationNum].FileSystemType }}'
    ip = '{{ Servers[ServerNum].PublicIpAddress }}'
    
    if os.path.exists(mountPoint):
        print 'instance store mount point already exists - continuing'
    
    else:
        runQuietly('mkfs', '-t', fsType, device)
        runQuietly('mkdir', mountPoint)
        runQuietly('mount', '-t',fsType, device,mountPoint)
        print '{0} - instance store initialized and mounted on {1}'.format(ip, mountPoint)