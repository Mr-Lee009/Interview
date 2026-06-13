# So sánh hiệu suất Kafka Cluster và RabbitMQ Cluster

Tài liệu này trả lời câu hỏi phỏng vấn: nếu **Kafka Cluster** (cụm Kafka nhiều broker) và **RabbitMQ Cluster** (cụm RabbitMQ nhiều node) đều có **leader/master** (node chính nhận xử lý) và **replica/follower** (node bản sao đồng bộ dữ liệu), thì hiệu suất khác nhau như thế nào và nên chọn hệ thống nào.

## 1. Kết luận nhanh

- **Kafka** thường mạnh hơn về **throughput** (số lượng message xử lý được trong một khoảng thời gian).
- **RabbitMQ** thường mạnh hơn về **routing** (định tuyến message đến đúng queue) và có thể có **latency** (độ trễ xử lý) rất thấp với message nhỏ, queue gọn, consumer xử lý nhanh.
- Nếu hỏi "cái nào nhanh hơn?", câu trả lời đúng nên là:
  - Kafka nhanh hơn về tổng lượng message lớn.
  - RabbitMQ có thể nhanh hơn về độ trễ cho **task** (công việc nền nhỏ) và routing đơn giản.
  - Chọn hệ thống nào phải dựa vào bài toán, không chỉ dựa vào tốc độ.

## 2. Bảng so sánh tổng quan

| Tiêu chí | Kafka Cluster | RabbitMQ Cluster |
|---|---|---|
| Mục tiêu chính | **Event streaming** (luồng sự kiện), lưu event lâu dài, throughput cao | **Message broker** (trung gian nhận/gửi message), **task queue** (hàng đợi công việc), routing linh hoạt |
| Cách lưu message | **Append-only log** (ghi nối tiếp vào cuối file log) trên disk | **Queue-based message storage** (lưu message theo hàng đợi) |
| Scale ngang | Rất tốt thông qua **partition** (phân vùng dữ liệu của topic) | Có scale nhưng phụ thuộc **queue leader** (node chính của queue) và cách chia queue |
| Throughput | Rất cao | Trung bình đến cao |
| Latency | Thấp, nhưng thường tối ưu cho **batch/stream** (xử lý theo lô/luồng) | Rất thấp với message nhỏ và queue không quá tải |
| Replay message | Rất mạnh, đọc lại theo **offset** (vị trí đã đọc trong log) | Không phải use case tự nhiên |
| Routing | Đơn giản hơn RabbitMQ | Rất mạnh qua **exchange** (bộ định tuyến), **routing key** (khóa định tuyến), **binding** (luật nối exchange với queue) |
| Retention | Lưu theo thời gian hoặc dung lượng | Thường message được xóa sau khi consumer **ack** (xác nhận đã xử lý) |
| Consumer model | Consumer tự quản lý offset | Broker quản lý delivery/ack |
| Phù hợp | **Event log** (nhật ký sự kiện), analytics, audit, fraud detection, tracking | Background job, command, email, workflow, RPC-like task |

## 3. Kafka Cluster hoạt động như thế nào?

- Kafka không có một **master** (node điều phối duy nhất) cho toàn bộ hệ thống message.
- Kafka chia dữ liệu theo:
  - **Topic** (chủ đề chứa các message cùng loại).
  - **Partition** (phân vùng nhỏ của topic để scale và xử lý song song).
- Mỗi partition có:
  - **Leader** (node chính): nhận ghi/đọc cho partition đó.
  - **Follower Replica** (bản sao theo sau): đồng bộ dữ liệu từ leader.
  - **ISR / In-Sync Replicas** (nhóm replica đang đồng bộ tốt): các bản sao đủ mới để có thể được chọn làm leader khi lỗi.
- **Producer** (thành phần gửi message) ghi message vào leader partition.
- **Consumer** (thành phần đọc message) đọc message từ partition.
- Khi leader chết, Kafka chọn một replica trong ISR lên làm leader mới.

Ví dụ:

```text
Topic: payment-events

Partition 0 -> Leader: Broker 1, Follower: Broker 2, Broker 3
Partition 1 -> Leader: Broker 2, Follower: Broker 1, Broker 3
Partition 2 -> Leader: Broker 3, Follower: Broker 1, Broker 2
```

Ý nghĩa:

- Tải được chia đều theo partition.
- Mỗi partition có leader khác nhau, nên cluster tận dụng được nhiều **broker** (server Kafka).
- Khi cần tăng throughput, có thể tăng số partition và scale **consumer group** (nhóm consumer cùng xử lý một topic).

