[![Build Status](https://travis-ci.org/IBM/openwhisk-data-processing-message-hub.svg?branch=master)](https://travis-ci.org/IBM/openwhisk-data-processing-message-hub)

# OpenWhisk 101 - OpenWhisk and Message Hub
Learn how to [create Message Hub data processing apps](https://github.com/IBM/openwhisk-data-processing-message-hub/wiki) with Apache OpenWhisk on IBM Bluemix. This tutorial will take less than 10 minutes to complete.

You should have a basic understanding of the OpenWhisk programming model. If not, [try the action, trigger, and rule demo first](https://github.com/IBM/openwhisk-action-trigger-rule). [You'll also need a Bluemix account and the latest OpenWhisk command line tool](docs/OPENWHISK.md).

When complete, move on to more complex serverless applications, such as those named _OpenWhisk 201_ or tagged as [_openwhisk-use-cases_](https://github.com/search?q=topic%3Aopenwhisk-use-cases+org%3AIBM&type=Repositories).

# Message Hub data processing with OpenWhisk
The example shows how to write actions receive data from Message Hub, aggregate those messages, and send data back to Message Hub. It also shows how to sequences with triggers and rules to link units of logic in a series.

![Sample Architecture](docs/OpenWhisk-MessageHub-sample-architecture.png)

Steps

1. [Provision Message Hub](#1-provision-mysql)
2. [Create OpenWhisk actions, triggers, and rules](#2-create-openwhisk-actions-triggers-and-rules)
3. [Test new message events](#3-test-new-message-events)
4. [Delete actions, triggers, and rules](#4-delete-actions-triggers-and-rules)
5. [Recreate deployment manually](#5-recreate-deployment-manually)


# 1. Provision Message Hub
Log into Bluemix, provision a [Message Hub](https://console.ng.bluemix.net/catalog/services/message-hub) instance, and name it `kafka-broker`. On the "Manage" tab of your Message Hub console create two topics: _in-topic_ and _out-topic_.

Copy `template.local.env` to a new file named `local.env` and update the `KAFKA_INSTANCE_NAME`, `SRC_TOPIC`, and `DEST_TOPIC` values for your instance if they differ. Update the `API_KEY`, `USER`, and `PASSWORD` values from the "Credentials" tab.

# 2. Create OpenWhisk actions, triggers, and rules
`deploy.sh` is a convenience script reads the environment variables from `local.env` and creates the OpenWhisk actions, triggers, and rules on your behalf. Later you will run these commands yourself.

```bash
./deploy.sh --install
```
> **Note**: If you see any error messages, refer to the [Troubleshooting](#troubleshooting) section below.

> **Note**: `deploy.sh` will be replaced with [`wskdeploy`](https://github.com/openwhisk/openwhisk-wskdeploy) in the future. `wskdeploy` uses a manifest to deploy declared triggers, actions, and rules to OpenWhisk.

# 3. Test new message events
To test, invoke the first action manually. Open one terminal window to poll the logs:
```bash
wsk activation poll
```

And in a second terminal, invoke the action:
```bash
wsk action invoke --blocking --result write-to-cloudant
```

# 3. Test new message events
There are two helper scripts that simulate a message producer and a message consumer.

```bash
# Produce a message, will trigger the sequence
./kafka_publish.sh

# Consume a message after processing is complete
./kafka_consume.sh
```

# 4. Delete actions, triggers, and rules
Use `deploy.sh` again to tear down the OpenWhisk actions, triggers, and rules. You will recreate them step-by-step in the next section.

```bash
./deploy.sh --uninstall
```

# Troubleshooting
Check for errors first in the OpenWhisk activation log. Tail the log on the command line with `wsk activation poll` or drill into details visually with the [monitoring console on Bluemix](https://console.ng.bluemix.net/openwhisk/dashboard).

If the error is not immediately obvious, make sure you have the [latest version of the `wsk` CLI installed](https://console.ng.bluemix.net/openwhisk/learn/cli). If it's older than a few weeks, download an update.
```bash
wsk property get --cliversion
```

# License
[Apache 2.0](LICENSE.txt)

# Credits
This project was inspired by and reuses significant amount of code from [this article](https://medium.com/openwhisk/transit-flexible-pipeline-for-iot-data-with-bluemix-and-openwhisk-4824cf20f1e0#.talwj9dno).
