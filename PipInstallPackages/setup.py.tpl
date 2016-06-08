import subprocess

def runQuietly(*args):
    p = subprocess.Popen(list(args), stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
    output = p.communicate()
    if p.returncode != 0:
        raise Exception('"{0}" failed with the following output: {1}'.format(' '.join(list(args)), output[0]))

#TODO this script assumes it is running as root , should make sudo an option
if __name__ == '__main__':
    ip='{{ Servers[ServerNum].PublicIpAddress }}'
    {% for package in Servers[ServerNum].Installations[InstallationNum].Packages %}
    package = '{{ package }}'
    runQuietly('pip','install', package)
    print '{0} - installed {1} python package'.format(ip, package)
    {% endfor %}
    