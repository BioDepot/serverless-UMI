import os
import glob
import sys
import functools
import jsonpickle
from collections import OrderedDict
from Orange.widgets import widget, gui, settings
import Orange.data
from Orange.data.io import FileFormat
from DockerClient import DockerClient
from BwBase import OWBwBWidget, ConnectionDict, BwbGuiElements, getIconName, getJsonName
from PyQt5 import QtWidgets, QtGui

class OWCleanup(OWBwBWidget):
    name = "Cleanup"
    description = "Setup and launch lambda functions  "
    priority = 10
    icon = getIconName(__file__,"Recycling_symbol2.svg.png")
    want_main_area = False
    docker_image_name = "biodepot/gcpclean"
    docker_image_tag = "277.0.0-alpine__a93c27bb"
    inputs = [("bucket_name",str,"handleInputsbucket_name"),("credentials_dir",str,"handleInputscredentials_dir"),("topic_name",str,"handleInputstopic_name"),("recv_topic",str,"handleInputsrecv_topic"),("function_name",str,"handleInputsfunction_name"),("work_dir",str,"handleInputswork_dir"),("Trigger",str,"handleInputsTrigger")]
    outputs = [("credentials_dir",str)]
    pset=functools.partial(settings.Setting,schema_only=True)
    runMode=pset(0)
    exportGraphics=pset(False)
    runTriggers=pset([])
    triggerReady=pset({})
    inputConnectionsStore=pset({})
    optionsChecked=pset({})
    bucket_name=pset("dtoxbucket")
    credentials_file=pset("/data/credentials.json")
    topic_name=pset("dtoxpubsub")
    recv_topic=pset("dtoxrecv")
    function_name=pset("dtoxfunction")
    work_dir=pset("test")
    dqueue=pset(False)
    dfunction=pset(False)
    dfiles=pset(False)
    dbucket=pset(False)
    def __init__(self):
        super().__init__(self.docker_image_name, self.docker_image_tag)
        with open(getJsonName(__file__,"Cleanup")) as f:
            self.data=jsonpickle.decode(f.read())
            f.close()
        self.initVolumes()
        self.inputConnections = ConnectionDict(self.inputConnectionsStore)
        self.drawGUI()
    def handleInputsbucket_name(self, value, *args):
        if args and len(args) > 0: 
            self.handleInputs("bucket_name", value, args[0][0], test=args[0][3])
        else:
            self.handleInputs("inputFile", value, None, False)
    def handleInputscredentials_dir(self, value, *args):
        if args and len(args) > 0: 
            self.handleInputs("credentials_dir", value, args[0][0], test=args[0][3])
        else:
            self.handleInputs("inputFile", value, None, False)
    def handleInputstopic_name(self, value, *args):
        if args and len(args) > 0: 
            self.handleInputs("topic_name", value, args[0][0], test=args[0][3])
        else:
            self.handleInputs("inputFile", value, None, False)
    def handleInputsrecv_topic(self, value, *args):
        if args and len(args) > 0: 
            self.handleInputs("recv_topic", value, args[0][0], test=args[0][3])
        else:
            self.handleInputs("inputFile", value, None, False)
    def handleInputsfunction_name(self, value, *args):
        if args and len(args) > 0: 
            self.handleInputs("function_name", value, args[0][0], test=args[0][3])
        else:
            self.handleInputs("inputFile", value, None, False)
    def handleInputswork_dir(self, value, *args):
        if args and len(args) > 0: 
            self.handleInputs("work_dir", value, args[0][0], test=args[0][3])
        else:
            self.handleInputs("inputFile", value, None, False)
    def handleInputsTrigger(self, value, *args):
        if args and len(args) > 0: 
            self.handleInputs("Trigger", value, args[0][0], test=args[0][3])
        else:
            self.handleInputs("inputFile", value, None, False)
    def handleOutputs(self):
        outputValue=None
        if hasattr(self,"credentials_dir"):
            outputValue=getattr(self,"credentials_dir")
        self.send("credentials_dir", outputValue)
