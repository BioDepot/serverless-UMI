#!/bin/bash

printenv
#echo "/$NWELLS/umisplit $@ &"
#remove any remaining done files
if [ -z "$OUTPUTDIR" ]; then
   exit 1
fi
rm ${OUTPUTDIR}/*.done
rm ${OUTPUTDIR}/*/*

/$NWELLS/umisplit $@ &
echo "runUploadSplitFiles.sh $CREDENTIALS $OUTPUTDIR $NFILES gs://${BUCKET}/${CLOUD_DIR}/ $UPLOAD_THREADS $UPLOAD_THREADS_AFTER"
runUploadSplitFiles.sh $CREDENTIALS $OUTPUTDIR $NFILES gs://${BUCKET}/${CLOUD_DIR}/ $UPLOAD_THREADS $UPLOAD_THREADS_AFTER
