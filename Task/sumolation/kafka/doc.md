# Kafka cho Java Developer

Tài liệu này tập trung vào Kafka dưới góc nhìn Java/Spring Boot Developer, đặc biệt phục vụ phỏng vấn Java Senior, Microservice và hệ thống event-driven.

Nếu cần ôn nhanh trước phỏng vấn, ưu tiên 10 chủ đề:

1. Topic & Partition
2. Consumer Group
3. Offset Management
4. Delivery Guarantee
5. Rebalance
6. Idempotent Producer
7. DLQ & Retry
8. Outbox Pattern
9. Kafka Transaction
10. Performance Tuning

## 1. Tổng quan Kafka

### 1.1 Kafka là gì?

Kafka là distributed event streaming platform, dùng để:

- Publish message/event từ producer.
- Lưu message/event bền vững theo topic/partition.
- Cho nhiều consumer đọc dữ liệu độc lập.
- Xử lý stream dữ liệu lớn, realtime hoặc near realtime.

Nói đơn giản:

```text
Producer gửi event -> Kafka lưu event -> Consumer đọc event theo nhu cầu.
```

Kafka không chỉ là message queue. Kafka giống một commit log phân tán:

- Message được append vào log.
- Consumer tự quản lý vị trí đọc bằng offset.
- Message không bị xóa ngay sau khi consumer đọc.
- Nhiều consumer group có thể đọc lại cùng một dữ liệu.

### 1.2 Khi nào nên dùng Kafka?

Nên dùng Kafka khi:

- Hệ thống microservice cần giao tiếp bất đồng bộ.
- Cần xử lý lượng message lớn.
- Cần decouple giữa service gửi và service nhận.
- Cần nhiều consumer group đọc cùng một stream dữ liệu.
- Cần replay message để rebuild dữ liệu.
- Cần event-driven architecture.
- Cần audit log/event history.
- Cần streaming data pipeline.

Ví dụ thực tế:

- Order service publish `OrderCreated`.
- Payment service consume để tạo payment.
- Inventory service consume để trừ kho.
- Email service consume để gửi email.
- Analytics service consume để thống kê.

Không nên dùng Kafka khi:

- Hệ thống rất nhỏ, chỉ cần call API đồng bộ đơn giản.
- Cần request/response tức thì.
- Cần queue task nhỏ, routing phức tạp, delay queue mạnh như RabbitMQ.
- Team chưa đủ khả năng vận hành broker, monitoring, lag, rebalance.

### 1.3 Kafka vs RabbitMQ

| Tiêu chí | Kafka | RabbitMQ |
|---|---|---|
| Mô hình chính | Distributed log/event streaming | Message broker/queue |
| Lưu message | Lưu theo retention, consumer đọc không làm mất message | Message thường bị ack xong là remove khỏi queue |
| Replay message | Mạnh, có thể reset offset đọc lại | Không phải use case chính |
| Throughput | Rất cao | Tốt nhưng thường thấp hơn Kafka ở workload streaming lớn |
| Ordering | Đảm bảo trong phạm vi partition | Đảm bảo trong queue nếu cấu hình đúng |
| Routing | Đơn giản hơn, theo topic/partition key | Mạnh với exchange/routing key |
| Consumer scale | Scale theo partition trong consumer group | Scale theo queue/consumer |
| Use case mạnh | Event streaming, log, analytics, microservice events | Task queue, command queue, routing phức tạp |
| Độ phức tạp vận hành | Cao hơn | Dễ tiếp cận hơn |

Kết luận:

- Dùng Kafka khi cần event stream, throughput cao, replay, nhiều consumer group.
- Dùng RabbitMQ khi cần message queue truyền thống, routing linh hoạt, task processing.

### 1.4 Ưu nhược điểm

Ưu điểm:

- Throughput cao.
- Scale ngang tốt bằng partition.
- Lưu message bền vững.
- Replay event dễ.
- Nhiều consumer group đọc độc lập.
- Phù hợp microservice/event-driven.
- Có replication và failover.

Nhược điểm:

