# Getting Started with OpenWhisk and Message Hub
This project provides sample code for creating a Message Hub (Kafka) data processing app with Apache OpenWhisk on IBM Bluemix. It should take no more than 10 minutes to get up and running. Once you complete this sample application, you can move on to more complex serverless application use cases.

Serverless platforms like Apache OpenWhisk provide a runtime that scales automatically in response to demand, resulting in a better match between the cost of cloud resources consumed and business value gained. One of the key use cases for OpenWhisk is to execute logic in response to events, such as messages or new streams of data.

## Overview of message flow
![Sample Architecture](/images/OpenWhisk-MessageHub-sample-architecture.png)

Flow of processing goes as follows:

1. External process (simulated by the script [`kafka_publish.sh`](kafka_publish.sh)) puts a message into IBM Message Hub (Kafka) into the topic 'in-topic'.
2. OpenWhisk has a feed from Message Hub that starts a trigger 'kafka-trigger'.
3. The trigger starts a rule 'kafka-inbound-rule', which is configured to invoke a 'kafka-sequence' sequence.
4. That sequence invokes two actions one after another. The first action called is 'consume-kafka-action'. It picks up the message from Message Hub and validates that message.
5. The output of the first action is passed as input into the action 'publish-kafka-action'. This action counts number of "events" in the input message and generates a summary JSON and then publishes it into the Message Hub topic 'out-topic'.
6. External process (simulated by the [`kafka_consume.sh`](kafka_consume.sh)) retrieves the message from Message Hub and prints it on the screen. Please note that due to latency issues, you may need to run the message consumer again if it did not get the message the first time.
7. This completes the flow of data.

# Installation
Setting up this sample involves configuration of OpenWhisk and Cloudant on IBM Bluemix. [If you haven't already signed up for Bluemix and configured OpenWhisk, review those steps first](docs/OPENWHISK.md).

### Setting up Message Hub
First, let's set up the IBM Message Hub on Bluemix. We need it to broker messages between our simulated clients and actions on OpenWhisk.

1. Go to the Bluemix Catalog page and select [Message Hub service](https://console.ng.bluemix.net/catalog/services/message-hub).
2. Click "Create" in the right hand bottom corner. Lets assume you called your Message Hub broker "kafka-broker".
3. On a "Manage" tab of your Message Hub console create two topics: "in-topic" and "out-topic".

> If you want to change names of topics or other resources, please update [`env.sh`](env.sh) file to reflect your changes.

### Setting up OpenWhisk
The next step is to configure OpenWhisk to perform the message consumption, transformation, and publishing.

1. Clone this repository to your machine.
2. Run [`wskinstall.sh`](wskinstall.sh) script - this will download and configure `wsk` command line tool.
2. Copy [`secret.template.sh`](secret.template.sh) into `secret.sh` and update it with proper credentials (from VCAP_SERVICES or the "Credentials" tab in Message Hub UI).
3. Configure `BMX_ORG` and `BMX_SPACE` in [`env.sh`](env.sh) with the organization and space that you are using from your Bluemix Account.
3. Run [`wskdeploy.sh`](wskdeploy.sh) script. This will package and deploy your JavaScript actions into Bluemix OpenWhisk cloud.

### Test the application
Now that your Message Hub and OpenWhisk are configured and cloud resources are deployed, it is time to test the application.

1. Send one or more test messages by running [`kafka_publish.sh`](kafka_publish.sh) script. This will kick off the chain of processing.
2. Get responses from server by running [`kafka_consume.sh`](kafka_consume.sh) script. It will display results on your screen.

This example is intentionally kept simple, but you can extend it with many additional actions, triggers, rules and connect OpenWhisk to other resources. It is very easy to build scalable serverless applications with OpenWhisk.

### Troubleshooting
The first place to check for errors is the OpenWhisk activation log. You can view it by tailing the log on the command line with `wsk activation poll` or you can view the [monitoring console on Bluemix](https://console.ng.bluemix.net/openwhisk/dashboard).

# Credits
This project was inspired by and reuses significant amount of code from [this article](https://medium.com/openwhisk/transit-flexible-pipeline-for-iot-data-with-bluemix-and-openwhisk-4824cf20f1e0#.talwj9dno).

# License
Licensed under [Apache 2.0 license](LICENSE.txt).
