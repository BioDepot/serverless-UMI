# Biodepot serverless RNA-seq workflow

## Instructions for AWS workflow
#### Install Docker
#### Pull Bwb-umi

Make sure the latest version is present

Open a terminal and type

```
docker pull biodepot/bwb-umi:latest
```
#### Start Bwb-umi

#### Warning: 130 GB of disk space are needed to run the workflow

Navigate to a directory that you have at least 130 GB of disk space.

Then type into the terminal: 

```
docker run --rm  -p 6080:6080 -v ${PWD}/:/data -v /var/run/docker.sock:/var/run/docker.sock -v /tmp/.X11-unix:/tmp/.X11-unix --privileged --group-add root biodepot/bwb-umi 
```
If you are running an older version of Docker that uses boot2docker then type
```
docker run --rm  -p 6080:6080 -v /c/users/:/data -v /var/run/docker.sock:/var/run/docker.sock -v /tmp/.X11-unix:/tmp/.X11-unix --privileged --group-add root biodepot/bwb-umi 
```

#### Connect using a browser
Open a browser and type localhost:6080 into the address bar.

For Macs and Windows machines the URL may be different if you are running a Docker in a virtual machine. Type 192:168:99:100:6080 into the bar as this is the usual address for the VM using virtualbox. Otherwise follow the instructions [here](https://docs.docker.com/machine/reference/ip) to find the ip address.

If you accidentally close the browser window - that is OK. Bwb does not quit - you can just open another browser window to the same address to reconnect. To quit check here add link<--
#### Load workflow

This version of bwb comes with the serverless workflows pre-installed. Under the File menu choose Load workflow and navigate to /workflows

Click on AWS-workflow-UMI and click on the choose button

#### Load Containers

Go to the File menu - choose Load containers

When the load containers window pops up - check off the reload even if container is present to ensure that the latest image is downloaded.


#### Double click on start widget
-Put mouse over the start widget in lower left of window. You will see that it transmits many initial parameters to the other modules (widgets) in the workflow.

You will need to edit some of these parameters. Double click on the start widget. You can resize the window by positioning the mouse to the lower right hand corner and dragging. You can minimize/maximize the window by using the three buttons in the top right corner.

#### Copy your credentials directory
Before going further, you need to obtain a set of credentials for your AWS account. Instructions are here <- link

By default your credentials are in the invisible .aws subdirectory in your home directory. You should copy this to the directory where you started Bwb  c:/users if you started the Bwb command using the c:/users:/data mapping.

Alternatively, you can click on the folder icon next to the credentials directory option and navigate to where the credentials directory is or enter it directly into the field 

#### Personalize cloud bucket name, region and function name parameters

Three parameters need to be changed from the defaults. 

The cloud bucket name can be one of your existing buckets. We strongly suggest that you create a new one to avoid accidentally deleting an existing bucket. 

Similarly the function name must be something unique or a function name that you have permission to overwrite (i.e. a previously created function_name).

Finally, the region that you specify should match your default region on your AWS account

##### Optionally, change other start parameters

Of the parameters, for the demo you can keep all of them or modify them if you wish to change the path where the results will be stored. The /data directory in Bwb points to the directory that you started Bwb or /c:/users if you are using Windows. Just make sure that if you want to store things in a sub-directory of /data you change the entire set of paths to be consistent.

Remember that you need 130 GB of disk space to store all the fastq files and shards. If you do not have that much space in your current directory. Then quit Bwb by following the instructions here <-- add link.

#### Starting the workflow

Press start button at the bottom of the start icon to start the workflow. 