## 4. RabbitMQ Cluster hoạt động như thế nào?

- RabbitMQ là **message broker** (hệ thống trung gian nhận, định tuyến và giao message).
- Message được gửi vào:
  - **Exchange** (bộ định tuyến message).
  - Sau đó route vào **Queue** (hàng đợi message) dựa trên routing key và binding.
- Với RabbitMQ hiện đại, nếu cần **high availability** (tính sẵn sàng cao), thường dùng **Quorum Queue** (queue có nhiều bản sao và dùng cơ chế đồng thuận).
- Mỗi quorum queue có:
  - **Leader** (node chính): xử lý queue.
  - **Follower** (node bản sao): giữ dữ liệu sao chép.
  - **Raft** (thuật toán đồng thuận): đảm bảo các replica thống nhất dữ liệu.

Ví dụ:

```text
Exchange: order.exchange
Routing key: order.created
Queue: order-created.queue

Queue Leader: RabbitMQ Node 1
Queue Follower: RabbitMQ Node 2, RabbitMQ Node 3
```

Ý nghĩa:

- Queue có độ bền tốt hơn nhờ replica.
- Nếu leader chết, follower có thể được bầu làm leader mới.
- Nhưng một **hot queue** (queue có tải quá cao) có thể bị giới hạn bởi leader của queue đó.

## 5. Vì sao Kafka thường có throughput cao hơn?

- Kafka ghi message theo kiểu **append-only log** (ghi nối tiếp vào cuối file):
  - Ghi tuần tự vào disk.
  - Ít **random I/O** (đọc/ghi ngẫu nhiên trên ổ đĩa) hơn.
  - Tận dụng **OS page cache** (bộ nhớ đệm của hệ điều hành) tốt.
- Kafka xử lý message theo **batch** (gom nhiều message xử lý một lần):
  - Producer có thể gom nhiều message rồi gửi một lần.
  - Consumer có thể **fetch** (lấy dữ liệu) nhiều message trong một lần đọc.
- Kafka scale bằng partition:
  - Nhiều partition có thể nằm trên nhiều broker.
  - Nhiều consumer trong cùng consumer group có thể xử lý song song.
- Kafka không xóa message ngay sau khi consumer đọc:
  - Consumer chỉ **commit offset** (ghi nhận vị trí đã xử lý).
  - Message vẫn được giữ theo **retention policy** (chính sách lưu giữ dữ liệu).

Kết luận:

- Nếu hệ thống cần xử lý lượng event rất lớn, Kafka thường vượt RabbitMQ về throughput tổng thể.

## 6. Vì sao RabbitMQ vẫn rất mạnh trong nhiều bài toán?

- RabbitMQ mạnh ở routing:
  - **Direct exchange** (định tuyến theo routing key chính xác).
  - **Topic exchange** (định tuyến theo pattern, ví dụ `order.*`).
  - **Fanout exchange** (phát message đến tất cả queue được binding).
  - **Headers exchange** (định tuyến theo header của message).
- RabbitMQ phù hợp với task queue:
  - **Worker** (tiến trình xử lý job) nhận job.
  - Xử lý xong thì ack.
  - Lỗi thì **retry** (thử lại) hoặc đưa vào **Dead Letter Queue / DLQ** (queue chứa message lỗi).
- RabbitMQ có thể có latency rất thấp khi:
  - Message nhỏ.
  - Queue không quá dài.
  - Consumer xử lý nhanh.
  - Không bật quá nhiều cơ chế **persistence** (lưu bền xuống disk) và replication nặng.

Ví dụ phù hợp với RabbitMQ:

- Gửi email sau khi user đăng ký.
- Xử lý resize ảnh.
- Gửi notification.
- Điều phối background job.
- Routing message theo loại nghiệp vụ.

## 7. Khi bật replication thì hiệu suất thay đổi thế nào?

| Vấn đề | Kafka | RabbitMQ |
|---|---|---|
| Replication (sao chép dữ liệu) làm chậm không? | Có | Có |
| Mức ảnh hưởng | Thường kiểm soát tốt nếu partition hợp lý | Có thể rõ hơn nếu quorum queue nhiều replica |
| Điểm nghẽn chính | Partition leader, disk, network, **consumer lag** (độ trễ consumer xử lý so với message mới nhất) | Queue leader, ack, disk, network, consumer chậm |
| Cách scale | Tăng partition, thêm broker, thêm consumer | Chia queue, thêm consumer, tối ưu **prefetch** (số message broker gửi trước cho consumer)/ack |

