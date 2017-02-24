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

# Project settings
BMX_ORG=ServerlessOrg
BMX_SPACE=test
REQUEST_FILE=request.json
OPEN_WHISK_BIN=/home/ubuntu/bin
export PATH=$PATH:$OPEN_WHISK_BIN

# Message Hub settings
KAFKA_REST_URL=https://kafka-rest-prod01.messagehub.services.us-south.bluemix.net:443
KAFKA_ADMIN_URL=https://kafka-admin-prod01.messagehub.services.us-south.bluemix.net:443
KAFKA_INSTANCE_NAME=kafka-broker
SRC_TOPIC=in-topic
DEST_TOPIC=out-topic
PKG=kafka
PKG_TARGET=kafka-out-binding
GET_ACTION=mhget-action
POST_ACTION=mhpost-action
SEQUENCE=kafka-sequence
RULE=kafka-inbound-rule
TRIGGER=kafka-trigger
BMX_CREDENTIALS=Bluemix_${KAFKA_INSTANCE_NAME}_Credentials-1

##############################################################################
# Error function
##############################################################################
die()
{
	echo Error: $?
	exit 1
}

##############################################################################
# Replace standard ECHO function with custom output
# PARAMS:		1 - Text to show (mandatory)
# 				2 - Logging level (optional) - see levels below
##############################################################################
# Available logging levels (least to most verbose)
ECHO_NONE=0
ECHO_NO_PREFIX=1
ECHO_ERROR=2
ECHO_WARNING=3
ECHO_INFO=4
ECHO_DEBUG=5
# Default logging level
ECHO_LEVEL=$ECHO_DEBUG

echo_my()
{
	local RED='\033[0;31m'
	local GREEN='\033[32m'
	local ORANGE='\033[33m'
	local NORMAL='\033[0m'
	# local PREFIX="[`hostname`] "
	local PREFIX=""

	if [ $# -gt 1 ]; then
		local ECHO_REQUESTED=$2
	else
		local ECHO_REQUESTED=$ECHO_INFO
	fi

	if [ $ECHO_REQUESTED -gt $ECHO_LEVEL ]; then return; fi
	if [ $ECHO_REQUESTED = $ECHO_NONE ]; then return; fi
	if [ $ECHO_REQUESTED = $ECHO_ERROR ]; then PREFIX="${RED}[ERROR] ${PREFIX}"; fi
	if [ $ECHO_REQUESTED = $ECHO_WARNING ]; then PREFIX="${RED}[WARNING] ${PREFIX}"; fi
	if [ $ECHO_REQUESTED = $ECHO_INFO ]; then PREFIX="${GREEN}[INFO] ${PREFIX}"; fi
	if [ $ECHO_REQUESTED = $ECHO_DEBUG ]; then PREFIX="${ORANGE}[DEBUG] ${PREFIX}"; fi
	if [ $ECHO_REQUESTED = $ECHO_NO_PREFIX ]; then PREFIX="${GREEN}"; fi

	printf "\n${PREFIX}$1${NORMAL}"
}