- Vận hành phức tạp hơn queue đơn giản.
- Cần hiểu partition, offset, rebalance.
- Không đảm bảo global ordering trên toàn topic.
- Exactly once khó, cần hiểu transaction/idempotency.
- Consumer lag có thể gây trễ dữ liệu.
- Hot partition có thể làm mất cân bằng tải.

## 2. Kiến trúc Kafka

### 2.1 Broker

Broker là một server Kafka.

Nhiệm vụ:

- Nhận message từ producer.
- Lưu message vào partition.
- Phục vụ consumer đọc message.
- Replicate dữ liệu với broker khác.

Một Kafka cluster thường có nhiều broker.

### 2.2 Cluster

Cluster là tập hợp nhiều broker Kafka.

Mục tiêu:

- Scale dữ liệu.
- Chịu lỗi.
- Phân tán partition trên nhiều broker.
- Cho phép failover khi broker chết.

### 2.3 Topic

Topic là logical channel để phân loại message.

Ví dụ:

```text
order-created
payment-success
inventory-updated
email-requested
```

Producer gửi message vào topic. Consumer subscribe topic để đọc message.

### 2.4 Partition

Partition là phần chia nhỏ của topic.

Ví dụ topic `order-created` có 3 partition:

```text
order-created-0
order-created-1
order-created-2
```

Mỗi partition là một append-only log:

```text
offset 0 -> offset 1 -> offset 2 -> offset 3
```

Partition giúp Kafka:

- Scale ghi.
- Scale đọc.
- Phân tán dữ liệu qua nhiều broker.
- Đảm bảo ordering trong phạm vi một partition.

### 2.5 Producer

Producer là service gửi message vào Kafka.

Producer quyết định message vào partition nào dựa trên:

- Partition key.
- Custom partitioner.
- Round-robin/sticky partitioner nếu không có key.

### 2.6 Consumer

Consumer là service đọc message từ Kafka.

Consumer có thể:

- Đọc một hoặc nhiều topic.
- Đọc từ một hoặc nhiều partition.
- Commit offset để ghi nhận đã xử lý tới đâu.

### 2.7 Consumer Group

Consumer group là nhóm consumer cùng xử lý một topic.

Rule quan trọng:

```text
Trong cùng một consumer group, một partition chỉ được assign cho tối đa một consumer tại một thời điểm.
```

Ví dụ topic có 3 partition:

| Partition | Consumer trong group A |
|---|---|
| P0 | C1 |
| P1 | C2 |
| P2 | C3 |

Nếu group có 4 consumer nhưng topic chỉ có 3 partition:

- 3 consumer được assign partition.
- 1 consumer idle.

### 2.8 Offset

Offset là vị trí của message trong partition.

Ví dụ:

```text
partition-0:
offset 0: event A
offset 1: event B
offset 2: event C
```

Consumer commit offset để Kafka biết consumer group đã xử lý tới đâu.

Lưu ý:

- Offset chỉ có ý nghĩa trong một partition.
- Offset không global trên toàn topic.
- Mỗi consumer group có offset riêng.

## 3. Luồng hoạt động Kafka

### 3.1 Producer -> Topic -> Partition -> Consumer

Luồng cơ bản:

```text
Producer
  -> send message to topic
  -> Kafka chọn partition
  -> Broker append message vào partition log
  -> Consumer poll message
  -> Consumer xử lý
  -> Consumer commit offset
```

### 3.2 Cách message được lưu

Kafka lưu message trong partition log.

Đặc điểm:

- Message được append vào cuối log.
- Mỗi message có offset tăng dần.
- Message được giữ theo retention policy.
- Consumer đọc message không làm message biến mất.

Retention có thể theo:

- Thời gian: ví dụ giữ 7 ngày.
- Dung lượng: ví dụ giữ 100GB.
- Compaction: giữ bản mới nhất theo key.

### 3.3 Cách message được đọc

Consumer đọc bằng cơ chế polling:

```text
consumer.poll()
```

Consumer không được broker push message chủ động như một số queue truyền thống.

Ưu điểm:

- Consumer tự kiểm soát tốc độ đọc.
- Dễ batch processing.
- Dễ xử lý backpressure.

## 4. Topic & Partition

### 4.1 Tại sao cần partition?

Partition giải quyết 3 vấn đề:

