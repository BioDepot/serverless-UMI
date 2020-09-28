#lhhung 020420 modified aws version for google calls

from subprocess import call
from pathlib import Path
import sys
import os
from google.cloud import storage
from google.cloud import pubsub
import google.api_core.exceptions
import time
import datetime

# A utility function to run a bash command from python
def runCmd(cmd):
    print("#{}\n".format(cmd))
    call([cmd], shell=True)

#utilities to remove directories and files except those in the whitelist
def removeDirectoriesExcept(rootDirectory,whiteList):
    for directory in os.popen('find {} -type d -mindepth 1 -maxdepth 1 '.format(rootDirectory)).read().split('\n')[0:-1]:
        if directory not in whiteList:
            print("removing {}\n".format(directory))
            runCmd("rm {} -rf".format(directory))
            
def removeFilesExcept(rootDirectory,whiteList):
    for myFile in os.popen('find {} -type f '.format(rootDirectory)).read().split('\n')[0:-1]:
        if myFile not in whiteList:
            print("removing {}\n".format(myFile))
            try:
                os.remove(myFile)
            except Exception as e:
                print('unable to remove {}\n'.format(myFile))
                
def get_callback(f, data,futures):
    def callback(f):
        try:
            print(f.result())
            futures.pop(data)
        except:  # noqa
            sys.stderr.write("Invoke error for {} for {}\n".format(f.exception(), data))
    return callback

def publish(publisher,topic_path,data,splitFile,stage,error,futures):
    # When you publish a message, the client returns a future.
    future=publisher.publish(topic_path,data,splitFile=splitFile,stage=stage,error=error)
    future.add_done_callback(get_callback(future,splitFile,futures))

def waitOnMessages(futures):
    attempts=0
    maxAttempts=5
    while futures and attempts < maxAttempts:
        time.sleep(5)
        attempts=attempts+1;
        print ("waiting to publish messages attempt {}".format(attempts))
            
def downloadFiles(sourceFile,destFile,bucketName,maxAttempts=3,overwrite=True,verbose=True):
    bucket=storage.Client().get_bucket(bucketName)
    if overwrite or not os.path.exists(destFile):
        attempts=0
        while attempts < maxAttempts:
            try:
                if verbose:
                    print("Downloading {} to {}\n".format(sourceFile,destFile))
                blob = bucket.blob(sourceFile)
                blob.download_to_filename(destFile)
                return 0
            except google.api_core.exceptions.NotFound:
                print("Not found error downloading {} to {} retrying".format(sourceFile,destFile))
            attempts=attempts+1
        sys.stderr.write("Unable to download {} to {} retrying".format(sourceFile,destFile))
        raise

            
# Performs BWA for the given splitFile, filterCmd, and outputFile
def runBwa(splitFile,outputFile,filterCmd,bwa_string):
    cmdStr="/tmp/{} /tmp/refMrna_ERCC_polyAstrip.hg19.fa /tmp/{} | /tmp/bwa samse -n 20 /tmp/refMrna_ERCC_polyAstrip.hg19.fa - /tmp/{} | {} > {} ".format(bwa_string,splitFile,splitFile,filterCmd,outputFile)
    sys.stderr.write("running cmd:\n{}\n".format(cmdStr))
    runCmd(cmdStr)
def uploadResults(sourceFile,destFile,bucketName):
    bucket=storage.Client().get_bucket(bucketName)
    blob=bucket.blob(destFile)
    return blob.upload_from_filename(sourceFile) 
    
