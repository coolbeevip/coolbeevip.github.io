---
title: "Apache NiFi Schema"
date: 2023-09-02T00:24:14+08:00
tags: [ workflow,schema ]
categories: [ apache,nifi ]
draft: false
---

# Apache NiFi Schema

Apache NiFi是一个易于使用、功能强大且可靠的数据处理和分发系统。它采用基于组件的方式设计数据流。

在NiFi终端界面，用户通过界面拖动组件建立和维护数据流。

## 术语

#### Processor

处理器是NiFi的基本组件，负责创建、发送、接收、转换、过滤、分割和处理数据。NiFi的数据流是由处理器连接起来的。处理器有一组属性，可以根据需要进行配置。

1. **Name**: Processor 的名称，用于在数据流图中识别 Processor。

2. **Scheduling Strategy**: 确定 Processor 是应根据时间间隔（Timer Driven）运行，还是应根据事件触发（Event Driven）运行。

3. **Concurrent tasks**: 这是可以同时执行的任务数。这允许并行处理，可以提高处理效能。

4. **Comments**: 可以在此处添加任何有关 Processor 的额外信息或注释。

5. **Yield Duration**: 当 Processor 无法进行处理时（例如，输出连接的队列已满），它将“退避（Yield）”，过一段时间再试。该属性定义了退避的持续时间。

6. **Penalization Duration**: 如果 Processor出现错误，将对其进行“惩罚”，使其在一段时间内无法处理任何FlowFile。这项属性决定了这段时间的长度。

#### Connection

在 Apache NiFi 中，`connection` 是流程图中两个处理器或者一个处理器与一个转换器之间传递数据的关键部分。以下是 `connection` 的一些典型属性（schema）：

1. **Name**: 连接的名称，便于在数据流图中明确识别连接。
2. **Source**: 连接的源处理器。连接从此处开始，将源处理器的输出数据传递到目标处理器。
3. **Destination**: 连接的目标处理器，它接收源处理器的输出数据。
4. **Back Pressure Object Threshold**: 这是队列中元素的数量，一旦超过该数量，源处理器将停止生产数据。
5. **Back Pressure Data Size Threshold**: 这是队列容量，一旦超过这个容量，源处理器将停止生产数据。
6. **Prioritizers**: 如果队列中包含多个元素，优先级器确定应首先处理哪一项。
7. **Expiration**: FlowFile在队列中能存活的最长时间。

#### FlowFile

Apache NiFi 中的 `FlowFile` 是一个数据记录或对象，它包含两部分，数据内容和属性。以下是一些 `FlowFile` 相关的重要概念和可能的 Schema ：

1. **Content**: 这部分存储实际的数据。这可以是任何类型的数据，包括纯文本，JSON，XML，图像，视频等。在流程中，处理器可以修改 FlowFile 的内容。

2. **Attributes**: 这部分存储元数据，帮助您处理或路由数据。FlowFile 的元数据属性可以是文件名，数据的大小，MimeType类型等。

一些常见的 `FlowFile` 属性：

- `filename`: FlowFile 的名称。
- `path`: FlowFile 在文件系统中的路径。
- `uuid`: FlowFile 的唯一标识符。
- `priority`: FlowFile 的优先级。
- `penaltyexpiresAt`: 当 FlowFile 在不存在问题时下次可以输出的时间。

注意：除了这些基本属性，还可以添加自定义属性，如：数据源IP、时间戳，并根据需要在流程中对其进行更新。

以上是一般性的介绍，并不包含所有 `FlowFile` 的属性，具体内容可能会根据实际的数据和处理需求来定义。

#### Process Group

Apache NiFi的`Process Group`是用来组织和管理流程的容器。每个Process Group都有自己的“画布”，可以设定一系列的处理器、输入/输出端口以及子Process Group等。

以下是Process Group的一些键属性：

1. **Name**: 给Process Group命名，有助于在Flow中识别。
2. **Comments**: 用户可以在这里记录有关这个Process Group的任何额外信息或注释。
3. **Run Schedule**: 当Process Group以定时驱动方式运行的时候，这个配置决定了Process Group的运行间隔。
4. **Concurrently Runnable Tasks**: 这个设置决定了在Process Group中每个节点上能同时运行的最大任务数。
5. **Penalize no completion**: 如果被激活，那么如果任务没有完成就将被“惩罚”，即“惩罚”期间任务无法被运行。

在Process Group中，用户可以组织相关处理器之间的连接，完成任务步骤，也可以设置对来自其他Process Groups的数据接入和处理的输入输出端口等等。

#### Controller Service

在 Apache NiFi 中，Controller Service 是一种共享服务，可以被流程中的多个处理器使用。Controller Service 的 schema 或属性因其类型（例如，数据库连接池，SSL上下文服务，Hadoop配置资源等等）而不同，以下是一些通常可配置的基本属性：

1. **Name**: Controller Service 的名称，用于在 NiFi 配置界面上区分各种服务。

2. **Comments**: 可以在此字段中添加对 Controller Service 的描述或其他信息。

3. **State**: Controller Service 的运行状态，可以是"启用"或"禁用"。

4. **Properties**: 这些是与 Controller Service 的特定类型相关的一系列配置选项。例如，如果 Controller Service 是一个数据库连接池，可能需要配置 JDBC 驱动位置，用户名，密码，连接URL等参数。

