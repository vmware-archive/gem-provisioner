#
# Copyright (c) 2015-2016 Pivotal Software, Inc. All Rights Reserved.
#
import subprocess

def runQuietly(*args):
    p = subprocess.Popen(list(args), stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
    output = p.communicate()
    if p.returncode != 0:
        raise Exception('"{0}" failed with the following output: {1}'.format(' '.join(list(args)), output[0]))

if __name__ == '__main__':
    ip = '{{ Servers[ServerNum].PublicIpAddress }}'
    {% for Service in Servers[ServerNum].Installations[InstallationNum].Services %}
    service = '{{ Service  }}'
    runQuietly('systemctl', 'disable', service)
    runQuietly('systemctl', 'stop', service)
    print '{0} - stopped service {1}'.format(ip, service)
    {% endfor %}    
