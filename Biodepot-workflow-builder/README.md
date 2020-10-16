# Biodepot serverless RNA-seq workflow

## Instructions for workflow

#### Youtube video

A 7 minute youtube video is available: [https://youtu.be/WHb_lQv3Y8Y](https://youtu.be/WHb_lQv3Y8Y) which shows the basico operation for the AWS workflow 


#### Get credentials

##### AWS #####

Before going further, you need to obtain a set of credentials for your AWS account. Instructions are in the top-level [README](https://github.com/BioDepot/serverless-UMI/blob/master/README.md) as to how to obtain your access_key_id and your secret_access_key

You then need to create a credentials directory and a credentials file if you do not already have one

i.e.
``` 
mkdir .aws
cd .aws
echo "[default]" > credentials
#replace xx with key
#replace yy with secret
echo "aws_access_key_id = xx" >> credentials 
echo "aws_secret_access_key = yy" >> credentials

```
If you have already installed and configured aws cli tools, you will probably have a credentials directory in ~/.aws


By default your credentials are in the invisible .aws subdirectory in your home directory. You should copy this to the directory where you started Bwb  c:/users if you started the Bwb command using the c:/users:/data mapping.

##### Google

For Google you need to create a project and then obtain a key pair same as AWS. You then download a file with the key pair as detailed in the top level README](https://github.com/BioDepot/serverless-UMI/blob/master/README.md).

Make sure this file is in a directory that you will be visibile in Docker. If you follow the instructions in this README, that will be a sub-directory of where you start the Docker process.

#### Install Docker

The instructions for installing Docker are [here](https://docs.docker.com/get-docker/) 

#### Pull Bwb-umi

Make sure the latest version is present

Open a terminal and type

```
docker pull biodepot/bwb-umi:latest
```
#### Start Bwb-umi

##### Warning: 130 GB of disk space are needed to run the workflow

Navigate to a directory that you have at least 130 GB of disk space.

If the credentials directory is not in this directory then copy it over 
```
cp -r original_directory/.aws . 

```
Then type into the terminal: 

```
docker run --rm  -p 6080:6080 -v ${PWD}/:/data -v /var/run/docker.sock:/var/run/docker.sock -v /tmp/.X11-unix:/tmp/.X11-unix --privileged --group-add root biodepot/bwb-umi 
```
If you are running an older version of Docker that uses boot2docker then type
```
docker run --rm  -p 6080:6080 -v /c/users/:/data -v /var/run/docker.sock:/var/run/docker.sock -v /tmp/.X11-unix:/tmp/.X11-unix --privileged --group-add root biodepot/bwb-umi 
```

#### Connect using a browser

Open a browser and type <ip\>:6080 into the address bar.

The value of <ip\> depends on where you are running Bwb. If you are running it remotely then it is the ip of the server or instance.

If you are running Bwb locally then it depends on the operating system you are using.

On Linux machines, <ip\> will be
```
localhost 
```
or 
```
127.0.0.1
```
For Macs and Windows machines the URL may be different if you are running a Docker in a virtual machine. It is most likely

```
192:168:99:100:6080 
```
 
Otherwise follow the instructions [here](https://docs.docker.com/machine/reference/ip) to find the ip address.

On an AWS instance the ip will be
the public url - something like
```
ec2-18-217-218-89.us-east-2.compute.amazonaws.com:6080
```
If you accidentally close the browser window - that is OK. Bwb does not quit - you can just open another browser window to the same address to reconnect. 

To quit the container, close the Bwb window, right click inside the browser and choose the *QUIT container* option. Alternatively, you can also stop it by finding the container id and stopping the container from the command line.

#### Load workflow

This version of Bwb comes with the serverless workflows pre-installed. Under the File menu choose Load workflow and navigate to /workflows

##### AWS
Click on *AWS-workflow-UMI* and then click on the *Choose* button at the bottom right of the popup.

##### Google

Click on *GCP-workflow-UMI* and then click on the *Choose* button at the bottom right of the popup.

#### Load Containers

Go to the *File* menu - choose *Load containers*

When the load containers window pops up - check off the box *Reload even if container is present* to ensure that the latest image is downloaded. Then click on the *Load* button to load. When the containers finish loading you will receive a message that there were no errors. If not - you can try again - it is not uncommon for the DockerHub to be busy and time out especially if you have a slow internet connection. You can scroll through the messages in the console if you want to see if this is the case. 

The load containers step is not absolutely necessary - however if you do not pre-load - Docker will try to pull the container when you actually need to use it.

#### Double click on start widget

-Put mouse over the start widget in lower left of window. You will see that it transmits many initial parameters to the other modules (widgets) in the workflow.

You will need to edit some of these parameters. Double click on the start widget. You can resize the window by positioning the mouse to the lower right hand corner and dragging. You can minimize/maximize the window by using the three buttons in the top right corner.

##### AWS

Three parameters need to be changed from the defaults. 

The cloud bucket name can be one of your existing buckets. We strongly suggest that you create a new one to avoid accidentally deleting an existing bucket. 

Similarly the function name must be something unique or a function name that you have permission to overwrite (i.e. a previously created function_name).

Finally, the region that you specify should match your default region on your AWS account

##### Google

GCP differs from AWS in requiring a project which contains information such as the region. You will need to enter to the credentials file instead of a credentials directory. Otherwise you need to enter a function name and cloud bucket name as with AWS.

#### Optionally, change other start parameters

Of the parameters, for the demo you can keep all of them or modify them if you wish to change the path where the results will be stored. The /data directory in Bwb points to the directory that you started Bwb or /c:/users if you are using Windows. Just make sure that if you want to store things in a sub-directory of /data you change the entire set of paths to be consistent.

Remember that you need 130 GB of disk space to store all the fastq files and shards. If you do not have that much space you may want to quit Bwb by minimizing or closing the Bwb window (not the browser) and, right clicking inside the browser and choose the *QUIT container* option. Alternatively, you can stop the Bwb container from the command line.

#### Starting the workflow

Double-click on the blue *Start* widget in the lower right corner of the canvas.
Press the bluse *Start* button at the bottom left of the window that pops up to start the workflow.

You should immediately see the *Create bucket* and *Download data* widgets' states change to *Running*. If an error occurs - you can stop the widgets by double-clicking on them and clicking the stop button. Check out the [video](https://youtu.be/WHb_lQv3Y8Y) to see how the workflow should progress.
 
The *Download data* widget must download 46 GB of data so can take some time until it finishes depending on your internet connection. The *Split-and-upload* step will also depend on the internet connection as it needs to upload about 80 GB of data. On a cloud instance  these steps can take as little as 4 minutes and only need to be done the first time.

The *Align* widget can also take some time to start especially with Google which takes time to provide all the necessary serverless instances.

You can monitor the progress of any of the steps by double-clicking on the instance and choosing the *Console* tab.

Note that the *Align* console will not update until the process is finished. This is due to the way that the Python Futures library interacts with the logger process.

 When the workflow is completed, a spreadsheet window will pop up with the top-40 genes for the 15 experiments.

#### Reanalysis with different alignment parameters

First, if you want,  save the top 40 results using the spreadsheet menu to a file under the */data* mountpoint which will be a local directory. The stop the widget by pressing the stop button or by quitting the spreadsheet.

Then double click on *Cleanup* cloud widget. The *Delete cloud alignment files* box should be checked. Leave the other boxes unchecked and click on the *Start* button. 

When the cleanup is finished, double click on the *Align* widget and then choose the *Optional entries* tab to bring up all the options that can be modified. Once the parameters have been entered, click on the *Start* button to reanalyze the data. The reanalysis should be much faster than the original analysis as the fastq download, sharding and upload steps are not needed. 

If you have quit the workflow and just want to do the reanalysis part but need to have all the parameter fields populated. Click on the *Start* widget. Check off the *Test mode* box and then click on *Start*. This will run the workflow without actually starting the Docker containers but propagating all the parameter values.

Then click on the *Align* widget and uncheck the *Test mode* box. This will make all downstream widgets change to normal running mode when activated so now you can adjust the *Align* parameters and re-analyze the data

#### Cleanup
When you are finished, double-click on the *Cleanup cloud* widget to delete any or all resources created by the workflow.

Remember that closing the browser window does not quit the Bwb container. To do this you must close the Bwb window, right-click and then choose the *Quit container* option or quit the container from the command line.
