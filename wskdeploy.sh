#!/bin/bash

##############################################################################
# Copyright 2017 IBM Corporation
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

# Load configuration variables
source local.env

function install() {
  echo -e "Installing OpenWhisk actions, triggers, and rules for openwhisk-data-processing-message-hub..."

  echo "Creating kafka package"
  wsk package create kafka

  # Package the rule for deployment
  echo "Zipping up actions"
  DIR=`pwd`
  cd actions/mhpost
  npm install
  zip -r mhpost.zip *
  cd ${DIR}

  echo "Creating mhget-action action"
  wsk action create mhget-action actions/mhget/mhget.js

  echo "Creating mhpost-action action"
  wsk action create kafka/mhpost-action actions/mhpost/mhpost.zip --kind nodejs:6

  echo "Creating package binding"
  wsk package bind kafka kafka-out-binding --param api_key ${API_KEY} --param kafka_rest_url ${KAFKA_REST_URL} --param topic ${DEST_TOPIC}

  echo "Summary of package binding"
  wsk package get --summary kafka-out-binding

  echo "Creating kafka-trigger trigger"
  wsk trigger create kafka-trigger -f /_/Bluemix_${KAFKA_INSTANCE_NAME}_Credentials-1/messageHubFeed -p isJSONData true -p topic ${SRC_TOPIC}

  echo "Creating kafka-sequence sequence"
  wsk action create kafka-sequence --sequence mhget-action,kafka-out-binding/mhpost-action
  # wsk action create kafka-sequence --sequence mhget-action,kafka-out-binding/mhpost-action

  echo "Creating kafka-inbound-rule rule"
  wsk rule create kafka-inbound-rule kafka-trigger kafka-sequence

  echo -e "Install Complete"
}


function uninstall() {
  echo -e "Uninstalling..."

  wsk rule delete --disable kafka-inbound-rule
	wsk trigger delete kafka-trigger
	wsk action delete kafka-sequence
	wsk action delete mhget-action
	wsk action delete kafka/mhpost-action
	wsk package delete kafka-out-binding
	wsk package delete kafka

  echo -e "Uninstall Complete"
}

function showenv() {
  echo -e API_KEY="$API_KEY"
  echo -e USER="$USER"
  echo -e PASSWORD="$PASSWORD"
  echo -e KAFKA_REST_URL="$KAFKA_REST_URL"
  echo -e KAFKA_ADMIN_URL="$KAFKA_ADMIN_URL"
  echo -e KAFKA_INSTANCE_NAME="$KAFKA_INSTANCE_NAME"
  echo -e SRC_TOPIC="$SRC_TOPIC"
  echo -e DEST_TOPIC="$DEST_TOPIC"
}

case "$1" in
"--install" )
install
;;
"--uninstall" )
uninstall
;;
"--env" )
showenv
;;
* )
usage
;;
esac
