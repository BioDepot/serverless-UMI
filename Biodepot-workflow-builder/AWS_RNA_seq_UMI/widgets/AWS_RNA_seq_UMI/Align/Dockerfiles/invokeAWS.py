#!/usr/bin/python3
#lhhung 013119 - cleaned up code from Dimitar Kumar
#lhhung 031019 - added timing code
#lhhung 121119 - added and modified code from XingZhi Nui using pubsub
import os
import sys
import json
import glob
import boto3
import threading
import re
import pathlib
import datetime,time, subprocess
import os
from timeit import default_timer as timer
from dateutil.parser import *
import concurrent.futures

#globals to determine when functions have started and finished
gfunctionStartTimes={}
gfunctionFinishTimes={}
gmessagePublished={}
gErrors={}
gsplitFileSeen={}

def publish(snsClient,topicId,attr):
    snsClient.publish(TopicArn=topicId,Message='start',MessageAttributes=attr)
        
def findUnPublishedMessages(splitFiles):
    output=[]
    for splitFile in splitFiles:
        if splitFile not in gmessagePublished:
            output.append(splitFile)
    return output

def clearDirectoryFiles(bucket,directory):
    directory=os.path.normpath(directory+"/")
    command="aws s3 rm s3://{}/{} --recursive ".format(bucket,directory)
    
def getDirectoryFiles(bucket,directory,suffix=None):
    #make sure that the directory has no double slash
    directory=os.path.normpath(directory)
    #check that directory exists
    directory_command="aws s3 ls s3://{}/{} ".format(bucket,directory)
    try:
        output=subprocess.check_output(directory_command, shell=True)
        if not output:
            return []
    except subprocess.CalledProcessError:
        return []
    if suffix:
        command="aws s3 ls s3://{}/{}/ --recursive | tr -s ' ' | cut -d ' ' -f 4 | grep '.*{}$'".format(bucket,directory,suffix)
    #    sys.stderr.write("getDirectoryFiles command is: {}\n".format(command))
    else:
        #grep gets rid of empty space because of header that aws inserts
        #recursive does not need trailing slash
        command="aws s3 ls s3://{}/{}/ --recursive | tr -s ' ' | cut -d ' ' -f 4 | grep -v '^[[:space:]]*$' ".format(bucket,directory)
    #    sys.stderr.write("getDirectoryFiles command is: {}\n".format(command))
    output=subprocess.check_output(command, shell=True)
    if output:
        return (output.decode()).splitlines()
    return []
    
def getBaseDirectoryFiles(bucket,directory,suffix=None):
    files=getDirectoryFiles(bucket,directory,suffix)
    baseFiles=[]
    if files:
        for myfile in files:
            baseFiles.append(os.path.basename(myfile))
    return baseFiles
            
def checkFinishFile(splitFile,baseFinishFiles):
    splitStem=pathlib.Path(splitFile).stem
    safFile=splitStem+".saf"
    return (safFile in baseFinishFiles)

def checkFinishFiles(splitFiles,baseFinishFiles):
    for splitFile in splitFiles:
        if not checkFinishFile(splitFile,baseFinishFiles):
            return False

def checkAllFunctionsStarted(splitFiles,bucketName,startDir,finishDir):
    startFiles=getBaseDirectoryFiles(bucketName,startDir)
    finishFiles=getBaseDirectoryFiles(bucketName,finishDir)
    for splitFile in splitFiles:
        baseSplitFile=os.path.basename(splitFile)
        if splitFile not in gsplitFileSeen and baseSplitFile not in startFiles and not checkFinishFile(baseSplitFile,finishFiles):
            return False
    return True
    
def checkAllFunctionsFinished(splitFiles,bucketName,finishDir):
    finishFiles=getBaseDirectoryFiles(bucketName,finishDir)
    for splitFile in splitFiles:
        baseSplitFile=os.path.basename(splitFile)
        if splitFile not in gfunctionFinishTimes and not checkFinishFile(baseSplitFile,finishFiles):
            return False
    return True
    