5. **Validation errors/warnings**: 如果 NiFi 检测到 Controller Service 配置有问题，或者存在某种潜在问题，可能会在此处显示错误或警告信息。

需要注意的是，Controller Service 创建和配置后，需要先启用，才能被 NiFi 流程中的处理器使用。并且在流程中引用了特定 Controller Service 的处理器无法自定义该 Controller Service，它们将共享同一个服务配置。

具体的 Controller Service 属性将根据其所提供服务的性质和需求来设定。

## 样例

> 参考：https://cwiki.apache.org/confluence/display/nifi/example+dataflow+templates

```json
{
  "id": "3ad97bbd-015c-1000-cc5d-de0731e2bcd5",
  "name": "ReverseGeoLookup_ScriptedLookupService",
  "description": "This template provides an example of using ScriptedLookupService to perform a lookup of latitude and longitude values against the Google Reverse Lookup web API, and return the specified location in the same record",
  "timestamp": "05/24/2017 12:28:27 EDT",
  "version": "1.1",
  "connections": [
    {
      "id": "id2cd7d8b1-9763-3143-0000-000000000000",
      "parentgroupid": "1d994300-fd59-339e-0000-000000000000",
      "backpressuredatasizethreshold": "1GB",
      "backpressureobjectthreshold": 10000,
      "source": {
        "groupid": "1d994300-fd59-339e-0000-000000000000",
        "id": "e9e4a255-983d-3675-0000-000000000000",
        "type": "PROCESSOR"
      },
      "destination": {
        "groupid": "1d994300-fd59-339e-0000-000000000000",
        "id": "412646bf-9f19-3cc0-0000-000000000000",
        "type": "PROCESSOR"
      }
    },
    {
      "id": "2cd7d8b1-9763-3143-0000-000000000000",
      "parentgroupid": "1d994300-fd59-339e-0000-000000000000",
      "backpressuredatasizethreshold": "1GB",
      "backpressureobjectthreshold": 10000,
      "source": {
        "groupid": "1d994300-fd59-339e-0000-000000000000",
        "id": "fa7bf4d9-d271-3376-0000-000000000000",
        "type": "PROCESSOR"
      },
      "destination": {
        "groupid": "e9e4a255-983d-3675-0000-000000000000",
        "id": "e9e4a255-983d-3675-0000-000000000000",
        "type": "PROCESSOR"
      }
    }
  ],
  "processors": [
    {
      "id": "412646bf-9f19-3cc0-0000-000000000000",
      "name": "LogAttribute",
      "parentgroupid": "1d994300-fd59-339e-0000-000000000000",
      "type": "org.apache.nifi.processors.standard.LogAttribute",
      "componentType": "PROCESSOR",
      "retryCount": 10,
      "config": {
        "concurrentlyschedulabletaskcount": 1,
        "properties": {}
      },
      "position": {
        "x": 1055.505,
        "y": 665.0208854980469
      },
      "relationships": {
        "autoterminate": true,
        "name": "success"
      }
    },
    {
      "id": "e9e4a255-983d-3675-0000-000000000000",
      "name": "ReverseGeoLookup",
      "parentgroupid": "1d994300-fd59-339e-0000-000000000000",
      "type": "org.apache.nifi.processors.standard.LookupRecord",
      "componentType": "PROCESSOR",
      "retryCount": 10,
      "config": {
        "concurrentlyschedulabletaskcount": 1,
        "propertyDescriptors": {
          "record-reader": {
            "name": "record-reader",
            "displayName": "Record Reader",
            "identifiesControllerService": false,
            "sensitive": false
          },
          "...": {}
        },
        "properties": {
          "record-reader": "72b7797d-72a8-388b-0000-000000000000",
          "record-writer": "53e34351-b658-3a29-0000-000000000000",
          "lookup-service": "a549fc72-2ba2-31ce-0000-000000000000"
        }
      },
      "position": {
        "x": 1055.505,
        "y": 665.0208854980469
      },
      "relationships": [
        {
          "autoterminate": true,
          "name": "failure"
        },
        {
          "autoterminate": false,
          "name": "matched"
        },
        {
          "autoterminate": true,
          "name": "unmatched"
        }
      ]
    },
    {
      "id": "fa7bf4d9-d271-3376-0000-000000000000",
      "name": "GenerateFlowFile",
      "parentgroupid": "1d994300-fd59-339e-0000-000000000000",
      "type": "org.apache.nifi.processors.standard.GenerateFlowFile",
      "config": {
        "concurrentlyschedulabletaskcount": 1,
        "properties":{
          "key1": "value1"
        }
      },
      "position": {
        "x": 1055.505,
        "y": 665.0208854980469
      },
      "relationships": [
        {
          "autoterminate": false,
          "name": "success"
        }
      ]
    }
  ],
  "controllerservices": [
    {
      "id": "a549fc72-2ba2-31ce-0000-000000000000",
      "parentgroupid": "1d994300-fd59-339e-0000-000000000000",
      "name": "ScriptedLookupService",
      "type": "org.apache.nifi.lookup.script.ScriptedLookupService",
      "properties": [
        {
          "key": "Script Engine",
          "value": "Groovy"
        },
        {
          "key": "Script File",
          "value": ""
        },
        {
          "key": "Script Body",
          "value": "...lookupService = new GroovyLookupService()..."
        },
        {
          "key": "googleApiKey",
          "value": "Your Google API Key Here"
        }
      ]
    }
  ]
}
```
