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

source local.env

#############################################################################
# Takes input message and decodes the base64 to human readable format
# ARGS:
#       1 - Input message in the form of [{"key":null,"value":"eyJyZXN1bHQiOiJvayJ9","partition":0,"offset":11}]
# RETURNS:
#       DECODED - human readable string for the "value" part of the message - saved in the DECODED global variable
#############################################################################
DECODED=""
decode_response() {
  local ARG=$1
  local ENCODED=${1##*,\"value\":\"}
  local ENCODED=${ENCODED%%\",\"partition\":*}
  DECODED=`echo $ENCODED | base64 -D`
}

#############################################################################
# Creates Kafka consumer
# ARGS:
#       1 - Consumer name
# RETURNS:
#       Nothing
#############################################################################
create_consumer()
{
  local CONSUMER=$1
  # Create a consumer for binary data, starting at the beginning of the topic's
  # log. Then consume some data from a topic.
  curl -X POST -H "Content-Type: application/vnd.kafka.v1+json" \
    -H "X-Auth-Token: $API_KEY" \
    --data '{"id": "my_instance", "format": "binary", "auto.offset.reset": "smallest"}' \
    $KAFKA_REST_URL/$CONSUMER
}

#############################################################################
# Consumes a message from a designated topic
# ARGS:
#       1 - Topic name
#       2 - Consumer name
# RETURNS:
#       RESULT - message that was consumed from Kafka topic
#############################################################################
consume()
{
  local TOPIC=$1
  local CONSUMER=$2
  RESULT=`curl -X GET -H "Accept: application/vnd.kafka.binary.v1+json" \
    -H "X-Auth-Token: $API_KEY" \
    $KAFKA_REST_URL/$CONSUMER/instances/my_instance/topics/$TOPIC`
}

#############################################################################
# MAIN
#############################################################################
CONSUMER=consumers/my_consumer
echo "Creating Kafka consumer '$CONSUMER'"
create_consumer $CONSUMER

echo "Consuming a message from the topic '$DEST_TOPIC'"
consume $DEST_TOPIC $CONSUMER

echo "Message content obtained:"
decode_response "$RESULT"
echo "\033[0;31m$DECODED" $ECHO_NO_PREFIX

echo "All done!"