def checkAllResultsTransferred(splitFiles,bucketName,finishDir):
    finishFiles=getBaseDirectoryFiles(bucketName,finishDir)
    for splitFile in splitFiles:
        baseSplitFile=os.path.basename(splitFile)
        if not checkFinishFile(baseSplitFile,finishFiles):
            return False
    return True

def listFunctionsNotStarted(splitFiles,bucketName,startDir,finishDir,verbose=False):
    startFiles=getBaseDirectoryFiles(bucketName,startDir)
    finishFiles=getBaseDirectoryFiles(bucketName,finishDir)
    nStarted=0
    unStartedFiles=[]
    for splitFile in splitFiles:
        baseSplitFile=os.path.basename(splitFile)
        if splitFile not in gsplitFileSeen and baseSplitFile not in startFiles and not checkFinishFile(baseSplitFile,finishFiles):
            if verbose:
                sys.stderr.write("{} not started\n".format(splitFile))
            unStartedFiles.append(splitFile)
        else:
            nStarted=nStarted+1
    sys.stderr.write("{} of {} functions started\n".format(nStarted,len(splitFiles)))
    return unStartedFiles

def listFunctionsNotFinished(splitFiles,bucketName,startDir,finishDir,verbose=False):
    finishFiles=getBaseDirectoryFiles(bucketName,finishDir)
    nFinished=0
    unFinishedFiles=[]
    if verbose:
        startFiles=getBaseDirectoryFiles(bucketName,startDir)
    for splitFile in splitFiles:
        baseSplitFile=os.path.basename(splitFile)
        if splitFile not in gfunctionFinishTimes and not checkFinishFile(baseSplitFile,finishFiles):
            if verbose:
                sys.stderr.write("{} not finished\n".format(splitFile))
            unFinishedFiles.append(splitFile)
        else:
            if verbose:
                sys.stderr.write("{} ".format(splitFile))
                if splitFile in gsplitFileSeen:
                    sys.stderr.write("seen ")
                if baseSplitFile in startFiles:
                    sys.stderr.write("started ")
                if checkFinishFile(baseSplitFile,finishFiles):
                    sys.stderr.write("finished ")
                if splitFile in gfunctionFinishTimes:
                    sys.stderr.write("finish Time ")
                sys.stderr.write("\n")
            nFinished=nFinished+1
    sys.stderr.write("{} of {} functions finished\n".format(nFinished,len(splitFiles)))   
    return unFinishedFiles
    
def listFunctionsNotTransferred(splitFiles,bucketName,startDir,finishDir,verbose=False):
    finishFiles=getBaseDirectoryFiles(bucketName,finishDir)
    if verbose:
        startFiles=getBaseDirectoryFiles(bucketName,startDir)
    nFinished=0
    unFinishedFiles=[]
    for splitFile in splitFiles:
        baseSplitFile=os.path.basename(splitFile)
        if not checkFinishFile(baseSplitFile,finishFiles):
            if verbose:
                sys.stderr.write("{} not transferred\n".format(splitFile))
            unFinishedFiles.append(splitFile)
        else:
            if verbose:
                sys.stderr.write("{} ".format(splitFile))
                if splitFile in gsplitFileSeen:
                    sys.stderr.write("seen ")
                if baseSplitFile in startFiles:
                    sys.stderr.write("started ")
                if checkFinishFile(baseSplitFile,finishFiles):
                    sys.stderr.write("finished ")
                if splitFile in gfunctionFinishTimes:
                    sys.stderr.write("finish Time ")
                sys.stderr.write("\n")
            nFinished=nFinished+1
    sys.stderr.write("{} of {} results transferred \n".format(nFinished,len(splitFiles)))   
    return unFinishedFiles

