### Packer
Packer is an open source tool for creating identical machine images for multiple platforms from a single source configuration
The provisioners can be used to run Ansible, Chef, Puppet or other customization software to
bake a configuration into the resulting image. If at all possible the manifests/recipes/plays
should be written in a broadly compatible manner so the codebase can be re-used. Client or 
Environment-specific settings should be injected via Hiera (if using puppet), environment variables, or Attributes
or the codebase branched if the changes are too extensive and don't lend themselves to simple
overrides.
## About AMI creation Command:

When running the command
```
./example-linux.sh build  -var instance.ssh.keypair=packerpem -var instance.ssh.private_key=/home/ec2-user/.ssh/packerinstance.pem
```
There are different flags that can be used to change the output for the above command, such as -l , -d = debug ,-n = noop, -p ,-v.  A better understanding of these flags can be taken from the create-image.sh file inside ami-config/ami-factory/packer/ . and  you can also run the script with -help flag to get the usage.
For example the -n flag specified here basically return the commands that are going to be run against the above command . The -n flag is very useful for debugging as it lets you know the scope of the command which makes it easy for you to debug issues . 
Output when running the command with -n flag:
```
/usr/bin/packer build -timestamp-ui -parallel-builds=1 -on-error=ask -var instance.ssh.keypair=packerpem -var instance.ssh.private_key=/home/ec2-user/.ssh/packerinstance.pem -var-file=./network/vpc-c0e064bb.json -var-file=./builder/amazon-ebs.json -var-file=./platform/linux.json -var-file=./platform/redhat.json -var-file=./image/redhat-rhel7.json -var-file=./project/default.json -var-file=./layer/base.json -var basedir=/home/ec2-user/ami-config/ami-factory -var factory.basedir=/home/ec2-user/ami-config/ami-factory -var ansible.basedir=/home/ec2-user/ami-config/ansible -var instance.ssh.private_key=/home/ec2-user/.ssh/packerinstance.pem -var provision.debug=0 -var provision.verbose=0 templates/example-linux.json
```

## Settings priority order :
 The settings and variables are overwriten in the following priority:
```
 Packer Program defaults  < config files < Environment Variables   < Command line switch
```
# Inside ami-config/Packer/
## Note: 
  This is a collection of re-usable templates intended for use in creating tailored Machine Images.
## example-linux.conf
   An example linux ami configuration file. In this file you can change the platform and  base image of the ami  
## example-windows.conf
   An example windows ami configuration file that you can use to create the windows ami   
## Example.conf 
 Example.conf=> An example linux ami configuration file. In this file you can change the platform and  base image of the ami  
## Example.sh
 Example.sh -> a example shell script file linked with ami-factory/packer/create-image.sh 
## baseline-windows.conf
 baseline-windows.conf=> configuration to create a windows ami 
## baseline-windows.sh
 baseline-windows.sh=> a file linked to the root create-image.sh file 
## baseline.conf
 baseline.conf=> configuration file for creating a linux ami some what similar to the example.conf
## baseline.sh
 baseline.sh=> a file linked to the the root create-image.sh
 
 
## Templates directory 
The templates directory contain the template file i.e example-linux.json for linux & example-windows.json for windows, These json files contains the variables , builders and provisioners a lot of customization in the ami  will be done using the template file.
In order to do any changes in the configuration of the AMI you can edit this template file and make changes in the provisioners for changes related to AMI and if you want to change the machine size or anything relate to the machine creation on which the ami is baked by Packer then you can make changes in the builder section of the file.
Most of the customization is done using two files which is the conf file which is basically the configuration file and template file which is in the templates directory.
   ### What are Variables
Variables in the template file are to define the variables or initiate the variable so if they are used later they exist  . some values are set here  and some are overwritten in other files.

   ### Builders : 
builders are used to create machines for image creation . A builder is a component of Packer that is responsible for creating a machine and turning that machine into an image. 

   ### Provisioners: 