- Với Kafka:
  - Nếu `replication.factor = 3`, message cần được replicate sang nhiều broker.
  - Nếu `acks=all`, producer chờ ISR xác nhận, an toàn hơn nhưng latency tăng.
  - Kafka vẫn giữ throughput tốt nếu partition được phân bố đều.
- Với RabbitMQ:
  - Quorum Queue replicate message giữa nhiều node.
  - An toàn hơn **classic queue** (queue truyền thống, ít cơ chế HA mạnh hơn quorum queue).
  - Nhưng throughput có thể giảm do cần đồng thuận giữa các replica.

## 8. Ví dụ chọn hệ thống theo bài toán

### Case 1: Ngân hàng kiểm tra giao dịch nghi ngờ

- Bài toán:
  - Hàng trăm nghìn giao dịch/phút.
  - Cần lưu **audit** (dữ liệu phục vụ kiểm tra, truy vết).
  - Nhiều service cùng đọc event: **fraud detection** (phát hiện gian lận), notification, reporting, risk engine.
  - Cần replay event khi service lỗi.
- Nên chọn:
  - **Kafka**.
- Lý do:
  - Throughput cao.
  - Lưu event lâu dài.
  - Có thể replay.
  - Scale tốt bằng partition.

### Case 2: Website cần gửi email và xử lý background job

- Bài toán:
  - User đăng ký xong thì gửi email.
  - Đơn hàng tạo xong thì gửi notification.
  - Worker xử lý từng task và ack.
- Nên chọn:
  - **RabbitMQ**.
- Lý do:
  - Routing linh hoạt.
  - Mô hình queue/worker rõ ràng.
  - Retry và dead letter queue dễ hiểu.

### Case 3: Hệ thống event-driven nhiều service cần đọc lại dữ liệu

- Bài toán:
  - `Order Service` phát event.
  - `Payment Service`, `Inventory Service`, `Shipping Service`, `Analytics Service` cùng đọc.
  - Một service chết vài giờ, sau đó cần đọc lại event bị **miss** (bỏ lỡ/chưa xử lý).
- Nên chọn:
  - **Kafka**.
- Lý do:
  - Consumer đọc theo offset riêng.
  - Message không bị xóa ngay sau khi một consumer đọc.
  - Dễ replay theo offset/time.

### Case 4: Cần route message theo nhiều rule nghiệp vụ

- Bài toán:
  - Message loại `order.created` đi vào queue A.
  - Message loại `order.cancelled` đi vào queue B.
  - Message theo **region** (khu vực) hoặc **priority** (độ ưu tiên) đi vào queue khác nhau.
- Nên chọn:
  - **RabbitMQ**.
- Lý do:
  - Exchange và routing key rất mạnh.
  - Topic exchange phù hợp routing theo pattern.

## 9. Cách trả lời phỏng vấn

Nếu interviewer hỏi:

> Kafka và RabbitMQ đều chạy cluster, đều có master/leader, vậy hiệu suất thế nào?

Có thể trả lời:

- Kafka và RabbitMQ đều có cơ chế leader/follower hoặc master/replica, nhưng mục tiêu thiết kế khác nhau.
- Kafka tối ưu cho event streaming và throughput lớn bằng append-only log, batch processing và partition.
- RabbitMQ tối ưu cho message broker, routing linh hoạt và task queue.
- Khi bật replication, cả hai đều chậm hơn single node vì phải đồng bộ dữ liệu.
- Kafka thường giữ throughput tốt hơn khi tăng partition và consumer group.
- RabbitMQ có thể gặp **bottleneck** (điểm nghẽn hiệu suất) ở queue leader nếu một queue quá nóng.
- Nếu cần xử lý event lớn, lưu lâu, replay, audit: chọn Kafka.
- Nếu cần queue job, routing message linh hoạt, worker ack từng task: chọn RabbitMQ.

## 10. Checklist chọn Kafka hay RabbitMQ

| Câu hỏi | Nên nghiêng về |
|---|---|
| Cần throughput cực lớn? | Kafka |
| Cần replay message? | Kafka |
| Cần lưu event lâu dài để audit? | Kafka |
| Cần nhiều consumer độc lập đọc cùng một event? | Kafka |
| Cần task queue đơn giản? | RabbitMQ |
| Cần routing phức tạp? | RabbitMQ |
| Cần worker ack từng job? | RabbitMQ |
| Cần retry/DLQ dễ hiểu cho background job? | RabbitMQ |
| Cần **event-driven architecture** (kiến trúc hướng sự kiện) quy mô lớn? | Kafka |
| Cần xử lý **command/task** (lệnh/công việc nghiệp vụ)? | RabbitMQ |

