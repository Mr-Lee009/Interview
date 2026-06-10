# So sánh Kafka, Redis và RabbitMQ

Tài liệu này so sánh các hệ thống message/event thường gặp trong backend/microservice:

- Kafka
- RabbitMQ
- Redis Pub/Sub
- Redis Streams

Mục tiêu: giúp chọn đúng công cụ theo bài toán, không chọn theo trend.

## 1. Bảng chọn nhanh

| Nhu cầu | Nên dùng | Lý do |
|---|---|---|
| Event streaming, throughput lớn, nhiều consumer group, cần replay | Kafka | Kafka lưu event bền vững theo log, scale tốt bằng partition |
| Task queue, job queue, routing linh hoạt, command processing | RabbitMQ | RabbitMQ mạnh về queue, exchange, routing key, ack/nack |
| Broadcast realtime cực nhẹ, không cần lưu message | Redis Pub/Sub | Đơn giản, latency thấp, nhưng không durable |
| Queue nhẹ có lưu lịch sử, consumer group đơn giản | Redis Streams | Có persistence, consumer group, dễ dùng hơn Kafka cho workload nhỏ |
| Microservice event-driven quy mô lớn | Kafka | Nhiều service có thể consume cùng event độc lập |
| Gửi email/background job | RabbitMQ hoặc Redis Streams | Không cần Kafka nếu chỉ là task queue |
| Chat notification realtime, online event | Redis Pub/Sub | Latency thấp, message không cần replay |
| Audit log, fraud detection, data pipeline | Kafka | Cần lưu event, replay, scale và retention |
| Delayed/retry workflow phức tạp | RabbitMQ | Có plugin/delay exchange, DLQ, routing linh hoạt |

## 2. So sánh tổng quan

| Tiêu chí | Kafka | RabbitMQ | Redis Pub/Sub | Redis Streams |
|---|---|---|---|---|
| Loại hệ thống | Distributed event streaming/log | Message broker/queue | In-memory pub/sub | In-memory stream/log |
| Mô hình chính | Topic + Partition + Offset | Exchange + Queue + Binding | Channel publish/subscribe | Stream + Consumer Group |
| Lưu message | Có, trên disk theo retention | Có, trong queue tới khi ack | Không lưu cho subscriber offline | Có, trong stream |
| Replay message | Mạnh | Không phải use case chính | Không | Có, theo stream id |
| Consumer group | Có | Có kiểu competing consumers trên queue | Không | Có |
| Ordering | Trong cùng partition | Trong queue nếu cấu hình đúng | Theo publish realtime, không durable | Theo stream |
| Throughput | Rất cao | Cao nhưng thường thấp hơn Kafka ở streaming lớn | Rất cao, nhẹ | Cao, phù hợp workload vừa/nhỏ |
| Latency | Thấp, nhưng tối ưu throughput | Thấp | Rất thấp | Thấp |
| Routing | Cơ bản | Rất mạnh | Rất đơn giản | Đơn giản |
| Persistence | Mạnh | Có | Không | Có nếu Redis persistence bật |
| Scale ngang | Mạnh bằng partition/broker | Có, nhưng routing/queue cần thiết kế | Redis Cluster phức tạp với Pub/Sub | Có giới hạn hơn Kafka |
| Vận hành | Phức tạp hơn | Vừa phải | Đơn giản | Đơn giản/vừa |
| Use case chính | Event stream, analytics, data pipeline | Task queue, command queue, routing | Realtime notification | Lightweight durable stream |

## 3. Kafka

### 3.1 Kafka là gì?

Kafka là distributed event streaming platform. Kafka lưu message/event vào append-only log trên disk.

Producer gửi event vào topic. Topic chia thành partition. Consumer group đọc event theo offset.

### 3.2 Khi nào dùng Kafka?

