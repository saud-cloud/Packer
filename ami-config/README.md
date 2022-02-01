# Pre Requisites
- A VPC 
- A public Subnet 
# Usage
Populate `ami-config` repository with configuration fragments. Following steps should be followed to create the image 

## Run Cloudformation Template

Run the Cloud formation template **Packer_Instance_CFT.yml**  under ami-config/cloudformation directory.
**Note:**
Make sure you have a existing VPC , Keypair, and a Public subnet. You will have to provide these in the  parameters of Cloud Formation template to create the stack  and you will also have to provide you ip the Cloudformation template 


## Clone the eq-skybase repository form Enquzit git-hub account 
ssh in to the EC2 instance that is created by the Cloud formation template stack that you created. SSH in to the EC2 using the key pair that you specified.
check the packer version by running the following command "Packer --version".just to make sure you are in the right EC2 and you have packer available

### Note: 
if you are having trouble in trying to ssh in to the EC2 then make sure that Your IP is not changed and is being reflected in the security group created by the Cloud formation template .ADD your ip in to the security group to ssh in to the console.


## Now get the VPC setup and create the ami by following the steps below 
```
cd eq-skybase/ami-config/packer
```
Create a copy of example-linux.conf file if you want to create a linux ami or you can create a copy of example-windows.conf if you want to create ami for windows. you can give any name to the new conf file forexample here we have named the file as CSTest.conf 
```
Syntax for linux:
cp -p ./example-linux.conf CSTest.conf
Syntax for Widnows:
cp -p ./example-windows.conf CSTest.conf
```
The name of the shell script such as example-linux.sh and the name of the configuration file should be the same i.e example-linux.conf because the example-linux.sh is linked to a root create-image.sh script which picks up the conf file having the similar name like the shell file. It is a good practice to give similar name to the template file that we will create after the creation of conf file.

Vi in your newly created conf file. Once you vi in the file change the vpc-id with the vpc-id you have specified in the Cloud formation template and also change the template name in the last line of the file. Give similar name like  the configuration file in the template path with a .json extension
```
vi CSTest.conf 
```
### Examples:

```
Network=network/<your vpc id here>

Template=templates/CSTest.json
```

**Symlink** a new file matching the configuration filename to the `create-image.sh` e that is inside /ami-factory/packer . The name name of new shell file should be similar to the conf file else the new shell file wont be able to find the conf file that you created earlier.
```
ln -s ../ami-factory/packer/create-image.sh CSTest.sh
```
Now **create the template file** with the same name that you specified in the templates path in the conf file.In the templates directory  copy the example-linux.json file for linux ami and example example-windows.json if you are creating windows ami in the new template file
```
cd templates
#for linux AMI use the below command
cp -p ./example-linux.json ./CSTest.json
#For windows AMI use the below command
cp -p ./example-windows.json ./CSTest.json

```
**provide subnet, security group and vpc id** by creating a new vpcid.json file. This file will setup the vpc where the client EC2 will spin up when you will run the AMI creation process .you will also need to add **"ssh.interface" : "private_ip"**,  to vpc file if ssh communicator tries to connect to public ip of ec2

``` 
#Inside the packer directory
cd /network
#copy the vpc-09226a292c2a00415.json file in a new file and use your vpc-id as the name of the new file
cp -p vpc-09226a292c2a00415.json <your-vpcid.json>
```
Vi in to the newly creatied <your-vpcid.json> file  and change the subnetid ,security group id and vpc id that with the ones attached with your EC2 that is created the Cloud formation template. 
```
vi <your-vpcid.json>
```
**Create a new pem file** and copy your EC2 private key init and then move it to the ssh directory
```
vi packerinstance.pem
mv packerinstance.pem ~/.ssh
```
Now run the packer instance creation command.

# Note: 

The keypair name in the below command should be similar to the one that you have on the AWS console. 
The shell file name should be similar to the file that you have created and linked with the create-image.sh script and in the similar way the pem file name in the command should be similar to the pem file that you have created and moved to ~/.ssh.  Change directory to packer and then run the following command. 
```
./CSTest.sh build   -var instance.ssh.keypair=packerinstance -var instance.ssh.private_key=/home/ec2-user/.ssh/packerinstance.pem
```