- Scale ghi: producer có thể ghi song song vào nhiều partition.
- Scale đọc: consumer group có thể có nhiều consumer đọc song song.
- Chịu lỗi: partition có replica trên nhiều broker.

Nếu topic chỉ có 1 partition:

- Chỉ một consumer trong group có thể xử lý tại một thời điểm.
- Ordering dễ hơn.
- Throughput bị giới hạn.

Nếu topic có nhiều partition:

- Xử lý song song tốt hơn.
- Ordering chỉ đảm bảo trong từng partition.
- Cần chọn partition key cẩn thận.

### 4.2 Cách Kafka scale

Kafka scale bằng cách:

- Tăng số broker.
- Tăng số partition.
- Tăng số consumer trong consumer group.

Nhưng số consumer active tối đa trong một group bị giới hạn bởi số partition.

Ví dụ:

| Partition | Consumer group size | Consumer active |
|---:|---:|---:|
| 3 | 1 | 1 |
| 3 | 3 | 3 |
| 3 | 5 | 3 active, 2 idle |
| 10 | 5 | 5 |

### 4.3 Message ordering

Kafka chỉ đảm bảo thứ tự trong cùng một partition.

Không đảm bảo thứ tự global trên toàn topic nếu topic có nhiều partition.

Ví dụ:

```text
orderId = 1001 -> partition 0
orderId = 1002 -> partition 1
```

Event của order `1001` sẽ giữ thứ tự nếu luôn dùng key `1001`.

### 4.4 Partition key

Partition key quyết định message vào partition nào.

Ví dụ:

```text
key = orderId
```

Ưu điểm:

- Event cùng order vào cùng partition.
- Giữ ordering theo order.

Rủi ro:

- Nếu một key quá hot, partition đó bị quá tải.
- Dẫn tới hot partition.

Best practice:

- Chọn key theo entity cần đảm bảo ordering.
- Ví dụ `orderId`, `userId`, `accountId`.
- Tránh key quá ít giá trị như `status`, `type`.

## 5. Replication

### 5.1 Replica factor

Replication factor là số bản sao của partition.

Ví dụ:

```text
replication.factor = 3
```

Mỗi partition có 3 replica trên các broker khác nhau.

Mục tiêu:

- Chịu lỗi broker chết.
- Tăng độ bền dữ liệu.

### 5.2 Leader/Follower

Mỗi partition có:

- 1 leader replica.
- N follower replicas.

Producer ghi vào leader. Consumer thường đọc từ leader. Follower replicate dữ liệu từ leader.

### 5.3 ISR

ISR là In-Sync Replicas.

ISR gồm các replica đang theo kịp leader.

Nếu follower lag quá xa, nó bị loại khỏi ISR.

ISR quan trọng vì:

- `acks=all` chờ các replica trong ISR xác nhận.
- Failover nên chọn leader mới từ ISR.

### 5.4 Failover

Khi broker chứa leader chết:

- Kafka controller chọn một follower trong ISR làm leader mới.
- Producer/consumer metadata refresh.
- Hệ thống tiếp tục hoạt động.

Rủi ro:

- Nếu không có ISR đủ tốt, có thể mất availability hoặc mất dữ liệu tùy config.

Config liên quan:

```properties
min.insync.replicas=2
acks=all
unclean.leader.election.enable=false
```

## 6. Producer

### 6.1 Cấu hình Producer quan trọng

| Config | Ý nghĩa | Gợi ý |
|---|---|---|
| `bootstrap.servers` | Danh sách broker để kết nối | Ít nhất 2-3 broker |
| `key.serializer` | Serializer cho key | String/Avro/JSON |
| `value.serializer` | Serializer cho value | JSON/Avro/Protobuf |
| `acks` | Mức xác nhận ghi | `all` nếu cần an toàn |
| `retries` | Số lần retry khi lỗi tạm thời | Bật retry |
| `batch.size` | Kích thước batch gửi | Tăng để tăng throughput |
| `linger.ms` | Chờ gom batch | 5-20ms tùy workload |
| `compression.type` | Nén message | `snappy`, `lz4`, `zstd` |
| `enable.idempotence` | Chống duplicate do retry | Nên bật |

### 6.2 Acks

