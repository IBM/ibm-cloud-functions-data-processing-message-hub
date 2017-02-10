#!/bin/bash

##############################################################################
# Copyright 2015-2017 IBM Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
##############################################################################

# This prevents running the script if any of the variables have not been set
set -o nounset

source env.sh
source secret.sh

cleanup() {
    echo_my "Cleanup...\n"
 	wsk rule delete --disable ${RULE}
	wsk trigger delete ${TRIGGER}
	wsk action delete ${SEQUENCE}
	wsk action delete ${GET_ACTION}
	wsk action delete ${PKG}/${POST_ACTION}
	wsk package delete ${PKG_TARGET}
	wsk package delete ${PKG}
    echo_my "<--- Cleanup complete\n"
}

###################################################
# MAIN
###################################################
echo_my "Set OpenWhisk authentication property...\n"
wsk property set --apihost openwhisk.ng.bluemix.net --auth ${OW_AUTH_KEY}
cleanup

echo_my "Refresing OpenWhisk packages...\n"
wsk package refresh

############################# PACKAGES
echo_my "Creating $PKG package...\n"
wsk package create ${PKG} || die

############################# ACTIONS
# Package the rule for deployment
echo_my "Zipping up actions...\n"
DIR=`pwd`
ZIP=mhpost.zip
ZIP_PATH=./actions/mhpost
cd ${ZIP_PATH}
zip -r ${ZIP} * || die
cd ${DIR}

echo_my "Creating $GET_ACTION action...\n"
wsk action create ${GET_ACTION} actions/mhget/mhget.js || die

echo_my "Creating $POST_ACTION action...\n"
wsk action create ${PKG}/${POST_ACTION} ${ZIP_PATH}/${ZIP} --kind nodejs:6 || die

echo_my "Creating package binding...\n"
wsk package bind ${PKG} ${PKG_TARGET} --param api_key ${API_KEY} --param kafka_rest_url ${KAFKA_REST_URL} --param topic ${DEST_TOPIC} || die

echo_my "Summary of package binding...\n"
wsk package get --summary ${PKG_TARGET}

############################# TRIGGERS
echo_my "Creating $TRIGGER trigger...\n"
wsk trigger create ${TRIGGER} -f /${BMX_ORG}_${BMX_SPACE}/${BMX_CREDENTIALS}/messageHubFeed -p isJSONData true -p topic ${SRC_TOPIC} || die

############################# SEQUENCES
echo_my "Creating ${SEQUENCE} sequence...\n"
wsk action create ${SEQUENCE} --sequence ${GET_ACTION},${PKG_TARGET}/${POST_ACTION} || die
# wsk action create ${SEQUENCE} --sequence ${GET_ACTION},${PKG_TARGET}/${POST_ACTION} || die

############################# RULES
echo_my "Creating $RULE rule...\n"
wsk rule create ${RULE} ${TRIGGER} ${SEQUENCE} || die

echo_my "All done!\n"