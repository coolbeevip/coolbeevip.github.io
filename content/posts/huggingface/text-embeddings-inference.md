---
title: "Text Embeddings Inference"
date: 2020-09-01T13:24:14+08:00
tags: [huggingface,embedding]
categories: [embedding]
draft: true
---

## Install

Download models

```shell
# Re-rankers
git clone https://huggingface.co/BAAI/bge-reranker-v2-m3
# Sequence Classification
git clone https://huggingface.co/SamLowe/roberta-base-go_emotions
# Embedding
git clone https://huggingface.co/BAAI/bge-m3
```
#### Docker

```shell
docker run -p 8080:80 -v /Volumes/SD/huggingface-models:/data --pull always ddosify/text-embeddings-inference:cpu-1.6.0 --model-id /data/bge-m3
```

#### Embedding models

```shell
text-embeddings-router --model-id /Volumes/SD/huggingface-models/bge-m3 --port 8080
```

```shell
curl 127.0.0.1:8080/embed \
    -X POST \
    -d '{"inputs":"What is Deep Learning?"}' \
    -H 'Content-Type: application/json'
```

#### Sequence Classification model

```shell
text-embeddings-router --model-id /Volumes/SD/huggingface-models/roberta-base-go_emotions --port 8080
```

```shell
curl 127.0.0.1:8080/predict \
    -X POST \
    -d '{"inputs":"I like you."}' \
    -H 'Content-Type: application/json'
[{"score":0.9857024,"label":"love"},{"score":0.0066806404,"label":"admiration"},{"score":0.0020655277,"label":"approval"},{"score":0.00087973906,"label":"neutral"},{"score":0.00058832625,"label":"joy"},{"score":0.00054199155,"label":"optimism"},{"score":0.00046722594,"label":"gratitude"},{"score":0.00031123954,"label":"realization"},{"score":0.00028784954,"label":"disapproval"},{"score":0.00027253045,"label":"desire"},{"score":0.00026830527,"label":"caring"},{"score":0.00025204947,"label":"annoyance"},{"score":0.00021391161,"label":"disappointment"},{"score":0.00019938755,"label":"excitement"},{"score":0.00018440332,"label":"sadness"},{"score":0.00017803303,"label":"amusement"},{"score":0.00017733894,"label":"anger"},{"score":0.00016724656,"label":"confusion"},{"score":0.000108405126,"label":"curiosity"},{"score":0.000101440164,"label":"disgust"},{"score":0.00009418401,"label":"surprise"},{"score":0.000079310885,"label":"remorse"},{"score":0.000044489374,"label":"fear"},{"score":0.000033451415,"label":"pride"},{"score":0.000028500963,"label":"embarrassment"},{"score":0.000026462249,"label":"nervousness"},{"score":0.000023444254,"label":"relief"},{"score":0.000022023838,"label":"grief"}]
```

#### Re-rankers models

```shell
text-embeddings-router --model-id /Volumes/SD/huggingface-models/bge-reranker-v2-m3 --port 8080
```

```shell
curl 127.0.0.1:8080/rerank \
    -X POST \
    -d '{"query": "What is Deep Learning?", "texts": ["Deep Learning is not...", "Deep learning is..."]}' \
    -H 'Content-Type: application/json'
[{"index":1,"score":0.9976495},{"index":0,"score":0.1261379}]
```

## 基准测试(Macbook pro M1)

#### Embeddings

```shell
echo '{"inputs":"In models based on the Transformer architecture, bidirectional encoders are used for pre-training, which can generate contextually rich word embeddings."}' > data.json
ab -n 10000 -c 50 -p data.json -T application/json http://127.0.0.1:8080/embed
This is ApacheBench, Version 2.3 <$Revision: 1903618 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

Benchmarking 127.0.0.1 (be patient)
Completed 1000 requests
Completed 2000 requests
Completed 3000 requests
Completed 4000 requests
Completed 5000 requests
Completed 6000 requests
Completed 7000 requests
Completed 8000 requests
Completed 9000 requests
Completed 10000 requests
Finished 10000 requests


Server Software:
Server Hostname:        127.0.0.1
Server Port:            8080

Document Path:          /embed
Document Length:        12751 bytes

Concurrency Level:      50
Time taken for tests:   265.670 seconds
Complete requests:      10000
Failed requests:        0
Total transferred:      131590277 bytes
Total body sent:        3070000
HTML transferred:       127510000 bytes
Requests per second:    37.64 [#/sec] (mean)
Time per request:       1328.351 [ms] (mean)
Time per request:       26.567 [ms] (mean, across all concurrent requests)
Transfer rate:          483.71 [Kbytes/sec] received
                        11.28 kb/s sent
                        494.99 kb/s total

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        9   95  53.9     89     441
Processing:    37 1229  65.1   1234    1560
Waiting:       37 1229  65.1   1234    1560
Total:         56 1324  42.2   1321    1692

Percentage of the requests served within a certain time (ms)
  50%   1321
  66%   1331
  75%   1340
  80%   1343
  90%   1348
  95%   1353
  98%   1359
  99%   1363
 100%   1692 (longest request)
```