# entry point.
def gcp_handler(event, context):
    if 'attributes' not in event:
        sys.stderr.write("No attributes - aborted function\n")
        return
    try:
        bwa_string='bwa aln '
        futures={}
        #acknowledge that the message has been received 
        attributes=event['attributes']
        bucketName=attributes['bucketName']
        baseDirectory=attributes['baseDirectory']
        uploadDir=attributes['uploadDir']
        fullPathSplitFile=attributes['splitFile']
        recv_topic=attributes['recv']
        project_id=attributes['project_id']
        if 'bwa_string' in attributes:
            bwa_string=attributes['bwa_string']
        print("bwa_string={} bucketName={} baseDir={} uploadDir={} fullPathSplitFile={} recv_topic={} project_id={}".format(bwa_string,bucketName,baseDirectory,uploadDir,fullPathSplitFile,recv_topic,project_id))
        publisher = pubsub.PublisherClient()
        topic_path = publisher.topic_path(project_id, recv_topic)
        Path('/tmp/start').touch()
        splitFile=os.path.basename(fullPathSplitFile)
        uploadResults('/tmp/start',os.path.join(os.path.join(baseDirectory,"start"),splitFile),bucketName)
        publish(publisher,topic_path,b"0",splitFile,"start","",futures)
    except:
        sys.stderr.write("error start")
        publisher = pubsub.PublisherClient()
        topic_path = publisher.topic_path(project_id, recv_topic)
        publish(publisher,topic_path,b"0",splitFile,"start","1",futures)
        waitOnMessages(futures)
        return        
    
    ### These parameters can be changed for other datasets
        
    #bwa doesn't actually need the sequence information - just the name to figure out where the indices are
    #these files are empty to save space - probably should add the chrM.fa file 
    try:
        fakeFiles=['/tmp/Human_RefSeq/refMrna_ERCC_polyAstrip.hg19.fa']
        
        #sourceFiles and directories used in other places
        
        alignDir='/tmp/Aligns'
        refDir='/tmp/Human_RefSeq'
        barcodeFile="/tmp/barcodes_trugrade_96_set4.dat" #in References/BroadUMI directory
        erccFile="/tmp/ERCC92.fa"
        symToRefFile="/tmp/refGene.hg19.sym2ref.dat"
    
        
        
        sourceFiles= [baseDirectory+"/executables/umimerge_filter", 
                      baseDirectory+"/executables/bwa", 
                      baseDirectory+"/Broad_UMI/Human_RefSeq/chrM.fa", 
                      baseDirectory+"/Broad_UMI/barcodes_trugrade_96_set4.dat",
                      baseDirectory+"/Broad_UMI/ERCC92.fa" ,
                      baseDirectory+"/Broad_UMI/Human_RefSeq/refGene.hg19.sym2ref.dat", 
                      baseDirectory+"/Broad_UMI/Human_RefSeq/refGene.hg19.txt", 
                      baseDirectory+"/Broad_UMI/Human_RefSeq/refMrna_ERCC_polyAstrip.hg19.fa.amb", 
                      baseDirectory+"/Broad_UMI/Human_RefSeq/refMrna_ERCC_polyAstrip.hg19.fa.ann", 
                      baseDirectory+"/Broad_UMI/Human_RefSeq/refMrna_ERCC_polyAstrip.hg19.fa.bwt", 
                      baseDirectory+"/Broad_UMI/Human_RefSeq/refMrna_ERCC_polyAstrip.hg19.fa.fai", 
                      baseDirectory+"/Broad_UMI/Human_RefSeq/refMrna_ERCC_polyAstrip.hg19.fa.pac", 
                      baseDirectory+"/Broad_UMI/Human_RefSeq/refMrna_ERCC_polyAstrip.hg19.fa.sa"]
    
        ### End parameters specific for this dataset
        print("Running handler for splitFile [{}] at time {}\n"
            .format(
                splitFile,
                datetime.datetime.fromtimestamp(time.time()).strftime('%Y-%m-%d %H:%M:%S')
            )
        )
        #cleanup files - keep RefSeq and binaries if already there
        whiteListFiles=[]
        for sourceFile in sourceFiles:
            basesourceFile=os.path.basename(sourceFile)
            destFile='/tmp/'+basesourceFile
            whiteListFiles.append(destFile)
        whiteListFiles=whiteListFiles + fakeFiles
        
        removeDirectoriesExcept('/tmp',['/tmp/Human_RefSeq'])
        removeFilesExcept('/tmp',whiteListFiles)
    
        #create directories
        for directory in [alignDir,refDir]:
            runCmd('mkdir -p {}'.format(directory))
        
        #make empty fakeFiles
        for fakeFile in fakeFiles:
            if not os.path.exists(fakeFile):
                runCmd('touch {}'.format(fakeFile))
        
        #download source files
        for sourceFile in sourceFiles:
            basesourceFile=os.path.basename(sourceFile)
            destFile='/tmp/'+basesourceFile
            downloadFiles(sourceFile,destFile,bucketName,maxAttempts=3,overwrite=False,verbose=True)
    
        #download splitFile 
        downloadFiles(fullPathSplitFile,'/tmp/' + splitFile, bucketName,maxAttempts=3,overwrite=True,verbose=True)
    except:
        sys.stderr.write("error download")
        publish(publisher,topic_path,b"0",splitFile,"download","1",futures)
        waitOnMessages(futures)
        return
    try:
        #make sure that executables have correct permissions
        for executable in ('/tmp/bwa','/tmp/umimerge_filter'):
            runCmd('chmod +x {}'.format(executable))
       
        #run bwa 
        outputFile='{}/{}.saf'.format(alignDir,os.path.splitext(splitFile)[0])
        filterCmd="/tmp/umimerge_filter -s {} -b {} -e {}".format(symToRefFile,barcodeFile,erccFile)
        print("Starting bwa at {}".format(datetime.datetime.fromtimestamp(time.time()).strftime('%Y-%m-%d %H:%M:%S')))
        runBwa(splitFile,outputFile,filterCmd,bwa_string)
    except:
        sys.stderr.write("error align")
        publish(publisher,topic_path,b"0",splitFile,"align","1",futures)
        waitOnMessages(futures)
        return        

    #upload results
    try:
        uploadFile=uploadDir+'/'+os.path.basename(outputFile)
        uploadResults(outputFile,uploadFile,bucketName)
    except:
        sys.stderr.write("error upload")
        publish(publisher,topic_path,b"0",splitFile,"upload","1",futures)
        waitOnMessages(futures)          
    #write that it is done
    print("Finished at {}".format(datetime.datetime.fromtimestamp(time.time()).strftime('%Y-%m-%d %H:%M:%S')))
    publish(publisher,topic_path,b"0",splitFile,"finish","",futures)
    waitOnMessages(futures)



