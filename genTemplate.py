#
# Copyright (c) 2015-2016 Pivotal Software, Inc. All Rights Reserved.
#
from  jinja2 import Environment, FileSystemLoader
import json
import sys


if __name__ == '__main__':
    env = Environment(loader=FileSystemLoader('.'))
    with open('env.json', 'r') as contextFile:
        context = json.load(contextFile)
        
    template = env.get_template('cloudformation.json.tpl')
    
    with open('cloudformation.json', 'w') as outfile:
        outfile.write(template.render(context))
        
    print 'cloudformation.json rendered'