def checkMessagesInQueue(sqsclient,subscription_name,interval=1,maxMessages=10):
    response=sqsclient.receive_message(QueueUrl=subscription_name,MessageAttributeNames=[],MaxNumberOfMessages=maxMessages)
    if "Messages" in response:
        delete_messages=[]
        for msg in response["Messages"]:
            msgBody=json.loads(msg["Body"])
            filename=msgBody["MessageAttributes"]["filename"]["Value"]
            Id=msg["MessageId"]
            handle=msg["ReceiptHandle"]
            message=msgBody["Message"]
            timestamp=msgBody["Timestamp"]
            if message == "Start":
                gfunctionStartTimes[filename]=parse(timestamp)
                gsplitFileSeen[filename]=True
            elif message == "Finish":
                gfunctionFinishTimes[filename]=parse(timestamp)
                gsplitFileSeen[filename]=True
            elif message and isinstance(message,str) and message[0:5] == "Error":
                gErrors[filename] = message
            delete_messages.append({
                'Id': Id,
                'ReceiptHandle': handle
            })
        if delete_messages:
            delete_response = sqsclient.delete_message_batch(
                QueueUrl=subscription_name,
                Entries=delete_messages
            )
        return True
    else:
        #sys.stderr.write("queue is empty\n")
        return False
    
def waitOnFunctions(splitFiles,bucket,startDir,finishDir,sqsclient,subscription_name,interval=1,startTimeout=20,finishTimeout=100):
    waitStartTime=timer()
    unFinishedFiles=[]
    while (not checkAllFunctionsStarted(splitFiles,bucket,startDir,finishDir) and (timer()-waitStartTime) <startTimeout):
        while checkMessagesInQueue(sqsclient,subscription_name,interval=1,maxMessages=10):
            pass
        time.sleep(1)
    if checkAllFunctionsStarted(splitFiles,bucket,startDir,finishDir):
        sys.stderr.write("{} to start all {} functions\n".format(timer()-waitStartTime,len(splitFiles)))
    else:
        listFunctionsNotStarted(splitFiles,bucket,startDir,finishDir,verbose=False)
    while (not checkAllFunctionsFinished(splitFiles,bucket,finishDir)):
        while checkMessagesInQueue(sqsclient,subscription_name,interval=1,maxMessages=10):
            pass
        time.sleep(1)
    if checkAllFunctionsFinished(splitFiles,bucket,finishDir):
        sys.stderr.write("{} to finish all {} functions\n".format(timer()-waitStartTime,len(splitFiles)))
    else:
        unFinishedFiles=listFunctionsNotFinished(splitFiles,bucket,startDir,finishDir,verbose=False)
    return unFinishedFiles

def getSplitFilenames(bucket,baseDir,suffix):
    return getDirectoryFiles(bucket,baseDir,suffix)

def startInvoke(baseDir,splitFiles,bucket,topicId,recv_topic,uploadDir,startTimes,region,max_workers,bwa_string):
    attrList=[]
    fullUploadDir=baseDir+'/'+uploadDir
    snsClient = boto3.client('sns',region_name=str(region))
    for splitFile in splitFiles:
        attrList.append({'uploadDir':{'DataType':'String','StringValue':fullUploadDir},'bwa_string':{'DataType':'String','StringValue':bwa_string},'splitFile':{'DataType':'String','StringValue':splitFile},'bucketName':{'DataType':'String','StringValue':bucket},'baseDirectory':{'DataType':'String','StringValue':baseDir},'topicArn':{'DataType':'String','StringValue':recv_topic}})
    with concurrent.futures.ThreadPoolExecutor(max_workers=max_workers) as executor:
        future_submissions={executor.submit(lambda attr: publish(snsClient, topicId, attr), attr): attr for attr in attrList}

def getFullSubscriptionName(subscription_name):
    arntokens=subscription_name.split(":")
    return "https://sqs.%s.amazonaws.com/%s/%s"%(arntokens[3],arntokens[4],arntokens[5])
        