| Case | Vì sao Kafka phù hợp |
|---|---|
| Event-driven microservice | Nhiều service có thể consume cùng event |
| Fraud detection realtime | Giao dịch là event stream lớn, cần xử lý gần realtime |
| Audit/event log | Kafka lưu event theo retention, có thể replay |
| Data pipeline | Đẩy dữ liệu sang data lake, warehouse, search |
| Analytics realtime | Throughput lớn, consumer group scale tốt |
| CDC với Debezium | DB change được stream vào Kafka |

### 3.3 Ưu điểm

| Ưu điểm | Giải thích |
|---|---|
| Throughput cao | Append log, batch, compression, partition |
| Replay mạnh | Consumer có thể reset offset đọc lại |
| Nhiều consumer group độc lập | Một event có thể phục vụ nhiều hệ thống |
| Scale ngang tốt | Tăng broker/partition/consumer |
| Durable | Message lưu trên disk và replication |
| Phù hợp event sourcing/audit | Event được giữ theo retention |

### 3.4 Nhược điểm

| Nhược điểm | Giải thích |
|---|---|
| Vận hành phức tạp | Cần quản lý broker, partition, replication, lag |
| Không phải task queue đơn giản | Routing/delay/retry không tiện bằng RabbitMQ |
| Ordering bị giới hạn | Chỉ đảm bảo trong partition |
| Cần hiểu offset/rebalance | Sai offset có thể duplicate/loss |
| Hot partition | Key phân bố không đều làm nghẽn partition |

### 3.5 Không nên dùng Kafka khi nào?

- Hệ thống nhỏ, chỉ cần gửi job đơn giản.
- Cần routing phức tạp theo nhiều điều kiện.
- Cần delay queue dễ dùng.
- Team chưa sẵn sàng vận hành Kafka.
- Không cần replay, không cần nhiều consumer group.

## 4. RabbitMQ

### 4.1 RabbitMQ là gì?

RabbitMQ là message broker theo mô hình queue. Producer gửi message vào exchange, exchange route message vào queue, consumer consume queue và ack/nack.

### 4.2 Khi nào dùng RabbitMQ?

| Case | Vì sao RabbitMQ phù hợp |
|---|---|
| Background job | Worker consume queue và ack sau khi xử lý |
| Email/SMS queue | Task rõ ràng, cần retry/DLQ |
| Command processing | Một command nên được một worker xử lý |
| Routing linh hoạt | Exchange/routing key rất mạnh |
| Delay/retry queue | Có TTL, DLX, delayed exchange plugin |
| RPC-style async | RabbitMQ hỗ trợ reply queue/correlation id |

### 4.3 Ưu điểm

| Ưu điểm | Giải thích |
|---|---|
| Routing mạnh | Direct, topic, fanout, headers exchange |
| Ack/nack rõ ràng | Phù hợp task queue |
| Retry/DLQ dễ thiết kế | TTL + DLX hoặc plugin |
| Dễ hiểu hơn Kafka | Mô hình queue quen thuộc |
| Low latency | Phù hợp job/command xử lý nhanh |

### 4.4 Nhược điểm

| Nhược điểm | Giải thích |
|---|---|
| Replay không mạnh | Message ack xong thường mất khỏi queue |
| Không tối ưu cho event stream lớn | Kafka phù hợp hơn cho log/streaming |
| Scale kiểu khác Kafka | Không phải cứ thêm partition như Kafka |
| Nhiều queue/routing phức tạp có thể khó quản lý | Cần discipline naming/routing |

### 4.5 Không nên dùng RabbitMQ khi nào?

- Cần lưu event nhiều ngày và replay thường xuyên.
- Cần nhiều consumer group độc lập đọc cùng stream.
- Cần data pipeline throughput cực lớn.
- Cần event log phân tán lâu dài.

## 5. Redis Pub/Sub

### 5.1 Redis Pub/Sub là gì?

Redis Pub/Sub là cơ chế publish/subscribe realtime trong Redis.

Producer publish message vào channel. Subscriber đang online nhận message.

### 5.2 Khi nào dùng Redis Pub/Sub?

