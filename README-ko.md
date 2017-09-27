[![Build Status](https://travis-ci.org/IBM/openwhisk-data-processing-message-hub.svg?branch=master)](https://travis-ci.org/IBM/openwhisk-data-processing-message-hub)

# OpenWhisk로 Message Hub 데이터 처리하기

*다른 언어로 보기: [English](README.md).*

이 과정은 서버리스, 이벤트 중심 아키텍쳐라 메시지나 데이터 레코드에 대한 스트림을 처리하는데 대응하여 어떻게 코드를 실행하는지 보여줍니다.

여기서는 Apache Kafka 기반의 IBM Message Hub에 메시지를 쓰고 읽는 JavaScript로 작성된 두 개의 OpenWhisk 액션을 보여줍니다. 사용 사례는 액션이 데이터 서비스와 함께 동작하는지, 메시지 이벤트에 대응하여 로직을 실행하는지 보여줍니다.

첫 번째 액션은 하나 이상의 데이터 레코드의 메시지 스트림을 수신하며, 이는 OpenWhisk 시퀀스(체인에서 선언적으로 액션을 연결하는 방법)에서 다른 액션으로 연결됩니다. 두 번째 액션은 메시지를 취합하고 변화된 요약 메시지를 다른 토픽에 게시합니다.

![Sample Architecture](docs/OpenWhisk-MessageHub-sample-architecture.png)

## 포함된 구성 요소

- OpenWhisk
- IBM Message Hub (Apache Kafka)

## 전제 조건

You should have a basic understanding of the OpenWhisk programming model. If not, [try the action, trigger, and rule demo first](https://github.com/IBM/openwhisk-action-trigger-rule).

Also, you'll need a Bluemix account and the latest [OpenWhisk command line tool (`wsk`) installed and on your PATH](https://github.com/IBM/openwhisk-action-trigger-rule/blob/master/docs/OPENWHISK.md).

As an alternative to this end-to-end example, you might also consider the more [basic "building block" version](https://github.com/IBM/openwhisk-message-hub-trigger) of this sample.

## 단계

1. [IBM Message Hub 구성하기](#1-ibm-message-hub-구성하기)
2. [OpenWhisk 액션, 트리거 및 룰 생성하기](#2-openwhisk-액션-및-매핑하기)
3. [신규 메시지 이벤트 테스트하기](#3-신규-메시지-이벤트-테스트하기)
4. [액션, 트리거 및 룰 삭제하기](#4-액션-트리거-및-룰-삭제하기)
5. [수동으로 다시 생성하기](#5-수동으로-다시-생성하기)

# 1. IBM Message Hub 구성하기
Bluemix에 로그인 후, 이름을 `kafka-broker`로 지정하여 [Message Hub](https://console.ng.bluemix.net/catalog/services/message-hub) 인스턴스를 생성합니다. Message Hub 콘솔의 "Manage"탭에서 다음 두 개의 토픽을 생성합니다: _in-topic_ / _out-topic_.

`template.local.env` 파일을 `local.env`로 이름을 변경하여 복사하고 `KAFKA_INSTANCE`, `SRC_TOPIC` 및 `DEST_TOPIC`의 값이 인스턴스의 정보와 다른 경우 업데이트 합니다.

# 2. OpenWhisk 액션, 트리거 및 룰 생성하기
`deploy.sh`는 `local.env`에서 환경 변수를 읽고, OpenWhisk 액션을 생성하며, API 매핑을 대신 해 주는  편의를 위한 스크립트 파일입니다. 나중이 이 명령들을 직접 실행하게 됩니다.

```bash
./deploy.sh --install
```
> **참고**: 에러 메시지가 나타나면, 아래 [문제 해결](#문제-해결) 영역을 참고 하기 바랍니다. 또한, [다른 배포 방법](#다른-배포-방법)을 참고 할 수 있습니다.

# 3. 신규 메시지 이벤트 테스트하기
로그 폴링을 위해 터미널 윈도를 하나 엽니다:
```bash
wsk activation poll
```

처리 할 이벤트 세트를 메시지로 전송합니다.
```bash
# 메시지를 생성하면 액션의 시퀀스를 트리거하게 됩니다
DATA=$( base64 events.json | tr -d '\n' | tr -d '\r' )

wsk action invoke Bluemix_${KAFKA_INSTANCE}_Credentials-1/messageHubProduce \
  --param topic $SRC_TOPIC \
  --param value "$DATA" \
  --param base64DecodeValue true
```

# 4. 액션, 트리거 및 룰 삭제하기
`deploy.sh` 을 다시 사용해서 OpenWhisk 액션과 매핑을 제거합니다. 이는 다음 영역에서 하나씩 다시 만들어 볼 수 있습니다.

```bash
./deploy.sh --uninstall
```

# 5. 수동으로 다시 생성하기
이 영역은 `deploy.sh`가 어떤 것을 실행하는지 좀 더 깊숙히 들여다봄으로써 OpenWhisk 트리거, 액션, 룰 그리고 패키지가 어떻게 동작하는지 좀 더 상세히 알 수 있게 됩니다.

## 5.1 Kafka 메시지 트리거 생성하기
새로운 메시지를 수신하는 Message Hub 패키지 피드를 이용하여 `message-trigger` 트리거를 생성하십시오. 패키지를 refresh 하면 Message Hub 서비스 신임 정보와 OpenWhisk로 연결 정보를 생성하게 됩니다.

```bash
wsk package refresh
wsk trigger create message-trigger \
  --feed Bluemix_${KAFKA_INSTANCE}_Credentials-1/messageHubFeed \
  --param isJSONData true \
  --param topic ${SRC_TOPIC}
```

## 5.2 메시지 수신 액션 생성하기
JavaScript 액션으로 `receive-consume` 액션을 업로드 합니다. 이는 트리거를 통해 메시지가 도착하면 메시지를 다운로드 합니다.

```bash
wsk action create receive-consume actions/receive-consume.js
```

## 5.3 메시시 취합 및 되돌려 보내는 액션 생성하기
`transform-produce` 액션을 업로드 하십시오. 이는 위의 액션에서 오는 정보를 통합하며, 또다른 Message Hub 토픽으로 요약된 JSON 문자열을 전송합니다.

```bash
wsk action create transform-produce actions/transform-produce.js \
  --param topic ${DEST_TOPIC} \
  --param kafka ${KAFKA_INSTANCE}
```

## 5.4 GET과 POST를 연결하는 시퀀스 생성하기

`receive-consume` 과 `transform-produce` 사이를 연결하는 시퀀스 의 이름을 `message-processing-sequence`로 선언하십시오.

```bash
wsk action create message-processing-sequence --sequence receive-consume,transform-produce
```

## 5.5 트리거를 스퀀스에 연결하는 룰 생성하기
`message-trigger` 트리거를 `message-processing-sequence` 시퀀스로 연결하는 룰 이름을 `message-rule`으로 선언 하십시오.

```bash
wsk rule create message-rule message-trigger message-processing-sequence
```

## 5.6 새로운 메시지 이벤트 테스트하기
```bash
# 메시지를 생성하면 시퀀스가 트리거 됩니다
DATA=$( base64 events.json | tr -d '\n' | tr -d '\r' )

wsk action invoke Bluemix_${KAFKA_INSTANCE}_Credentials-1/messageHubProduce \
  --param topic $SRC_TOPIC \
  --param value "$DATA" \
  --param base64DecodeValue true
```
# 문제 해결
가장 먼저 OpenWhisk 활성화 로그에서 오류를 확인 하십시오. 명령창에서 `wsk activation poll`을 이용하여 로그 메시지를 확인하거나 [Bluemix의 모니터링 콘솔](https://console.ng.bluemix.net/openwhisk/dashboard)에서 시각적으로 상세정보를 확인해 보십시오.

오류가 즉각적으로 분명하지 않다면, [최신 버젼의 `wsk` CLI](https://console.ng.bluemix.net/openwhisk/learn/cli)가 설치되어 있는지 확인하십시오. 만약 이전 것이라면 다운로드하고 업데이트 하십시오.
```bash
wsk property get --cliversion
```

# 다른 배포 방법
`deploy.sh`은 향후 [`wskdeploy`](https://github.com/openwhisk/openwhisk-wskdeploy)로 교체될 예정입니다. `wskdeploy`는 선언된 트리거, 액션 및 규칙을 OpenWhisk에 배포하기 위해 manifest를 사용합니다.

또한 다음 버튼을 사용하여 이 저장소의 복사본을 복제하고 DevOps 툴 체인의 일부로 Bluemix에 배포 할 수 있습니다. 딜리버리 파이프 라인 아이콘 아래에서 OpenWhisk 및 MySQL 신임 정보를 제공하고 Create를 클릭 한 후 딜리버리 파이프 라인에 대한 Deploy Stage를 실행하십시오.

[![Deploy to Bluemix](https://bluemix.net/deploy/button.png)](https://bluemix.net/deploy?repository=https://github.com/IBM/openwhisk-data-processing-message-hub.git)

# 라이센스
[Apache 2.0](LICENSE.txt)

# 크레딧
이 과정은 [이 글](https://medium.com/openwhisk/transit-flexible-pipeline-for-iot-data-with-bluemix-and-openwhisk-4824cf20f1e0#.talwj9dno)의 코드에서 많은 영감을 받았고 이를 재사용했습니다.