Within the template, the provisioners section contains an array of all the provisioners that Packer should use to install and configure software within running machines prior to turning them into machine images. Provisioners are optional.  The provisioners can be used to run ,shell scripts, Ansible, Chef, Puppet or other customization software to bake a configuration into the resulting image.
  #### Ansible Provisioner:

The ansible Packer provisioner runs Ansible playbooks. It dynamically creates an Ansible inventory file configured to use SSH, runs an SSH server, executes ansible-playbook, and marshals Ansible plays through the SSH server to the machine being provisioned by Packer.


In the current configuration we (EQ) use ansible playbooks to apply "Security Technical Implementation Guides" (STIGs) changes to the temporary instances.
These are maintained by DISA — Defense Information Systems Agency.

The STIGs were sourced from other repositories and should be updated as the originals are updated and as  scans show lack of compliance.

ami-config/ansible/OSCAP

contains playbook files from 
https://github.com/ansible-lockdown/RHEL7-STIG

The provisioner to use this in the example templates include:

	# definition of provisioner type 
        "type"                  : "ansible",

	# path to ansible config yaml file
        "playbook_file"         : "{{user `ansible.basedir`}}/OSCAP/site.yaml",


The variables needed are defined automatically in the create-image.sh script based on the platform
ami-config/packer/platform/linux.json
ami-config/packer/platform/redhat.json
ami-config/packer/image/redhat-rhel7.json

The ansible provisioner MUST be included for the STIGs to be applied.


An example of Shell provisioner is given below .
```
 {
        "type"                  : "shell",
        "start_retry_timeout"   : "{{user `reboot.timeout`}}",
        "expect_disconnect"     : true,
        "environment_vars" : [
            "DEBUG={{user `provision.debug`}}",
            "VERBOSE={{user `provision.verbose`}}"
        ],
        "inline" : [
            "# hard-coded for DoT instead of using JSON inputs to installer",
            "cd {{user `os.tmpdir`}}",
            "WGET='wget -4 -nc -nv --timeout=90'",

            "# SNMP v3",
            "sudo yum install -y net-snmp net-snmp-utils net-snmp-devel",
            "#sudo net-snmp-config --create-snmpv3-user -ro -A fdvxYIYJlGG2WS5NbspV -X fdvxYIYJlGG2WS5NbspV -a SHA -x AES DOTsnmpv3agent",
            "#( cd /etc/snmp; sudo $WGET https://s3.amazonaws.com/dot-newserverinstall/etc/snmp.conf )",

            "# Big-Fix, https://support.bigfix.com/bes/release/",
            "#sudo rpm -ivh http://software.bigfix.com/download/bes/95/BESAgent-9.5.8.38-rhe6.x86_64.rpm",
            "#( CONF_DIR=/etc/opt/BESClient; sudo mkdir -p $CONF_DIR; sudo $WGET -O $CONF_DIR/actionsite.afxm https://s3.amazonaws.com/dot-newserverinstall/BES+Client/Windows/masthead.afxm )",
}


```
## builder directory
The builder directory contains-amazon-ebs.json  file in which you specify the role that will be attached to the temporary ec2 that gets spined up  when you run the shell script for AMI creation 
## disk directory
The  disk directory contains disk related Variables in the Example.json file. The disk related variables have been merged in the base.json file in the templates directory now . 
## image directory
The image directory contains different versions of redhat ,ubuntu ,windows ,amazon images that can be used as a base image for ami creation 
## network directory 
The network directory  contains VPC configuration file vpc-09226a292c2a00415.json.provide  your own subnet, security group, VPC and region for the temporary ec2 .
## platform directory           
The platform directorys contains the platform that you are going to choose such as linux or windows etc  
# Inside ami-config/ami-factory/packer
## create-image.sh
 create-image.sh => shell script that basically creates the AMI . This script is also a good source for better understanding of flags.



