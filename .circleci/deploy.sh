#!/bin/bash

set -e

WORKSPACE_FOLDER="$1"
if [ ! -d "$WORKSPACE_FOLDER" ]; then
    echo "Invalid workspace folder"
    exit 1
fi

if [ -f $WORKSPACE_FOLDER/model.txt ]; then
    MODEL=$(cat $WORKSPACE_FOLDER/model.txt)
fi
if [ -z "$MODEL" ]; then
    echo "Invalid model"
    exit 1
fi

if [ -f $WORKSPACE_FOLDER/version.txt ]; then
    VERSION=$(cat $WORKSPACE_FOLDER/version.txt)
fi
if [ -z "$VERSION" ]; then
    echo "Invalid version"
    exit 1
fi

if [ -f $WORKSPACE_FOLDER/deployment.txt ]; then
    DEPLOYMENT=$(cat $WORKSPACE_FOLDER/deployment.txt)
fi
if [ -z "$DEPLOYMENT" ]; then
    echo "Invalid deployment"
    exit 1
fi

ARTIFACT_FOLDER=$WORKSPACE_FOLDER/artifacts
if [ ! -d "$ARTIFACT_FOLDER" ]; then
    echo "No artifacts"
    exit 1
fi

S3_BUCKET="release.bnxcloud.com"
RELEASE_PREFIX="$MODEL/$DEPLOYMENT/$VERSION"

files=$(ls -1 $ARTIFACT_FOLDER)
for f in $files
do
    if [ -d $ARTIFACT_FOLDER/$f ]; then
        aws s3 cp --recursive "$ARTIFACT_FOLDER/$f" "s3://$S3_BUCKET/$RELEASE_PREFIX/" --acl public-read
    else
        aws s3 cp "$ARTIFACT_FOLDER/$f" "s3://$S3_BUCKET/$RELEASE_PREFIX/" --acl public-read
    fi
done