```shell
echo '{"inputs":"基于Transformer架构的模型，使用双向编码器进行预训练，能够生成上下文信息丰富的词嵌入"}' > data.json
ab -n 10000 -c 50 -p data.json -T application/json http://127.0.0.1:8080/embed
This is ApacheBench, Version 2.3 <$Revision: 1903618 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

Benchmarking 127.0.0.1 (be patient)
Completed 1000 requests
Completed 2000 requests
Completed 3000 requests
Completed 4000 requests
Completed 5000 requests
Completed 6000 requests
Completed 7000 requests
Completed 8000 requests
Completed 9000 requests
Completed 10000 requests
Finished 10000 requests


Server Software:
Server Hostname:        127.0.0.1
Server Port:            8080

Document Path:          /embed
Document Length:        12771 bytes

Concurrency Level:      50
Time taken for tests:   211.032 seconds
Complete requests:      10000
Failed requests:        0
Total transferred:      131764472 bytes
Total body sent:        2740000
HTML transferred:       127710000 bytes
Requests per second:    47.39 [#/sec] (mean)
Time per request:       1055.162 [ms] (mean)
Time per request:       21.103 [ms] (mean, across all concurrent requests)
Transfer rate:          609.75 [Kbytes/sec] received
                        12.68 kb/s sent
                        622.43 kb/s total

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        8   88  44.0     84     415
Processing:    33  964  50.0    968    1054
Waiting:       33  964  50.0    968    1054
Total:         51 1052  26.7   1053    1423

Percentage of the requests served within a certain time (ms)
  50%   1053
  66%   1054
  75%   1054
  80%   1055
  90%   1057
  95%   1058
  98%   1060
  99%   1061
 100%   1423 (longest request)
```

## GPU(A800)

```shell
$ nvidia-smi
Sun Jan  5 20:51:58 2025
+---------------------------------------------------------------------------------------+
| NVIDIA-SMI 535.129.03             Driver Version: 535.129.03   CUDA Version: 12.2     |
|-----------------------------------------+----------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |         Memory-Usage | GPU-Util  Compute M. |
|                                         |                      |               MIG M. |
|=========================================+======================+======================|
|   0  NVIDIA A800-SXM4-80GB          Off | 00000000:3D:00.0 Off |                    0 |
| N/A   31C    P0              63W / 400W |  47846MiB / 81920MiB |      0%      Default |
|                                         |                      |             Disabled |
+-----------------------------------------+----------------------+----------------------+
|   1  NVIDIA A800-SXM4-80GB          Off | 00000000:42:00.0 Off |                    0 |
| N/A   28C    P0              66W / 400W |   6950MiB / 81920MiB |      0%      Default |
|                                         |                      |             Disabled |
+-----------------------------------------+----------------------+----------------------+
|   2  NVIDIA A800-SXM4-80GB          Off | 00000000:61:00.0 Off |                    0 |
| N/A   28C    P0              66W / 400W |  37006MiB / 81920MiB |      0%      Default |
|                                         |                      |             Disabled |
+-----------------------------------------+----------------------+----------------------+
|   3  NVIDIA A800-SXM4-80GB          Off | 00000000:67:00.0 Off |                    0 |
| N/A   32C    P0              61W / 400W |  34011MiB / 81920MiB |      0%      Default |
|                                         |                      |             Disabled |
+-----------------------------------------+----------------------+----------------------+
|   4  NVIDIA A800-SXM4-80GB          Off | 00000000:AD:00.0 Off |                    0 |
| N/A   32C    P0              64W / 400W |  35922MiB / 81920MiB |      0%      Default |
|                                         |                      |             Disabled |
+-----------------------------------------+----------------------+----------------------+
|   5  NVIDIA A800-SXM4-80GB          Off | 00000000:B1:00.0 Off |                    0 |
| N/A   27C    P0              61W / 400W |   3559MiB / 81920MiB |      0%      Default |
|                                         |                      |             Disabled |
+-----------------------------------------+----------------------+----------------------+
|   6  NVIDIA A800-SXM4-80GB          Off | 00000000:D0:00.0 Off |                    0 |
| N/A   26C    P0              54W / 400W |      5MiB / 81920MiB |      0%      Default |
|                                         |                      |             Disabled |
+-----------------------------------------+----------------------+----------------------+
|   7  NVIDIA A800-SXM4-80GB          Off | 00000000:D3:00.0 Off |                    0 |
| N/A   31C    P0              64W / 400W |  10116MiB / 81920MiB |      0%      Default |
|                                         |                      |             Disabled |
+-----------------------------------------+----------------------+----------------------+
```