`acks` quyết định khi nào producer coi send là thành công.

| acks | Ý nghĩa | Rủi ro |
|---|---|---|
| `0` | Không chờ broker xác nhận | Có thể mất message |
| `1` | Chờ leader ghi thành công | Leader chết trước khi replicate có thể mất message |
| `all` | Chờ leader và ISR xác nhận | An toàn hơn, latency cao hơn |

Cho hệ thống quan trọng:

```properties
acks=all
enable.idempotence=true
min.insync.replicas=2
```

### 6.3 Retries

Retry giúp producer gửi lại khi lỗi tạm thời:

- Network glitch.
- Leader election.
- Broker tạm unavailable.

Rủi ro:

- Nếu không bật idempotence, retry có thể tạo duplicate.

### 6.4 Batch processing

Producer gom nhiều message thành batch để tăng throughput.

Config:

```properties
batch.size=32768
linger.ms=10
```

Trade-off:

- Batch lớn tăng throughput.
- Nhưng tăng latency.

### 6.5 Compression

Compression giảm network và disk usage.

Config:

```properties
compression.type=snappy
```

Gợi ý:

- `snappy`: cân bằng CPU/throughput.
- `lz4`: nhanh.
- `zstd`: nén tốt, tốn CPU hơn.

### 6.6 Idempotent Producer

Idempotent producer giúp tránh duplicate do retry ở producer.

Config:

```properties
enable.idempotence=true
acks=all
retries>0
```

Ý nghĩa:

- Producer gửi lại cùng message nhưng broker nhận biết và không append duplicate trong cùng producer session.

Lưu ý:

- Không giải quyết duplicate do application tự gửi lại business event.
- Consumer vẫn nên xử lý idempotent.

## 7. Consumer

### 7.1 Consumer Group

Consumer group giúp scale xử lý message.

Ví dụ:

```text
email-service-group
inventory-service-group
analytics-service-group
```

Mỗi group có offset riêng.

Một event có thể được xử lý bởi nhiều service khác nhau nếu mỗi service dùng group khác nhau.

### 7.2 Offset Management

Offset cho biết consumer group đã xử lý tới đâu.

Offset được commit vào internal topic:

```text
__consumer_offsets
```

Consumer có thể:

- Auto commit.
- Manual commit.

### 7.3 Auto Commit

Auto commit:

```properties
enable.auto.commit=true
auto.commit.interval.ms=5000
```

Ưu điểm:

- Dễ dùng.

Nhược điểm:

- Có thể commit trước khi xử lý xong.
- Nếu app crash sau commit nhưng trước xử lý xong -> message loss về mặt business.

### 7.4 Manual Commit

Manual commit nghĩa là app chủ động commit sau khi xử lý thành công.

Spring Kafka:

```java
@KafkaListener(topics = "order-created", groupId = "payment-service")
public void listen(OrderCreatedEvent event, Acknowledgment ack) {
    process(event);
    ack.acknowledge();
}
```

Ưu điểm:

- Kiểm soát tốt hơn.
- Phù hợp hệ thống cần at-least-once.

Nhược điểm:

- Cần xử lý duplicate.
- Code phức tạp hơn.

## 8. Delivery Semantics

### 8.1 At Most Once

Message được xử lý tối đa một lần.

Flow:

```text
Commit offset trước -> xử lý message sau
```

Nếu consumer crash sau commit nhưng trước xử lý:

- Message bị mất về mặt xử lý.

Dùng khi:

- Chấp nhận mất message.
- Log/metric không quan trọng tuyệt đối.

### 8.2 At Least Once

Message được xử lý ít nhất một lần.

Flow:

```text
Xử lý message xong -> commit offset
```

Nếu consumer crash sau xử lý nhưng trước commit:

- Message sẽ được đọc lại.
- Có thể duplicate.

Dùng nhiều nhất trong microservice.

Yêu cầu:

- Consumer xử lý idempotent.
- DB có unique key hoặc processed event table.

### 8.3 Exactly Once

Exactly once nghĩa là kết quả xử lý cuối cùng chỉ được apply một lần trong phạm vi được Kafka hỗ trợ.

Kafka hỗ trợ exactly-once mạnh với:

- Idempotent producer.
- Kafka transaction.
- Read-process-write trong Kafka.

Nhưng nếu consumer ghi vào external DB:

- Exactly once end-to-end khó hơn.
- Cần transaction/outbox/idempotency.

Kết luận phỏng vấn:

```text
Kafka có thể hỗ trợ exactly-once trong Kafka ecosystem, nhưng khi liên quan DB ngoài Kafka thì cần thiết kế idempotent hoặc outbox/inbox pattern.
```

### 8.4 Kafka Transaction

Kafka transaction dùng để đảm bảo một nhóm thao tác produce message được commit hoặc abort cùng nhau.

Use case phổ biến:

```text
Consume topic A
  -> xử lý
  -> produce topic B
  -> commit consumer offset
```

Nếu dùng Kafka transaction, producer có thể:

- Gửi nhiều message vào nhiều topic/partition trong cùng transaction.
- Commit offset consumer cùng transaction với output message.
- Abort transaction nếu xử lý lỗi.

Config producer:

```properties
enable.idempotence=true
transactional.id=payment-service-01
acks=all
```

Flow đơn giản:

```text
producer.initTransactions()
producer.beginTransaction()
producer.send(outputTopic, message)
producer.sendOffsetsToTransaction(offsets, consumerGroupMetadata)
producer.commitTransaction()
```

Nếu lỗi:

```text
producer.abortTransaction()
```

Lưu ý phỏng vấn:

- Kafka transaction mạnh khi input và output đều nằm trong Kafka.
- Nếu consumer vừa ghi DB vừa produce Kafka thì Kafka transaction không tự đảm bảo atomic với DB.
- Với DB ngoài Kafka, nên dùng Outbox Pattern hoặc idempotent consumer.
- `transactional.id` phải ổn định theo producer instance, không random mỗi lần start.

## 9. Rebalance

### 9.1 Rebalance là gì?

Rebalance là quá trình Kafka phân phối lại partition cho các consumer trong group.

Ví dụ:

- Consumer mới join group.
- Consumer cũ rời group.
- Partition tăng.
- Consumer bị timeout.

### 9.2 Khi nào xảy ra?

Rebalance xảy ra khi:

- Consumer start/stop.
- Consumer crash.
- Consumer xử lý quá lâu không poll.
- Network issue.
- Topic partition thay đổi.
- Deploy rolling update.

Config liên quan:

| Config | Ý nghĩa |
|---|---|
| `session.timeout.ms` | Consumer mất heartbeat bao lâu thì bị coi là chết |
| `heartbeat.interval.ms` | Tần suất gửi heartbeat |
| `max.poll.interval.ms` | Khoảng cách tối đa giữa hai lần poll |
| `max.poll.records` | Số record tối đa mỗi poll |

### 9.3 Ảnh hưởng đến hệ thống

Trong lúc rebalance:

- Consumer có thể pause xử lý.
- Partition bị revoke/assign lại.
- Lag tăng.
- Nếu xử lý không idempotent có thể duplicate.

Giảm tác động:

- Tránh xử lý quá lâu trong listener thread.
- Tune `max.poll.interval.ms`.
- Giảm `max.poll.records`.
- Dùng static membership.
- Dùng cooperative rebalancing.

## 10. Error Handling

### 10.1 Retry

Retry dùng cho lỗi tạm thời:

- Timeout gọi service khác.
- DB deadlock.
- Network glitch.

Không retry vô hạn trong consumer chính vì có thể block partition.

### 10.2 Dead Letter Queue

DLQ là topic chứa message xử lý thất bại sau retry.

Ví dụ:

```text
order-created
order-created.retry
order-created.dlq
```

DLQ dùng để:

- Không block consumer chính.
- Lưu message lỗi để điều tra.
- Cho phép replay sau khi fix bug.

### 10.3 Poison Message

Poison message là message luôn gây lỗi khi consumer xử lý.

Ví dụ:

- JSON sai schema.
- Data thiếu field bắt buộc.
- Business state không hợp lệ.

Cách xử lý:

- Validate schema.
- Retry có giới hạn.
- Đẩy DLQ.
- Alert nếu DLQ tăng.

## 11. Performance Tuning

### 11.1 Producer tuning

