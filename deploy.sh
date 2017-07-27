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

function usage() {
  echo -e "Usage: $0 [--install,--uninstall,--env]"
}

function install() {
  echo -e "Installing OpenWhisk actions, triggers, and rules for openwhisk-data-processing-message-hub..."

  echo -e "Make Message Hub connection info available to OpenWhisk"
  wsk package refresh

  echo "Creating the message-trigger trigger"
  wsk trigger create message-trigger \
    --feed Bluemix_${KAFKA_INSTANCE}_Credentials-1/messageHubFeed \
    --param isJSONData true \
    --param topic ${SRC_TOPIC}

  echo "Creating receive-consume action as a regular Node.js action"
  wsk action create receive-consume actions/receive-consume.js

  echo "Creating transform-produce action as regular Node.js action"
  wsk action create transform-produce actions/transform-produce.js \
    --param topic ${DEST_TOPIC} \
    --param kafka ${KAFKA_INSTANCE}

  echo "Creating the message-processing-sequence sequence that links the consumer and producer actions"
  wsk action create message-processing-sequence --sequence receive-consume,transform-produce

  echo "Creating the  message-rule rule that links the trigger to the sequence"
  wsk rule create message-rule message-trigger message-processing-sequence

  echo -e "Install Complete"
}


function uninstall() {
  echo -e "Uninstalling..."

  wsk rule delete --disable message-rule
	wsk trigger delete message-trigger
	wsk action delete message-processing-sequence
	wsk action delete receive-consume
	wsk action delete transform-produce
  wsk package delete Bluemix_${KAFKA_INSTANCE}_Credentials-1

  echo -e "Uninstall Complete"
}

function showenv() {
  echo -e KAFKA_INSTANCE="$KAFKA_INSTANCE"
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
