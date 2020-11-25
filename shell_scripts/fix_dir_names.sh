#!/bin/sh

# unzip of downloaded CNDA files creates unusable session folder names
# in the form NN-blerg (e.g., 7-T1w_MPR). Run this from on top of
# the directory tree to fix (e.g., change 7-T1w_MPR to 7). You
# must pass in the CNDA downlist file: fix_dir_names.sh <CNDAlist>
#
# There is also a version fix_dir_names_local.sh that can be
# run in each directory that does not require the CNDA list

INPUT_FILE=$1
CURR_DIR=`pwd`

while read SID SESS T1 T2
do

  DATADIR=${CURR_DIR}/${SID}_${SESS}/scans
#   DATADIR=${CURR_DIR}/${SID}/scans

echo ${DATADIR}

   if [ -d ${DATADIR} ]; then

      cd ${DATADIR}

      for FILE in * 
      do
         if [ -d ${FILE} ]; then
            NEWNAME=`echo ${FILE} | cut -d- -f 1`
            mv -v "${FILE}" "${NEWNAME}"
         fi
      done

   fi

done < $INPUT_FILE

cd ${CURR_DIR}