## 11. Kết luận

- Kafka không chỉ là queue, mà là **distributed event log** (nhật ký sự kiện phân tán).
- RabbitMQ là message broker mạnh về routing và **task delivery** (giao việc cho worker xử lý).
- Kafka thường thắng về throughput và khả năng replay.
- RabbitMQ thường thắng về routing linh hoạt và mô hình worker queue dễ dùng.
- Trong phỏng vấn, không nên nói tuyệt đối "Kafka nhanh hơn" hoặc "RabbitMQ nhanh hơn".
- Câu trả lời tốt là nêu rõ:
  - Nhanh theo tiêu chí nào.
  - Bài toán cần gì.
  - Có cần replay không.
  - Có cần routing phức tạp không.
  - Có cần scale bằng partition không.
  - Có cần worker ack từng task không.

## 12. Làm sao test hiệu năng Kafka và RabbitMQ?

Khi benchmark (đo hiệu năng), không nên chỉ đo "gửi được bao nhiêu message". Cần đo cả throughput, latency, CPU, RAM, disk, network, replication và độ ổn định khi broker/node bị lỗi.

### Công cụ nên dùng

| Nhu cầu | Kafka | RabbitMQ | Ghi chú |
|---|---|---|---|
| Test throughput producer | `kafka-producer-perf-test.sh` | RabbitMQ PerfTest | Đo tốc độ gửi message |
| Test throughput consumer | `kafka-consumer-perf-test.sh` | RabbitMQ PerfTest | Đo tốc độ đọc/xử lý message |
| Benchmark chuẩn nhiều hệ thống | OpenMessaging Benchmark | OpenMessaging Benchmark | Dùng khi muốn so sánh công bằng hơn |
| Test qua API ứng dụng | k6, JMeter, Gatling | k6, JMeter, Gatling | Đo từ góc nhìn application |
| Monitoring Kafka | Prometheus JMX Exporter, Grafana, Kafka UI | Không áp dụng | Theo dõi broker, topic, consumer lag |
| Monitoring RabbitMQ | Không áp dụng | RabbitMQ Management UI, Prometheus plugin, Grafana | Theo dõi queue depth, ack rate, publish rate |
| Quan sát hạ tầng | Docker stats, Prometheus Node Exporter, Grafana | Docker stats, Prometheus Node Exporter, Grafana | Đo CPU, RAM, disk, network |

### Công cụ Kafka cần biết

- `kafka-producer-perf-test.sh`: công cụ có sẵn trong Kafka để test tốc độ producer gửi message.
- `kafka-consumer-perf-test.sh`: công cụ có sẵn trong Kafka để test tốc độ consumer đọc message.
- Kafka UI: giao diện xem topic, partition, consumer group, offset.
- Prometheus JMX Exporter: export metric JVM/Kafka ra Prometheus.
- Grafana: vẽ dashboard theo dõi throughput, latency, consumer lag, broker health.

Ví dụ metric cần đo với Kafka:

- **Producer throughput** (số message producer gửi được mỗi giây).
- **Consumer throughput** (số message consumer đọc được mỗi giây).
- **Consumer lag** (consumer đang chậm hơn topic bao nhiêu message).
- **Request latency p95/p99** (95% hoặc 99% request có độ trễ dưới ngưỡng bao nhiêu).
- **Disk I/O** (tốc độ đọc/ghi disk).
- **Network I/O** (lưu lượng mạng giữa producer, broker, consumer).
- **Under replicated partitions** (partition chưa đủ replica đồng bộ).

### Công cụ RabbitMQ cần biết

- RabbitMQ PerfTest: công cụ chính thức thường dùng để benchmark RabbitMQ.
- RabbitMQ Management UI: giao diện web để xem queue, exchange, connection, channel, publish rate, deliver rate.
- RabbitMQ Prometheus plugin: export metric RabbitMQ ra Prometheus.
- Grafana: vẽ dashboard RabbitMQ.
- `rabbitmq-diagnostics`: kiểm tra trạng thái node, cluster, memory, alarm.

Ví dụ metric cần đo với RabbitMQ:

- **Publish rate** (số message publish vào broker mỗi giây).
- **Deliver rate** (số message broker giao cho consumer mỗi giây).
- **Ack rate** (số message consumer xác nhận đã xử lý mỗi giây).
- **Queue depth** (số message đang tồn trong queue).
- **Redelivered messages** (message bị giao lại do retry/nack/consumer lỗi).
- **Node memory** (RAM của RabbitMQ node).
- **Disk free alarm** (cảnh báo thiếu disk).
- **Quorum queue leader balance** (leader của queue có phân bố đều giữa các node không).

