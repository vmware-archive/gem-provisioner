#
# Copyright (c) 2015-2016 Pivotal Software, Inc. All Rights Reserved.
#
import json
import os
import os.path
import pwd
import subprocess

def runQuietly(*args):
    p = subprocess.Popen(list(args), stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
    output = p.communicate()
    if p.returncode != 0:
        raise Exception('"{0}" failed with the following output: {1}'.format(' '.join(list(args)), output[0]))
    
def hasFileSystem(deviceName):
    if deviceName.startswith('/dev/'):
          deviceName = deviceName[len('/dev/'):]
    
    #TODO would be better to start with the assumption that there is a
    # file system and look for evidence that there is not
    result = False  
    lsblk = subprocess.check_output(['lsblk','-o', 'NAME,FSTYPE', '-l', '--noheadings'])
    for line in lsblk.splitlines():
        if line.startswith(deviceName):
            words = line.split()
            if len(words) > 1:
                result = True
                break
    
    return result
    
def isMounted(deviceName):
     mountOutput = subprocess.check_output(['mount'])
     result = False
     for line in mountOutput.splitlines():
          if line.lower().find(deviceName.lower()) != -1:
               result = True
               break
          
     return result
    
if __name__ == '__main__':
    {% for device in Servers[ServerNum].BlockDevices %}
    ip = '{{ Servers[ServerNum].PublicIPAddress }}'
    {% if device.MountPoint is defined %}
    mountPoint = '{{ device.MountPoint }}'
    if os.path.exists(mountPoint):
        print '{0} Mount point {1} already exists.  Continuing ...'.format(ip, mountPoint)
    else:
        if hasFileSystem('{{ device.Device }}'):
            print '{0} {1} already has a file system on it - skipping format step (you are welcome)'.format(ip,'{{ device.Device }}')
        else:
            {% if device.FSType is defined %}
            runQuietly('mkfs','-t', '{{ device.FSType }}', '{{ device.Device }}')
            print '{0} created new {1} file system on {2}'.format(ip,  '{{ device.FSType }}','{{ device.Device }}' )
            {% endif %}
            pass
            
        os.makedirs(mountPoint)

        {# TODO do we need to edit fstab to make it permanent ?
             or will we always run setup again when a box is restarted #}
             
        if isMounted('{{ device.Device }}'):
          runQuietly('umount',  '{{ device.Device }}')  # some AMI will automatically mount ephemeral devices
          
        {% if device.FSType is defined %}
        runQuietly('mount', '-t', '{{ device.FSType }}', '{{ device.Device }}',mountPoint)
        {% else %}
        runQuietly('mount', '{{ Device.device }}',mountPoint)
        {% endif %}
        
        {% if device.Owner is defined %}
        entry = pwd.getpwnam('{{ device.Owner }}')
        os.chown(mountPoint,entry[2], entry[3])
        {% endif %}
        
        print '{0} mounted {1} on {2}'.format(ip, '{{ device.Device }}', mountPoint)
    {% endif %}
    {% endfor %}