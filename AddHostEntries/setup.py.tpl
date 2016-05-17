import shutil

if __name__ == '__main__':
    ip = '{{ Servers[ServerNum].PublicIpAddress }}'
    shutil.copyfile('/tmp/setup/hosts', '/etc/hosts')
    print '{0} - added hostname entry to hosts file'.format(ip)