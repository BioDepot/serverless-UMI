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

##### Warning: 130 GB of disk space are needed to run the workflow

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

#### Optionally, change other start parameters

Of the parameters, for the demo you can keep all of them or modify them if you wish to change the path where the results will be stored. The /data directory in Bwb points to the directory that you started Bwb or /c:/users if you are using Windows. Just make sure that if you want to store things in a sub-directory of /data you change the entire set of paths to be consistent.

Remember that you need 130 GB of disk space to store all the fastq files and shards. If you do not have that much space in your current directory. Then quit Bwb by following the instructions here <-- add link.

#### Starting the workflow

Press start button at the bottom of the start icon to start the workflow.

You should immediately see the Create-storage, Download-data and widgets' states change to Running. If an error occurs - you can stop the widgets by double-clicking on them and clicking the stop button.

The Create-widget should finish in less than a minute and then the Split-and-upload widget will start running.
 
The Download-data widget must download 46GB of data so can take some time until it finishes depending on your internet connection. The Split-and-upload step will also depend on the internet connection as it needs to upload about 80 GB of data. On a cloud instance  these steps can take as little as 4 minutes and only need to be done the first time.

The Align step can also take some time to 

 When the workflow is completed, a spreadsheet window will pop up with the top-40 genes for the 15 experiments.

#### Reanalysis with different alignment parameters

First, if you want,  save the top 40 results using the spreadsheet menu to a file under the /data mountpoint which will be a local directory. The stop the widget by pressing the stop button or by quitting the spreadsheet.

Then double click on Cleanup cloud widget. The "Delete cloud alignment files" box should be checked. Leave the other boxes unchecked and click on the Start button. 

When the cleanup is finished, double doubleclick on the Align widget and then choose the Optional entries tab to bring up all the options that can be modified. Once the parameters have been entered, click on the start button to reanalyze the data. The reanalysis should be much faster than the original analysis as the fastq download, sharding and upload steps are not needed. 

#### Cleanup
When you are finished, double-click on the Cleanup cloud icon to delete any or all resources created by the workflow.
