#!/bin/bash

# ------------------------------------------------------------------------
# Copyright 2018 WSO2, Inc. (http://wso2.com)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License
# ------------------------------------------------------------------------

# This script builds a zipped file of a WSO2 WUM supported product after applying the followings.
# If INITIAL_RUN,
#     1. WUM update.
#     2. Apply custom configurations using a configuration management tool like Ansible or Puppet.
#     3. Copy the artifact(s) to the location(s).
#     4. Run the in-place updates tool.
# If not the INITIAL_RUN,
#     1. Apply custom configurations using a configuration management tool like Ansible or Puppet.
#     2. Copy the artifact(s) to the location(s).
#     3. Run the in-place updates tool.
#
# Prerequisites
#   1. WUM 3.0.1 installed
#   2. Puppet 5.4.1 or higher installed
#   3. Puppet module configurations under the directory $working_directory/configs/modules/
#
# TODO: Add git support to clone the PUPPET modules

PRODUCT=${PRODUCT}
PRODUCT_VERSION=${VERSION}
CHANNEL="full"
INITIAL_RUN=false
CONF_LOCATION="${PUPPET_CONF_LOC}"
ARTIFACT_LOCATION=${ARTIFACT_LOC}
WORKING_DIRECTORY=$(pwd)
MODULE_PATH="${PUPPET_CONF_LOC}/modules"
ZIP_OUTPUT_LOCATION=${ZIP_OUTPUT_LOC}
DEPLOYMENT_PATTERN=${DEPLOYMENT_PATTERN}
PACK_DIRECTORY=${DEPLOYMENT_PATTERN}
WUM_UPDATE=true
WUM_USER=${WUM_USERNAME}
WUM_PASSWORD=${WUM_PASSWORD}
WUM_PRODUCT_HOME="${WUM_HOME}"
WUM=`which wum`
CP=`which cp`
MV=`which mv`
RM=`which rm`
UNZIP=`which unzip`
ZIP=`which zip`
PUPPET=`which puppet`
FAILED_WUM_UPDATE=10
FAILED_WUM_ADD=11
FAILED_INPLACE_UPDATES=12
FAILED_PUPPET_APPLY=13
FAILED_TO_MOVE_WUMMED_PRODUCT=14
FAILED_UNZIP=15
FAILED_RM_UNZIP=16
FAILED_ARTIFACT_APPLY=17
FAILED_WUM_INIT=18
FAILED_DOWNLOAD_PACK=19
FAILED_DOWNLOAD_PATCH_FILE=20

#Specify deployment directory
if [ ${PRODUCT} = "wso2ei" ] ; then
    PACK_DIRECTORY="ei"
else
    if [ ${PRODUCT} = "wso2is" ] ; then
        PACK_DIRECTORY="is"
    fi
fi

#init WUM
if [ -z  "$WUM_USER" ]; then
    WUM_UPDATE=false
else
    ${WUM} init -u ${WUM_USER} -p ${WUM_PASSWORD} -v &>> wum.log
    if [ $? -eq 1 ] ; then
        exit ${FAILED_WUM_INIT}
    fi
fi

if [ -d "${WORKING_DIRECTORY}/${PACK_DIRECTORY}/" ]; then
   echo "Applying artifact(s) to the existing deployment pattern >> $DEPLOYMENT_PATTERN..."
else
   echo "Initial Run..."
   INITIAL_RUN=true
   mkdir ${WORKING_DIRECTORY}/${PACK_DIRECTORY}/
fi