```shell
echo '{"inputs":"基于Transformer架构的模型，使用双向编码器进行预训练，能够生成上下文信息丰富的词嵌入"}' > data.json
ab -n 10000 -c 50 -p data.json -T application/json http://127.0.0.1:58181/embed
This is ApacheBench, Version 2.3 <$Revision: 1430300 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

Benchmarking 127.0.0.1 (be patient)
Completed 1000 requests
Completed 2000 requests
Completed 3000 requests
Completed 4000 requests
Completed 5000 requests
Completed 6000 requests
Completed 7000 requests
Completed 8000 requests
Completed 9000 requests
Completed 10000 requests
Finished 10000 requests


Server Software:
Server Hostname:        127.0.0.1
Server Port:            58181

Document Path:          /embed
Document Length:        12765 bytes

Concurrency Level:      50
Time taken for tests:   12.957 seconds
Complete requests:      10000
Failed requests:        7938
   (Connect: 0, Receive: 0, Length: 7938, Exceptions: 0)
Write errors:           0
Total transferred:      131259083 bytes
Total body sent:        2750000
HTML transferred:       127285227 bytes
Requests per second:    771.80 [#/sec] (mean)
Time per request:       64.783 [ms] (mean)
Time per request:       1.296 [ms] (mean, across all concurrent requests)
Transfer rate:          9893.20 [Kbytes/sec] received
                        207.27 kb/s sent
                        10100.47 kb/s total

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    0   0.2      0       3
Processing:     5   64  15.8     63     144
Waiting:        5   64  15.8     62     143
Total:          8   64  15.8     63     144

Percentage of the requests served within a certain time (ms)
  50%     63
  66%     69
  75%     74
  80%     77
  90%     85
  95%     94
  98%    103
  99%    109
 100%    144 (longest request)
```

```shell
ab -n 10000 -c 100 -p data.json -T application/json http://127.0.0.1:58181/embed
This is ApacheBench, Version 2.3 <$Revision: 1430300 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

Benchmarking 127.0.0.1 (be patient)
Completed 1000 requests
Completed 2000 requests
Completed 3000 requests
Completed 4000 requests
Completed 5000 requests
Completed 6000 requests
Completed 7000 requests
Completed 8000 requests
Completed 9000 requests
Completed 10000 requests
Finished 10000 requests


Server Software:
Server Hostname:        127.0.0.1
Server Port:            58181

Document Path:          /embed
Document Length:        12765 bytes

Concurrency Level:      100
Time taken for tests:   12.255 seconds
Complete requests:      10000
Failed requests:        8254
   (Connect: 0, Receive: 0, Length: 8254, Exceptions: 0)
Write errors:           0
Total transferred:      131258675 bytes
Total body sent:        2750000
HTML transferred:       127284097 bytes
Requests per second:    815.96 [#/sec] (mean)
Time per request:       122.555 [ms] (mean)
Time per request:       1.226 [ms] (mean, across all concurrent requests)
Transfer rate:          10459.17 [Kbytes/sec] received
                        219.13 kb/s sent
                        10678.30 kb/s total

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    0   0.6      0       8
Processing:     6  122  25.2    119     222
Waiting:        6  121  25.2    119     221
Total:         14  122  25.1    120     222

Percentage of the requests served within a certain time (ms)
  50%    120
  66%    129
  75%    136
  80%    141
  90%    154
  95%    169
  98%    181
  99%    186
 100%    222 (longest request)
```
#### Sequence Classification

```shell
echo '{"inputs":"查询北京5G网络利用率"}' > data.json
ab -n 10000 -c 50 -p data.json -T application/json http://127.0.0.1:8080/predict

This is ApacheBench, Version 2.3 <$Revision: 1903618 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

Benchmarking 127.0.0.1 (be patient)
Completed 1000 requests
Completed 2000 requests
Completed 3000 requests
Completed 4000 requests
Completed 5000 requests
Completed 6000 requests
Completed 7000 requests
Completed 8000 requests
Completed 9000 requests
Completed 10000 requests
Finished 10000 requests


Server Software:
Server Hostname:        127.0.0.1
Server Port:            8080

Document Path:          /predict
Document Length:        122 bytes

Concurrency Level:      50
Time taken for tests:   86.422 seconds
Complete requests:      10000
Failed requests:        0
Total transferred:      5203129 bytes
Total body sent:        1850000
HTML transferred:       1220000 bytes
Requests per second:    115.71 [#/sec] (mean)
Time per request:       432.111 [ms] (mean)
Time per request:       8.642 [ms] (mean, across all concurrent requests)
Transfer rate:          58.79 [Kbytes/sec] received
20.90 kb/s sent
79.70 kb/s total

Connection Times (ms)
min  mean[+/-sd] median   max
Connect:       20  403  33.0    402     526
Processing:     9   28  12.8     27     319
Waiting:        9   28  12.8     27     319
Total:         41  431  35.2    429     787

Percentage of the requests served within a certain time (ms)
50%    429
66%    441
75%    448
80%    453
90%    468
95%    478
98%    499
99%    511
100%    787 (longest request)
```