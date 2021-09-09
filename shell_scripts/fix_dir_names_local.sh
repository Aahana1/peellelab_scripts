#!/bin/sh

# unzip of downloaded CNDA files creates unusable session folder names
# in the form NN-blerg (e.g., 7-T1w_MPR). Run this from on top of
# the directory tree to fix (e.g., cd to PL123346/scans)


for FILE in * 
do
   if [ -d ${FILE} ]; then
      NEWNAME=`echo ${FILE} | cut -d- -f 1`
      mv -v "${FILE}" "${NEWNAME}"
   fi
done