| Config | Tác dụng | Trade-off |
|---|---|---|
| `batch.size` | Tăng kích thước batch | Tăng memory |
| `linger.ms` | Chờ thêm để gom batch | Tăng latency |
| `compression.type` | Giảm network/disk | Tốn CPU |
| `acks` | Độ an toàn ghi | `all` latency cao hơn |
| `buffer.memory` | Bộ nhớ producer buffer | Quá thấp dễ block |

### 11.2 Consumer tuning

| Config | Tác dụng | Trade-off |
|---|---|---|
| `fetch.min.bytes` | Broker chờ đủ bytes mới trả | Tăng throughput, tăng latency |
| `fetch.max.wait.ms` | Thời gian chờ fetch | Tăng latency nếu cao |
| `max.poll.records` | Số record mỗi poll | Quá cao dễ xử lý lâu |
| `max.poll.interval.ms` | Thời gian xử lý tối đa giữa poll | Quá thấp dễ rebalance |

### 11.3 batch.size

`batch.size` càng lớn producer càng gom được nhiều message.

Phù hợp:

- Throughput cao.
- Message nhỏ.

Không phù hợp:

- Low latency strict.

### 11.4 linger.ms

`linger.ms` là thời gian producer chờ để gom batch.

Ví dụ:

```properties
linger.ms=10
```

Producer có thể đợi tối đa 10ms trước khi gửi batch.

### 11.5 compression.type

Gợi ý:

```properties
compression.type=snappy
```

Nếu message lớn và CPU đủ:

```properties
compression.type=zstd
```

### 11.6 fetch.min.bytes

Consumer fetch tuning:

```properties
fetch.min.bytes=1024
fetch.max.wait.ms=500
```

Broker sẽ chờ đủ data hoặc tới timeout mới trả response.

## 12. Monitoring

### 12.1 Consumer Lag

Consumer lag là số message chưa được consumer xử lý.

```text
lag = latest offset - committed offset
```

Lag cao nghĩa là consumer xử lý chậm hơn tốc độ message vào.

Nguyên nhân:

- Consumer xử lý chậm.
- Message tăng đột biến.
- Partition quá ít.
- Downstream DB/API chậm.
- Rebalance storm.

### 12.2 Throughput

Theo dõi:

- Message per second.
- Bytes in/out per second.
- Produce latency.
- Fetch latency.

### 12.3 Broker Health

Theo dõi:

- Broker alive.
- Under-replicated partitions.
- Offline partitions.
- ISR shrink/expand.
- Disk usage.
- Network IO.
- Controller status.

### 12.4 Grafana / Prometheus

Stack thường dùng:

```text
Kafka JMX Exporter -> Prometheus -> Grafana
```

Dashboard nên có:

- Consumer lag by group/topic.
- Broker disk usage.
- Bytes in/out.
- Request latency.
- Under replicated partitions.
- JVM heap/GC.

## 13. Security

### 13.1 SSL

SSL dùng để encrypt traffic giữa:

- Client và broker.
- Broker và broker.

Mục tiêu:

- Tránh nghe lén dữ liệu.
- Xác thực certificate nếu dùng mTLS.

### 13.2 SASL

SASL dùng để authentication.

Các cơ chế:

- SASL/PLAIN.
- SASL/SCRAM.
- SASL/GSSAPI Kerberos.
- SASL/OAUTHBEARER.

### 13.3 ACL

ACL dùng để authorization.

Ví dụ:

- Service A chỉ được write topic `order-created`.
- Service B chỉ được read topic `order-created`.
- Không cho service lạ delete topic.

Best practice:

- Mỗi service có principal riêng.
- Không dùng super user cho app.
- Grant quyền tối thiểu.

## 14. Spring Boot Kafka

### 14.1 Dependency

```xml
<dependency>
    <groupId>org.springframework.kafka</groupId>
    <artifactId>spring-kafka</artifactId>
</dependency>
```

### 14.2 application.yml mẫu