| Case | Vì sao phù hợp |
|---|---|
| Realtime notification nhẹ | Latency rất thấp |
| WebSocket fan-out nội bộ | Broadcast message cho node đang online |
| Cache invalidation | Báo các instance xóa cache |
| Local event trong hệ thống nhỏ | Đơn giản, ít vận hành |

### 5.3 Ưu điểm

| Ưu điểm | Giải thích |
|---|---|
| Rất đơn giản | Redis có sẵn |
| Latency thấp | In-memory pub/sub |
| Dễ tích hợp | Không cần Kafka/RabbitMQ nếu use case rất nhẹ |

### 5.4 Nhược điểm

| Nhược điểm | Giải thích |
|---|---|
| Không durable | Subscriber offline sẽ mất message |
| Không replay | Không có offset để đọc lại |
| Không consumer group | Không chia tải kiểu Kafka/RabbitMQ |
| Không phù hợp giao dịch quan trọng | Dễ mất event |

### 5.5 Không nên dùng Redis Pub/Sub khi nào?

- Payment, banking, order critical event.
- Cần đảm bảo message không mất.
- Cần retry/DLQ.
- Cần replay.
- Consumer có thể offline.

## 6. Redis Streams

### 6.1 Redis Streams là gì?

Redis Streams là cấu trúc stream log trong Redis, hỗ trợ message id, consumer group và ack.

Khác Pub/Sub:

- Streams có lưu message.
- Consumer offline có thể đọc lại.
- Có consumer group.

### 6.2 Khi nào dùng Redis Streams?

| Case | Vì sao phù hợp |
|---|---|
| Queue nhẹ có persistence | Dễ hơn Kafka |
| Hệ thống nhỏ/vừa đã dùng Redis | Không cần thêm broker mới |
| Job processing vừa phải | Có consumer group và ack |
| Event nội bộ cần lưu ngắn hạn | Redis stream đủ dùng |

### 6.3 Ưu điểm

| Ưu điểm | Giải thích |
|---|---|
| Có persistence | Message nằm trong stream |
| Có consumer group | Có thể chia tải |
| Dễ dùng nếu đã có Redis | Ít thêm hạ tầng |
| Latency thấp | Redis in-memory |

### 6.4 Nhược điểm

| Nhược điểm | Giải thích |
|---|---|
| Không mạnh bằng Kafka cho stream lớn | Scale/retention/replay dài hạn kém hơn |
| Dữ liệu phụ thuộc Redis memory/persistence | Cần cấu hình RDB/AOF đúng |
| Monitoring ecosystem ít hơn Kafka | Kafka mạnh hơn cho event pipeline lớn |
| Không thay thế RabbitMQ cho routing phức tạp | Routing của Redis Streams đơn giản |

## 7. Bảng so sánh theo tiêu chí thiết kế

| Câu hỏi thiết kế | Kafka | RabbitMQ | Redis Pub/Sub | Redis Streams |
|---|---|---|---|---|
| Cần message durable? | Có | Có | Không | Có |
| Cần replay nhiều lần? | Rất tốt | Hạn chế | Không | Có, nhưng giới hạn hơn Kafka |
| Cần nhiều hệ thống đọc cùng event? | Rất tốt | Có thể fanout nhưng không phải log replay | Chỉ subscriber online | Có thể |
| Cần task queue worker xử lý? | Được nhưng không tối ưu bằng RabbitMQ | Rất tốt | Không phù hợp | Tốt cho workload nhỏ/vừa |
| Cần routing phức tạp? | Hạn chế | Rất tốt | Không | Hạn chế |
| Cần delay/retry queue? | Cần tự thiết kế | Rất tốt | Không | Cần tự thiết kế |
| Cần throughput cực cao? | Rất tốt | Tốt | Rất tốt nhưng không durable | Tốt |
| Cần ordering? | Trong partition | Trong queue | Realtime channel | Trong stream |
| Cần vận hành đơn giản? | Khó hơn | Vừa | Dễ | Dễ/vừa |
| Phù hợp banking critical event? | Có | Có cho command/task | Không | Có thể, nhưng cân nhắc kỹ |

