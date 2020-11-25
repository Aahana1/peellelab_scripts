#!/bin/bash
 
USER=jonesm
INPUT_FILE=NAM_datastamp.txt
SITE=https://cnda.wustl.edu
MAXFILE=10000
PROJECT=NP1014

# -s option avoids confusing echo here
JSESSION=`curl -s -u ${USER} "${SITE}/data/JSESSION"`
 
let i=0
while [ $i -lt $MAXFILE ] && read SID SESS SCANS 
do
    if [ ! -f ./${SID}_${SESS}.zip ]; then
      let i=$i+1
      # convert scan numbers to comma separated values
      SCANS=`echo ${SCANS} | tr -s ' ' ','`
      echo Downloading ${SID}
      curl -b JSESSIONID=${JSESSION} "https://cnda.wustl.edu/data/projects/${PROJECT}/subjects/${SID}/experiments/${SID}_${SESS}/scans/${SCANS}/resources/DICOM/files?format=zip" > ./${SID}_${SESS}.zip
    else
       echo "${SID}_${SESS}.zip exists"
    fi
done < $INPUT_FILE
 