def invokeFunctions (bucket,topicId,work_dir,cloud_aligns_dir,recv_topic,suffix,uploadDir,subscription_name,region,align_timeout,start_timeout,finish_timeout,max_workers=16,bwa_string=None):
    sys.stderr.write("bucket is {}\n".format(bucket))
    sys.stderr.write("topicId is {}\n".format(topicId))
    sys.stderr.write("work_dir is {}\n".format(work_dir))
    sys.stderr.write("cloud_aligns_dir is {}\n".format(cloud_aligns_dir))
    sys.stderr.write("recv_topic is {}\n".format(recv_topic))
    sys.stderr.write("suffix is {}\n".format(suffix))
    sys.stderr.write("uploadDir is {}\n".format(uploadDir))            
    sys.stderr.write("subscription_name is {}\n".format(subscription_name))
    sys.stderr.write("region is {}\n".format(region))
    sys.stderr.write("align_timeout is {}\n".format(align_timeout))
    sys.stderr.write("start_timeout is {}\n".format(start_timeout))
    sys.stderr.write("finish_timeout is {}\n".format(finish_timeout))
    sys.stderr.write("bwa_string is {}\n".format(bwa_string))
    finishTimes={}
    startTimes={}
    sqsclient=boto3.client('sqs',region_name=str(region))
    splitFiles=getSplitFilenames(bucket,cloud_aligns_dir,suffix)
    start = timer()
    alignAttempts=0
    maxAlignAttempts=2
    remainingSplitFiles=splitFiles
    startDir=os.path.join(work_dir,"start")
    finishDir=os.path.join(work_dir,uploadDir)
    clearDirectoryFiles(bucket,startDir)
    clearDirectoryFiles(bucket,finishDir)
    while remainingSplitFiles and alignAttempts < maxAlignAttempts:
        startInvoke(work_dir,splitFiles,bucket,topicId,recv_topic,uploadDir,startTimes,region,max_workers,bwa_string)    
        sys.stderr.write('Time elapsed for launch is {}\n'.format(timer()-start))
        fullSubscriptionName=getFullSubscriptionName(subscription_name)
        remainingSplitFiles=waitOnFunctions(remainingSplitFiles,bucket,startDir,finishDir,sqsclient,fullSubscriptionName,startTimeout=start_timeout,finishTimeout=finish_timeout)
        alignAttempts=alignAttempts+1
    #It is possible to finish but not have the files finish transferring
    while (not checkAllResultsTransferred(splitFiles,bucket,finishDir) and (timer()-start) < align_timeout):
        time.sleep(1)
    if not checkAllResultsTransferred(splitFiles,bucket,finishDir):
        listFunctionsNotTransferred(splitFiles,bucket,startDir,finishDir)
        gErrors['Transfer']="True"
    else:
        sys.stderr.write("{} to write all {} result files\n".format(timer()-start,len(splitFiles)))
    for splitFile in splitFiles:
        if splitFile in gfunctionStartTimes and splitFile in gfunctionFinishTimes:
            sys.stderr.write("{} {} {} {}\n".format(splitFile,gfunctionStartTimes[splitFile],gfunctionFinishTimes[splitFile],gfunctionFinishTimes[splitFile]-gfunctionStartTimes[splitFile]))
    for remainingSplitFile in remainingSplitFiles:
        sys.stderr.write("Did not finish {}\n".format(remainingSplitFile))
    for splitFile in splitFiles:
        if splitFile in gErrors:
            sys.stderr.write("Error for {} - {}\n".format(splitFile,gErrors['splitFile']))
    if gErrors:
        sys.stderr.write("errors {}\n".format(gErrors))
        raise Exception ("Errors detected during the alignment phase")
    
if __name__ == "__main__":
    if len(sys.argv) != 14 :
        exit(0)
    bucket=sys.argv[1]
    topicId=sys.argv[2]
    work_dir=sys.argv[3]
    cloud_aligns_dir=argv[4]
    recv_topic=sys.argv[5]
    suffix=sys.argv[6]
    uploadDir=sys.argv[7]
    subscription_name=sys.argv[8]
    max_workers=sys.argv[9]
    region=sys.argv[10]
    align_timeout=argv[11]
    start_timeout=argv[12]
    finish_timeout=argv[13]
    bwa_string=argv[14]
    
    
    invokeFunctions(bucket,topicId,work_dir,cloud_aligns_dir,recv_topic,suffix,uploadDir,subscription_name,region,align_timeout,start_timeout,finish_timeout,max_workers=max_workers,bwa_string=bwa_string)