if $INITIAL_RUN; then
    if $WUM_UPDATE; then
        # Add WUM product
        echo "Adding the product - ${PRODUCT}-${PRODUCT_VERSION}..." &>> wum.log
        ${WUM} add ${PRODUCT}-${PRODUCT_VERSION} -y  -v &>> wum.log
        if [ $? -eq 0 ] ; then
            echo "${PRODUCT}-${PRODUCT_VERSION} successfully added..." &>> wum.log
        else
            if [ $? -ne 1 ] ; then
                exit ${FAILED_WUM_ADD}
            fi
        fi

        # Get the updates
        echo "Get latest updates for the product - ${PRODUCT}-${PRODUCT_VERSION}..." &>> wum.log
        ${WUM} update ${PRODUCT}-${PRODUCT_VERSION} ${CHANNEL} &>> wum.log
        if [ $? -eq 0 ] ; then
            echo "${PRODUCT}-${PRODUCT_VERSION} successfully updated..." &>> wum.log
        else
            if [ $? -eq 1 ] ; then
                exit ${FAILED_WUM_UPDATE}
            fi
        fi

        # Move the WUM updated product
        echo "Moving the WUM updated product ${PRODUCT}-${PRODUCT_VERSION}..." &>> wum.log
        ${MV} ${WUM_PRODUCT_HOME}/${PRODUCT}/${PRODUCT_VERSION}/${CHANNEL}/${PRODUCT}-${PRODUCT_VERSION}*.zip ${WORKING_DIRECTORY}/${PACK_DIRECTORY}/${PRODUCT}-${PRODUCT_VERSION}.zip
        if [ $? -ne 0 ] ; then
          echo "Failed to move the WUM updated product from ${WUM_PRODUCT_HOME}/${PRODUCT}/${PRODUCT_VERSION}/${CHANNEL} to ${WORKING_DIRECTORY}/${PACK_DIRECTORY}..."
          exit ${FAILED_TO_MOVE_WUMMED_PRODUCT}
        fi
    fi
    if ! $WUM_UPDATE; then
        # Download the product pack from S3 bucket
        echo "Download the GA pack from S3 bucket..." &>> wum.log
        wget https://s3.amazonaws.com/aws-cicd-product-packs/${PRODUCT}-${PRODUCT_VERSION}.zip -P ${WORKING_DIRECTORY}/${PACK_DIRECTORY}/
        if [ $? -eq 1 ] ; then
            exit ${FAILED_DOWNLOAD_PACK}
        fi
    fi

    # Unzip the product pack
    echo "Unzip the product pack..." &>> wum.log
    ${UNZIP} -q ${WORKING_DIRECTORY}/${PACK_DIRECTORY}/${PRODUCT}-${PRODUCT_VERSION}.zip -d ${WORKING_DIRECTORY}/${PACK_DIRECTORY}/
    if [ $? -ne 0 ] ; then
        echo "Failed to unzip the product pack ${PRODUCT}-${PRODUCT_VERSION}..."
        exit ${FAILED_UNZIP}
    fi
    echo "Remove the zipped product..." &>> wum.log
    ${RM} ${WORKING_DIRECTORY}/${PACK_DIRECTORY}/${PRODUCT}-${PRODUCT_VERSION}.zip
    if [ $? -ne 0 ] ; then
        echo "Failed to remove the zipped product ${PRODUCT}-${PRODUCT_VERSION}..."
        exit ${FAILED_RM_UNZIP}
    fi

    # Download the patch file for clustering
    echo "Download the patch file from S3 bucket..." &>> wum.log
    wget https://wso2-patches.s3-us-west-2.amazonaws.com/patch9999.zip -P ${WORKING_DIRECTORY}/${PACK_DIRECTORY}/${PRODUCT}-${PRODUCT_VERSION}/patches/
    if [ $? -eq 1 ] ; then
            exit ${FAILED_DOWNLOAD_PATCH_FILE}
    fi

    # Unzip the patch file
    echo "Unzip the patch file..." &>> wum.log
    ${UNZIP} -q ${WORKING_DIRECTORY}/${PACK_DIRECTORY}/${PRODUCT}-${PRODUCT_VERSION}/patches/patch9999.zip -d ${WORKING_DIRECTORY}/${PACK_DIRECTORY}/${PRODUCT}-${PRODUCT_VERSION}/patches/
    if [ $? -ne 0 ] ; then
        echo "Failed to unzip the patch file patch9999.zip..."
        exit ${FAILED_UNZIP}
    fi
    echo "Remove the zipped patch file..." &>> wum.log
    ${RM} ${WORKING_DIRECTORY}/${PACK_DIRECTORY}/${PRODUCT}-${PRODUCT_VERSION}/patches/patch9999.zip
    if [ $? -ne 0 ] ; then
        echo "Failed to remove the zipped patch file patch9999.zip..."
        exit ${FAILED_RM_UNZIP}
    fi
fi

echo "Applying Puppet modules..."
puppet apply -e "include ${PACK_DIRECTORY}" --modulepath=${MODULE_PATH}
if [ $? -ne 0 ] ; then
  echo "Failed to apply Puppet for ${PRODUCT}-${PRODUCT_VERSION}..."
  exit ${FAILED_PUPPET_APPLY}
fi

if ! $INITIAL_RUN; then
    if $WUM_UPDATE; then
        echo "Running the in-place updates tool..."
        ${WORKING_DIRECTORY}/${PACK_DIRECTORY}/${PRODUCT}-${PRODUCT_VERSION}/bin/update_linux -u ${WUM_USER} -p ${WUM_PASSWORD} -c ${CHANNEL} 2>&1 | tee inplace.log
        cat inplace.log | grep "Merging configurations failed."
        if [ $? -eq 0 ] ; then
            echo "Failed to execute in-place updates for ${PRODUCT}-${PRODUCT_VERSION}. Merging configurations failed..."
            exit ${FAILED_INPLACE_UPDATES}
        fi
        echo "In-place update successfully executed for ${PRODUCT}-${PRODUCT_VERSION}..."
        ${RM} inplace.log
    fi
fi

#Create the zipped folder
echo "Creating the archive for ${PRODUCT}-${PRODUCT_VERSION}..."
cd ${WORKING_DIRECTORY}/${PACK_DIRECTORY}/
${ZIP} -q -r ${PRODUCT}-${PRODUCT_VERSION}.zip ${PRODUCT}-${PRODUCT_VERSION}/*
${MV} ${PRODUCT}-${PRODUCT_VERSION}.zip ${ZIP_OUTPUT_LOCATION}/
