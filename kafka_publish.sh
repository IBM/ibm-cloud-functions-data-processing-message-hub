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
# Posts a message to a designated topic
# ARGS:
#       1 - Topic name
#       2 - Payload (must be encoded in base64)
# RETURNS:
#       Nothing
#############################################################################
post()
{
  local TOPIC=$1
  local DATA='{"records":[{"value":"'${2}'"}]}'

  # See details here: http://docs.confluent.io/1.0/kafka-rest/docs/intro.html
  # Produce a message using PAYLOAD to the kafka topic TOPIC
  curl -X POST -H "Content-Type: application/vnd.kafka.binary.v1+json" \
    -H "X-Auth-Token: $API_KEY" \
    --data "$DATA" \
    "$KAFKA_REST_URL/topics/$TOPIC"
}

#############################################################################
# MAIN
#############################################################################
echo "Encoding payload from file 'request.json'..."
PAYLOAD=$( base64 request.json | tr -d '\n' | tr -d '\r' )   # Note that it is important to disable line wrapping

NUM_MSGS=2
for ((i=0; i<$NUM_MSGS; i++)); do
  echo -e "\nPosting a message #$i into the topic '$SRC_TOPIC'"
  post $SRC_TOPIC "$PAYLOAD"    # Note that PAYLOAD has spaces in in, so need to pass it in quotes
done

echo -e "\nAll done!"