```yaml
spring:
  kafka:
    bootstrap-servers: localhost:9092
    producer:
      key-serializer: org.apache.kafka.common.serialization.StringSerializer
      value-serializer: org.springframework.kafka.support.serializer.JsonSerializer
      properties:
        acks: all
        enable.idempotence: true
        compression.type: snappy
        linger.ms: 10
        batch.size: 32768
    consumer:
      group-id: payment-service
      key-deserializer: org.apache.kafka.common.serialization.StringDeserializer
      value-deserializer: org.springframework.kafka.support.serializer.JsonDeserializer
      enable-auto-commit: false
      properties:
        spring.json.trusted.packages: "*"
        max.poll.records: 100
    listener:
      ack-mode: manual
```

### 14.3 KafkaTemplate

`KafkaTemplate` dùng để producer gửi message.

```java
@Service
public class OrderEventProducer {

    private final KafkaTemplate<String, OrderCreatedEvent> kafkaTemplate;

    public OrderEventProducer(KafkaTemplate<String, OrderCreatedEvent> kafkaTemplate) {
        this.kafkaTemplate = kafkaTemplate;
    }

    public void publish(OrderCreatedEvent event) {
        kafkaTemplate.send("order-created", event.orderId(), event);
    }
}
```

Key là `orderId` để đảm bảo event cùng order vào cùng partition.

### 14.4 @KafkaListener

```java
@KafkaListener(topics = "order-created", groupId = "payment-service")
public void consume(OrderCreatedEvent event, Acknowledgment ack) {
    try {
        paymentService.createPayment(event);
        ack.acknowledge();
    } catch (Exception ex) {
        throw ex;
    }
}
```

### 14.5 Retry

Spring Kafka hỗ trợ retry bằng `DefaultErrorHandler`.

Ý tưởng:

- Retry lỗi tạm thời vài lần.
- Sau đó đẩy message sang DLQ.

### 14.6 DLQ

Ví dụ topic:

```text
order-created
order-created.DLT
```

DLQ nên lưu:

- Message gốc.
- Error reason.
- Stack trace hoặc error code.
- Thời điểm lỗi.

## 15. Kafka Design Patterns

### 15.1 Event-Driven Architecture

Service giao tiếp bằng event.

Ví dụ:

```text
Order Service -> OrderCreated -> Payment Service
                            -> Inventory Service
                            -> Email Service
```

Ưu điểm:

- Decouple service.
- Scale độc lập.
- Dễ mở rộng consumer mới.

Nhược điểm:

- Eventual consistency.
- Debug phức tạp.
- Cần tracing/correlation id.

### 15.2 Saga Pattern

Saga dùng để quản lý transaction phân tán.

Ví dụ order flow:

```text
Create Order
  -> Reserve Inventory
  -> Create Payment
  -> Confirm Order
```

Nếu payment fail:

```text
Release Inventory
Cancel Order
```

Saga có hai kiểu:

- Choreography: các service nghe event và tự phản ứng.
- Orchestration: một orchestrator điều phối các bước.

### 15.3 Outbox Pattern

Outbox pattern giải quyết vấn đề:

```text
DB commit thành công nhưng publish Kafka fail
```

Cách làm:

1. Trong cùng DB transaction, ghi business data và ghi event vào outbox table.
2. Background worker/Debezium đọc outbox.
3. Publish event sang Kafka.
4. Mark event đã publish.

Ưu điểm:

- Không mất event khi DB commit thành công.
- Đảm bảo atomic giữa DB change và event record.

### 15.4 CQRS

CQRS tách:

- Command model: ghi dữ liệu.
- Query model: đọc dữ liệu.

Kafka dùng để đồng bộ event từ write model sang read model.

Ví dụ:

```text
OrderCreated -> update order_read_model
PaymentSuccess -> update customer_order_summary
```

## 16. Các vấn đề thực tế

### 16.1 Duplicate Message

Nguyên nhân:

- Producer retry.
- Consumer xử lý xong nhưng chưa commit offset thì crash.
- Rebalance.
- Provider gửi lại event.

Cách xử lý:

- Idempotent consumer.
- Unique business key.
- Processed event table.
- Upsert thay vì insert mù.

### 16.2 Message Loss

Nguyên nhân:

- `acks=0` hoặc `acks=1` không đủ an toàn.
- Auto commit trước khi xử lý.
- Retention quá ngắn.
- Unclean leader election.

Cách giảm:

- `acks=all`.
- `enable.idempotence=true`.
- Manual commit sau xử lý.
- `min.insync.replicas >= 2`.
- Monitoring under-replicated partitions.

### 16.3 Consumer Lag

Nguyên nhân:

- Consumer xử lý chậm.
- Downstream chậm.
- Partition quá ít.
- Message tăng đột biến.

Cách xử lý:

- Tăng consumer nhưng không vượt quá partition.
- Tăng partition nếu cần.
- Batch processing.
- Tối ưu DB/API downstream.
- Tách topic theo workload.

### 16.4 Hot Partition

Nguyên nhân:

- Partition key phân bố không đều.
- Một key quá nhiều message.

Ví dụ:

```text
key = merchantId
```

Nếu một merchant chiếm 80% traffic, partition đó sẽ hot.

Cách xử lý:

- Chọn key phân bố đều hơn.
- Thêm shard key.
- Tách topic riêng cho tenant lớn.

### 16.5 Rebalance Storm

Rebalance storm là rebalance xảy ra liên tục.

Nguyên nhân:

- Consumer xử lý quá lâu.
- `max.poll.interval.ms` quá thấp.
- App deploy liên tục.
- Network unstable.

Cách xử lý:

- Tune poll config.
- Giảm `max.poll.records`.
- Dùng static membership.
- Dùng cooperative rebalancing.
- Tách xử lý nặng khỏi listener thread.

## 17. Câu hỏi phỏng vấn Kafka

### 17.1 Offset là gì?

Offset là vị trí của message trong một partition. Consumer group commit offset để ghi nhận đã xử lý tới đâu.

Điểm cần nói:

- Offset là per partition.
- Mỗi consumer group có offset riêng.
- Offset lưu trong `__consumer_offsets`.

### 17.2 Consumer Group hoạt động thế nào?

Consumer group là nhóm consumer cùng xử lý một topic.

Trong cùng group:

- Một partition chỉ assign cho một consumer tại một thời điểm.
- Nhiều consumer giúp xử lý song song.
- Số consumer active tối đa bằng số partition.

### 17.3 Kafka đảm bảo thứ tự ra sao?

Kafka đảm bảo ordering trong phạm vi một partition.

Muốn event cùng entity đúng thứ tự:

- Dùng cùng partition key, ví dụ `orderId`.

Không có global ordering nếu topic có nhiều partition.

### 17.4 At Least Once và Exactly Once khác nhau thế nào?

At least once:

- Message được xử lý ít nhất một lần.
- Có thể duplicate.
- Cần idempotent consumer.

Exactly once:

- Kết quả cuối cùng chỉ apply một lần trong phạm vi thiết kế.
- Kafka hỗ trợ trong read-process-write với transaction.
- Với external DB cần outbox/idempotency.

### 17.5 ISR là gì?

ISR là In-Sync Replicas, danh sách replica đang theo kịp leader.

ISR quan trọng vì:

- `acks=all` chờ ISR xác nhận.
- Failover chọn leader mới từ ISR.

### 17.6 Outbox Pattern là gì?

Outbox pattern là cách đảm bảo DB change và event được ghi atomic.

Flow:

```text
DB transaction:
  - Update business table
  - Insert outbox_event

Worker/Debezium:
  - Read outbox_event
  - Publish Kafka
```

Giải quyết lỗi:

```text
DB commit thành công nhưng publish Kafka thất bại.
```

## 18. Trả lời phỏng vấn theo kiểu senior

Khi gặp câu hỏi Kafka, nên trả lời theo công thức:

```text
1. Nói khái niệm.
2. Nói trade-off.
3. Nói config liên quan.
4. Nói cách xử lý production.
5. Nói cách monitor.
```

Ví dụ câu hỏi: "Làm sao tránh mất message?"

Trả lời tốt:

- Producer dùng `acks=all`, `enable.idempotence=true`, retry.
- Topic có replication factor >= 3.
- Broker set `min.insync.replicas=2`.
- Tắt unclean leader election nếu ưu tiên consistency.
- Consumer manual commit sau khi xử lý thành công.
- Consumer xử lý idempotent để chịu duplicate.
- Monitor under-replicated partitions và consumer lag.