## 8. Case thực tế nên chọn gì?

### 8.1 Hệ thống kiểm tra giao dịch nghi ngờ ngân hàng

Nên dùng:

```text
Kafka
```

Lý do:

- Event giao dịch lớn.
- Nhiều consumer group: fraud, audit, data lake, notification.
- Cần replay để điều tra.
- Cần scale theo partition.

Không dùng Redis Pub/Sub vì message có thể mất.

### 8.2 Gửi email sau khi user đăng ký

Nên dùng:

```text
RabbitMQ hoặc Redis Streams
```

Lý do:

- Đây là background job.
- Cần retry/DLQ.
- Không nhất thiết cần Kafka.

Nếu hệ thống đã có Kafka và event `UserRegistered` còn được nhiều service khác consume, dùng Kafka cũng ổn.

### 8.3 Cache invalidation giữa nhiều instance

Nên dùng:

```text
Redis Pub/Sub
```

Lý do:

- Event nhẹ.
- Không cần replay.
- Mất một message invalidation có thể chấp nhận nếu có TTL.

### 8.4 Order event trong microservice lớn

Nên dùng:

```text
Kafka
```

Lý do:

- `OrderCreated` có thể được nhiều service consume.
- Cần audit/replay.
- Cần scale.

### 8.5 Worker xử lý upload ảnh/video

Nên dùng:

```text
RabbitMQ
```

Lý do:

- Task queue rõ ràng.
- Retry/DLQ tiện.
- Mỗi task nên một worker xử lý.

### 8.6 Notification realtime cho WebSocket

Nên dùng:

```text
Redis Pub/Sub hoặc Redis Streams
```

Lý do:

- Pub/Sub nếu chỉ gửi cho user online.
- Streams nếu cần user offline vẫn đọc lại thông báo.

## 9. Ưu tiên chọn theo câu hỏi

| Nếu câu hỏi là... | Chọn |
|---|---|
| "Tôi cần event log, replay, nhiều consumer group" | Kafka |
| "Tôi cần queue task, retry, DLQ, routing" | RabbitMQ |
| "Tôi cần broadcast realtime, mất message cũng được" | Redis Pub/Sub |
| "Tôi cần queue nhẹ, có lưu message, đã có Redis" | Redis Streams |
| "Tôi cần xử lý giao dịch ngân hàng/audit/fraud" | Kafka |
| "Tôi cần gửi email/job nền" | RabbitMQ |
| "Tôi cần cache invalidation" | Redis Pub/Sub |

## 10. Lỗi chọn sai công nghệ

| Chọn sai | Hậu quả |
|---|---|
| Dùng Redis Pub/Sub cho payment event | Consumer offline là mất event, rất nguy hiểm |
| Dùng Kafka cho task queue nhỏ | Tăng độ phức tạp vận hành không cần thiết |
| Dùng RabbitMQ cho audit log cần replay dài hạn | Khó replay và phân tích stream lâu dài |
| Dùng Redis Streams cho data pipeline lớn | Có thể gặp giới hạn scale/retention/monitoring |
| Dùng Kafka nhưng không hiểu partition key | Hot partition, mất ordering theo business |

## 11. Kết luận leader

Không có hệ thống nào tốt nhất cho mọi bài toán.

Quyết định nên dựa trên:

- Có cần durable không?
- Có cần replay không?
- Có bao nhiêu consumer group?
- Có cần routing phức tạp không?
- Message có critical không?
- Throughput bao nhiêu?
- Team có vận hành được không?

Rule ngắn:

```text
Kafka: event stream lớn, replay, nhiều consumer group.
RabbitMQ: task queue, command queue, routing/retry/DLQ.
Redis Pub/Sub: realtime nhẹ, không cần lưu.
Redis Streams: queue/stream nhẹ có persistence, phù hợp hệ thống nhỏ/vừa.
```

