#!/bin/bash

function deleteSub () {
	topic=$1
	subs=($(gcloud pubsub topics list-subscriptions ${topic} | sed -e 's/---//' | sed -e 's/^[ \t\n\r]*//'))
	for sub in ${subs[@]}; do
		echo "gcloud pubsub subscriptions delete $sub"
		gcloud pubsub subscriptions delete $sub
	done
}

confirmationFile=$1
project_id=$(jq -r '.project_id' $confirmationFile)
gcloud config set project $project_id
echo "gcloud auth activate-service-account --key-file=$confirmationFile"
gcloud auth activate-service-account --key-file=$confirmationFile

if [[ $DELETE_FUNCTION ]]; then
	echo "deleting function $FUNCTION_NAME"
	gcloud functions delete --quiet $FUNCTION_NAME || echo "unable to delete $FUNCTION_NAME"
fi
if [[ $DELETE_QUEUE ]]; then
	echo "deleting pubsub subscriptions"
	deleteSub $TOPIC
	deleteSub $RTOPIC
	echo "deleting pubsub topics"
	gcloud pubsub topics delete $TOPIC || echo "unable to delete $TOPIC "
	gcloud pubsub topics delete $RTOPIC  || echo "unable to delete $RTOPIC "
	
fi
if [[ $DELETE_BUCKET ]]; then
	echo "deleting bucket $BUCKET_NAME"
	
	gsutil -m rm -r gs://$BUCKET_NAME || echo "unable to rm $BUCKET_NAME"
elif [[ $DELETE_FILES ]]; then
	echo "deleting cloud files"
    gsutil -m rm -r gs://$BUCKET_NAME/$WORK_DIR || echo "unable to rm $BUCKET_NAME/$WORK_DIR"
fi

