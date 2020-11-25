#!/bin/bash
 
# MATLAB genpath no longer allows folders named 'resouces'
# but CNDA download uses 'resources' for the DICOM files
# rename them to 'dicom_files'

# run this in the top level

find . -depth -name resources -execdir mv {} dicom_files \;
