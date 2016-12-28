import json
import os.path
import subprocess
import sys

#expects to be invoked like ssh.py user@server101


if __name__ == '__main__':
   if len(sys.argv) < 2:
      sys.exit('Please provide a single target argument. e.g. ssh.py auser@aserver')
      
   target = sys.argv[1]

   here = os.path.dirname(os.path.abspath(sys.argv[0]))
   runtimeFile = os.path.join(here, 'runtime.json')
   envFile = os.path.join(here, 'env.json')
   
   if not os.path.exists(runtimeFile):
      sys.exit('required file "{0}" not found'.format(runtimeFile))
      
   if not os.path.exists(envFile):
      sys.exit('required file "{0}" not found'.format(envFile))
   
   with open(runtimeFile, 'r') as f:
      serverMap = json.load(f)
      
   with open(envFile, 'r') as f:
      settings = json.load(f)
      
   keyFile = settings['SSHKeyPath']
   
   i = target.find('@')
   if i == -1:
      sys.exit('The target argument did not have the expected format.  Target must have the format "user@server"')
      
   user = target[0:i]
   serverName = target[i+1:]
   
   if not serverName in serverMap:
      sys.exit('server "{0}" not found in runtime.json'.format(serverName))
      
   serverIp = serverMap[serverName]
   
   target = user + '@' + serverIp
   
   cmd = ['ssh','-o','StrictHostKeyChecking=no', '-o','UserKnownHostsFile=/dev/null','-i',keyFile, target]
   if len(sys.argv) > 2:
      cmd = cmd + sys.argv[2:]
      
   subprocess.check_call(cmd)
      
   