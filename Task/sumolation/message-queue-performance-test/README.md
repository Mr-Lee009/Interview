# Kịch bản test hiệu năng Kafka và RabbitMQ

Thư mục này chứa bộ tài liệu và file dựng môi trường benchmark (đo hiệu năng) cho 2 hệ thống message queue / event streaming:

- `kafka/`: Kafka Cluster 3 broker, Kafka UI và script benchmark.
- `rabbitmq/`: RabbitMQ Cluster 3 node, Management UI và script benchmark.

## 1. Mục tiêu test

- Đo **throughput** (số message xử lý mỗi giây).
- Đo **latency** (độ trễ gửi/nhận message).
- Đo ảnh hưởng của **replication** (sao chép dữ liệu giữa các node).
- Đo ảnh hưởng của **message size** (kích thước message).
- Đo khi **consumer chậm** (consumer xử lý không kịp).
- Đo khi tăng số **producer** (bên gửi message) và **consumer** (bên đọc message).

## 2. Dung lượng tối đa của 1 message

| Hệ thống | Mặc định | Có thể tăng đến đâu? | Ghi chú |
|---|---:|---:|---|
| Kafka | Khoảng 1 MB/message | Có thể tăng bằng config, nhưng không nên lạm dụng | Cần chỉnh đồng bộ broker, topic, producer, consumer và replica fetch |
| RabbitMQ 4.x | 16 MB/message | Tối đa 512 MB/message | Cấu hình bằng `max_message_size` |

## 3. Kafka: giới hạn message cần hiểu

- Kafka không phù hợp để gửi message quá lớn.
- Mặc định thường gặp:
  - `max.message.bytes`: giới hạn message batch ở broker/topic, khoảng 1 MB.
  - `max.request.size`: giới hạn request phía producer, mặc định khoảng 1 MB.
- Nếu muốn gửi message lớn hơn, cần chỉnh đồng bộ:
  - Broker: `message.max.bytes`
  - Topic: `max.message.bytes`
  - Producer: `max.request.size`
  - Consumer: `fetch.max.bytes`, `max.partition.fetch.bytes`
  - Replica: `replica.fetch.max.bytes`
- Khuyến nghị thực tế:
  - Với Kafka, nên giữ message nhỏ, thường vài KB đến dưới 1 MB.
  - Nếu payload lớn như ảnh, file PDF, video, nên lưu file ở object storage như S3/MinIO rồi gửi URL hoặc object key qua Kafka.

## 4. RabbitMQ: giới hạn message cần hiểu

- RabbitMQ có cấu hình `max_message_size`.
- Theo tài liệu RabbitMQ 4.3:
  - Mặc định: `16777216` bytes, tương đương 16 MB.
  - Max value: `536870912` bytes, tương đương 512 MB.
- Dù RabbitMQ cho phép message lớn hơn Kafka mặc định, không nên gửi file lớn trực tiếp qua RabbitMQ.
- Với file lớn, cũng nên dùng object storage rồi gửi reference qua queue.

Nguồn chính thức:

- Kafka documentation: https://kafka.apache.org/documentation/
- RabbitMQ configuration `max_message_size`: https://www.rabbitmq.com/docs/configure

## 5. Công cụ benchmark

| Hệ thống | Công cụ | Dùng để làm gì |
|---|---|---|
| Kafka | `kafka-producer-perf-test.sh` | Đo tốc độ producer gửi message |
| Kafka | `kafka-consumer-perf-test.sh` | Đo tốc độ consumer đọc message |
| Kafka | Kafka UI | Xem topic, partition, consumer group |
| RabbitMQ | RabbitMQ PerfTest | Đo publish rate, consume rate, latency |
| RabbitMQ | RabbitMQ Management UI | Xem queue, exchange, connection, queue depth |
| Chung | Docker stats | Xem CPU/RAM/network của container |
| Chung | k6/JMeter/Gatling | Test qua API ứng dụng thật nếu cần |

## 6. Kịch bản test đề xuất

| Case | Message size | Producer | Consumer | Replication | Mục tiêu |
|---|---:|---:|---:|---|---|
| Baseline nhỏ | 1 KB | 1 | 1 | Có | Lấy số nền |
| Tải vừa | 10 KB | 3 | 3 | Có | Gần event nghiệp vụ |
| Tải lớn | 100 KB | 3 | 3 | Có | Kiểm tra network/disk |
| Tải rất lớn | 1 MB | 3 | 3 | Có | Chạm vùng giới hạn Kafka mặc định |
| Consumer chậm | 10 KB | 3 | 1 | Có | Xem lag/queue depth |
| Scale consumer | 10 KB | 3 | 6 | Có | Xem hệ thống scale ra sao |
| Failover | 10 KB | 3 | 3 | Có | Tắt 1 broker/node khi đang chạy |

## 7. Cách chạy Kafka benchmark

```powershell
cd Task\sumolation\message-queue-performance-test\kafka
docker compose up -d
.\scripts\create-topic.ps1
.\scripts\benchmark-producer.ps1
.\scripts\benchmark-consumer.ps1
```

Kafka UI:

```text
http://localhost:8085
```

## 8. Cách chạy RabbitMQ benchmark

```powershell
cd Task\sumolation\message-queue-performance-test\rabbitmq
docker compose up -d
.\scripts\setup-quorum-queue.ps1
.\scripts\benchmark-perftest.ps1
```

RabbitMQ Management UI:

```text
http://localhost:15672
User: admin
Password: admin123
```

## 9. Cách đọc kết quả

- Kafka:
  - Nếu throughput tăng khi tăng partition và consumer, Kafka scale tốt.
  - Nếu consumer lag tăng liên tục, consumer xử lý không kịp.
  - Nếu broker CPU thấp nhưng disk/network cao, bottleneck nằm ở disk/network.
- RabbitMQ:
  - Nếu queue depth tăng liên tục, worker xử lý không kịp.
  - Nếu quorum queue chậm, kiểm tra replication và queue leader.
  - Nếu memory alarm hoặc disk alarm xuất hiện, cần giảm tải hoặc tăng tài nguyên.

## 10. Checklist để so sánh công bằng

- Dùng cùng message size.
- Dùng cùng số producer/consumer.
- Dùng cùng số node/broker.
- Dùng cùng replication level.
- Chạy test đủ lâu, tối thiểu 5 phút/case.
- Chạy ít nhất 3 lần và lấy trung bình.
- Ghi lại CPU, RAM, disk, network cùng với throughput/latency.