## 13. Kịch bản benchmark nên chạy

Không nên test một kịch bản duy nhất. Nên chạy nhiều case để biết hệ thống phù hợp với tải thật.

| Kịch bản | Mục tiêu |
|---|---|
| Single producer, single consumer | Đo baseline đơn giản |
| Nhiều producer, nhiều consumer | Đo khả năng scale |
| Message nhỏ, ví dụ 1 KB | Đo throughput cao nhất |
| Message vừa, ví dụ 10 KB | Gần với event nghiệp vụ thực tế |
| Message lớn, ví dụ 100 KB trở lên | Kiểm tra network/disk bottleneck |
| Replication bật | Đo ảnh hưởng của replica/follower |
| Persistence bật | Đo khi message cần lưu bền xuống disk |
| Broker/node bị tắt giữa chừng | Đo failover và khả năng phục hồi |
| Consumer xử lý chậm | Đo consumer lag hoặc queue depth |
| Retry/DLQ | Đo ảnh hưởng khi message lỗi |

### Kafka nên test các biến số này

- `acks=1` và `acks=all`: so sánh tốc độ và độ an toàn.
- `replication.factor=1` và `replication.factor=3`: đo ảnh hưởng replication.
- Số partition: ví dụ 3, 6, 12, 24.
- Số producer thread.
- Số consumer trong consumer group.
- `batch.size`: kích thước batch producer.
- `linger.ms`: thời gian producer chờ để gom batch.
- `compression.type`: `none`, `gzip`, `snappy`, `lz4`, `zstd`.

### RabbitMQ nên test các biến số này

- Classic Queue và Quorum Queue.
- Message durable hoặc non-durable.
- Persistent message hoặc transient message.
- Số producer.
- Số consumer.
- `prefetch`: số message broker gửi trước cho consumer.
- Manual ack và auto ack.
- Queue đơn và nhiều queue chia tải.
- Exchange type: direct, topic, fanout.

## 14. Cách đọc kết quả benchmark

- Nếu throughput cao nhưng latency p99 rất lớn, hệ thống có thể không phù hợp với request cần phản hồi nhanh.
- Nếu Kafka consumer lag tăng liên tục, consumer đang xử lý chậm hơn tốc độ message vào.
- Nếu RabbitMQ queue depth tăng liên tục, worker không xử lý kịp.
- Nếu CPU thấp nhưng disk I/O cao, bottleneck nằm ở disk.
- Nếu disk thấp nhưng network cao, bottleneck nằm ở network.
- Nếu bật replication mà throughput giảm mạnh, cần kiểm tra network giữa broker/node và cấu hình replica.
- Nếu RabbitMQ quorum queue chậm, cần kiểm tra queue leader có bị dồn vào một node không.
- Nếu Kafka chỉ có ít partition, thêm consumer cũng không tăng hiệu năng nhiều vì một partition chỉ được xử lý bởi một consumer trong cùng consumer group.

## 15. Cấu hình test tối thiểu nên có

- Máy test producer/consumer nên tách khỏi máy chạy broker nếu muốn kết quả khách quan.
- Chạy mỗi test ít nhất 3 lần rồi lấy trung bình.
- Mỗi lần test nên đủ dài, ví dụ 5 đến 15 phút, không chỉ vài giây.
- Ghi lại đầy đủ:
  - Số broker/node.
  - CPU/RAM/disk/network.
  - Message size.
  - Số producer/consumer.
  - Replication/persistence.
  - Throughput trung bình.
  - Latency p50/p95/p99.
  - Error rate.

## 16. Kết luận thực hành

- Muốn test Kafka: bắt đầu với `kafka-producer-perf-test.sh`, `kafka-consumer-perf-test.sh`, Kafka UI, Prometheus và Grafana.
- Muốn test RabbitMQ: bắt đầu với RabbitMQ PerfTest, RabbitMQ Management UI, Prometheus plugin và Grafana.
- Muốn so sánh công bằng hơn: dùng OpenMessaging Benchmark, cùng message size, cùng số producer/consumer, cùng replication level và cùng phần cứng.
- Muốn test giống production: bắn tải qua chính service Spring Boot bằng k6/JMeter/Gatling, vì hiệu năng thực tế còn phụ thuộc code application, serialize JSON, database, retry, logging và network.
