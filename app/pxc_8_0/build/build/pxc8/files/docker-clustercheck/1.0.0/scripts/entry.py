#!/usr/bin/env python
# This script takes command line options and
# starts up mysqld

########################################################################################################################
# LIBRARY IMPORT                                                                                                       #
########################################################################################################################
# Import required libaries
import sys,os,pwd,grp   # OS Libraries
import argparse         # Parse Arguments
from subprocess import Popen, PIPE, STDOUT
                        # Open up a process

# Important required templating libarires
from jinja2 import Environment as TemplateEnvironment, \
                   FileSystemLoader, Template
                        # Import the jinja2 libaries required by this script
from jinja2.exceptions import TemplateNotFound
                        # Import any exceptions that are caught by the Templates section

# Specific to to this script
from IPy import IP

# Functions
def isIP(address):
   try:
      IP(address)
      ip = True
   except ValueError:
      ip = False
   return ip


########################################################################################################################
# ARGUMENT PARSER                                                                                                      #
# This is where you put the Argument Parser lines                                                                      #
########################################################################################################################
# 4 positional arguments required:
# mysql_ip - The IP address of the host that is running MySQL
# mysql_port - The port that the host is listening on for MySQL
# mysql_user - The user to connect through to MySQL for monitor checks of the cluster health
# mysql_pass - The password for the user to connect through to MySQL for monitor checks of the cluster health
argparser = argparse.ArgumentParser(description='Run a docker container containing a clustercheck Instance')

argparser.add_argument('mysql_ip',
                       action='store',
                       help='The IP address of the host that is running MySQL')

argparser.add_argument('mysql_port',
                       action='store',
                       help='The port that the host is listening on for MySQL')

argparser.add_argument('mysql_user',
                       action='store',
                       help='The user to connect through to MySQL for monitor checks of the cluster health')

argparser.add_argument('mysql_pass',
                       action='store',
                       help='The password for the user to connect through to MySQL for monitor checks of the cluster health')

try:
   args = argparser.parse_args()
except SystemExit:
   sys.exit(0) # This should be a return 0 to prevent the container from restarting.

    
########################################################################################################################
# ARGUMENT VERIRIFCATION                                                                                               #
# This is where you put any logic to verify the arguments, and failure messages                                        #
########################################################################################################################
# 
# Check that mysql_ip is a valid IP address
if not isIP(args.mysql_ip):
   print "The argument %s must be a valid IP address" % args.mysql_ip
   sys.exit(0) # This should be a return 0 to prevent the container from restarting.


########################################################################################################################
# TEMPLATES                                                                                                            #
# This is where you manage any templates                                                                               #
########################################################################################################################
# Configuration Location goes here
template_location = '/clustercheck-templates'

# Create the template list
template_list = {}

# Templates go here
### my.cnf ###
template_name = 'my.cnf'
template_dict = { 'context' : { # Subsitutions to be performed
                                'mysql_ip'     : args.mysql_ip,
                                'mysql_port'   : args.mysql_port,
                              },
                  'path'    : '/etc/my.cnf',
                  'user'    : 'root',
                  'group'   : 'root',
                  'mode'    : 0644 }
template_list[template_name] = template_dict

### clustercheck ###
template_name = 'clustercheck'
template_dict = { 'context' : { # Subsitutions to be performed
                                'mysql_user'   : args.mysql_user,
                                'mysql_pass'   : args.mysql_pass,
                              },
                  'path'    : '/etc/xinetd.d/clustercheck',
                  'user'    : 'root',
                  'group'   : 'root',
                  'mode'    : 0644 }
template_list[template_name] = template_dict

# Load in the files from the folder
template_loader = FileSystemLoader(template_location)
template_env = TemplateEnvironment(loader=template_loader,
                                   lstrip_blocks=True,
                                   trim_blocks=True,
                                   keep_trailing_newline=True)

# Load in expected templates
for template_item in template_list:
   # Attempt to load the template
   try:
       template_list[template_item]['template'] = template_env.get_template(template_item)
   except TemplateNotFound as e:
       errormsg = "The template file %s was not found in %s (returned %s)," % template_item, template_list, e
       errormsg += " terminating..."
       print errormsg
       sys.exit(0) # This should be a return 0 to prevent the container from restarting

   # Attempt to open the file for writing
   try:
       template_list[template_item]['file'] = open(template_list[template_item]['path'],'w')
   except IOError as e:
       errormsg = "The file %s could not be opened for writing for template" % template_list[template_item]['path']
       errormsg += " %s (returned %s), terminating..." % template_item, e
       print errormsg
       sys.exit(0) # This should be a return 0 to prevent the container from restarting

   # Stream
   try:
       template_list[template_item]['render'] = template_list[template_item]['template'].\
                                            render(template_list[template_item]['context'])

       # Submit to file

       template_list[template_item]['file'].write(template_list[template_item]['render'].encode('utf8'))
       template_list[template_item]['file'].close()
   except:
       e = sys.exc_info()[0]
       print "Unrecognised exception occured, was unable to create template (returned %s), terminating..." % e
       sys.exit(0) # This should be a return 0 to prevent the container from restarting.

   # Change owner and group
   try:
       template_list[template_item]['uid'] = pwd.getpwnam(template_list[template_item]['user']).pw_uid
   except KeyError as e:
       errormsg = "The user %s does not exist for template %s" % template_list[template_item]['user'], template_item
       errormsg += "(returned %s), terminating..." % e
       print errormsg
       sys.exit(0) # This should be a return 0 to prevent the container from restarting

   try:
       template_list[template_item]['gid'] = grp.getgrnam(template_list[template_item]['group']).gr_gid
   except KeyError as e:
       errormsg = "The group %s does not exist for template %s" % template_list[template_item]['group'], template_item
       errormsg += "(returned %s), terminating..." % e
       print errormsg
       sys.exit(0) # This should be a return 0 to prevent the container from restarting

   try:
       os.chown(template_list[template_item]['path'],
                template_list[template_item]['uid'],
                template_list[template_item]['gid'])
   except OSError as e:
       errormsg = "The file %s could not be chowned for template" % template_list[template_item]['path']
       errormsg += " %s (returned %s), terminating..." % template_item, e
       print errormsg
       sys.exit(0) # This should be a return 0 to prevent the container from restarting

   # Change permissions
   try:
       os.chmod(template_list[template_item]['path'],
                template_list[template_item]['mode'])
   except OSError as e:
       errormsg = "The file %s could not be chmoded for template" % template_list[template_item]['path']
       errormsg += " %s (returned %s), terminating..." % template_item, e
       print errormsg
       sys.exit(0) # This should be a return 0 to prevent the container from restarting


########################################################################################################################
# SPAWN CHILD                                                                                                          #
########################################################################################################################
# Spawn the child
child_path = ['/usr/sbin/xinetd', '-dontfork']

# Flush anything on the buffer
sys.stdout.flush()
# Reopen stdout as unbuffered. This will mean log messages will appear as soon as they become avaliable.
sys.stdout = os.fdopen(sys.stdout.fileno(), 'w', 0)

child = Popen(child_path, stdout = PIPE, stderr = STDOUT, shell = False) 

# Output any log items to Docker
for line in iter(child.stdout.readline, ''):
    sys.stdout.write(line)

# If the process terminates, read its errorcode and return it
sys.exit(child.returncode)
