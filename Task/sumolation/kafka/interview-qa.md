# Kafka và RabbitMQ - Bộ câu hỏi phỏng vấn thực chiến

Tài liệu này trả lời ngắn gọn nhưng đủ chiều sâu cho các câu hỏi phỏng vấn thường gặp quanh `Kafka`, `RabbitMQ`, `Redis cache` và xử lý lỗi consumer.

## 1. Kafka và RabbitMQ khác gì nhau?

### Ý ngắn gọn

- `Kafka` mạnh về `event streaming`, throughput lớn, retention dài, replay message.
- `RabbitMQ` mạnh về `message queue` truyền thống, routing linh hoạt, xử lý command/task queue.

### So sánh theo góc nhìn phỏng vấn

| Tiêu chí | Kafka | RabbitMQ |
|---|---|---|
| Mô hình chính | Distributed log | Message broker / queue |
| Cách lưu message | Append vào log, giữ theo retention | Message nằm trong queue, ack xong thường bị remove |
| Replay message | Rất mạnh, reset offset đọc lại được | Không phải use case chính |
| Throughput | Rất cao, hợp workload streaming lớn | Tốt nhưng thường thấp hơn Kafka ở tải rất lớn |
| Consumer | Chủ động poll | Broker push theo cơ chế queue |
| Multi-consumer | Nhiều consumer group đọc độc lập cùng một event | Thường thiên về chia việc giữa các consumer |
| Routing | Đơn giản hơn, chủ yếu topic/partition/key | Rất mạnh với exchange, binding, routing key |
| Ordering | Đảm bảo trong từng partition | Đảm bảo trong queue nếu cấu hình phù hợp |
| Use case mạnh | Event bus, analytics, audit, stream processing | Task queue, command queue, workflow, retry/delay |

### Kết luận nên trả lời

- Nếu cần `event-driven`, `throughput cao`, `replay`, `nhiều hệ cùng đọc một stream`, chọn `Kafka`.
- Nếu cần `queue tác vụ`, `routing linh hoạt`, `delay/retry workflow`, chọn `RabbitMQ`.

## 2. Offset của Kafka là gì?

`Offset` là vị trí của một message trong `một partition`.

Ví dụ:

```text
partition-0
offset 100 -> event A
offset 101 -> event B
offset 102 -> event C
```

### Những ý bắt buộc nên nói

- Offset là `per partition`, không phải global trên toàn topic.
- Mỗi `consumer group` có offset riêng.
- Consumer commit offset để đánh dấu đã xử lý tới đâu.
- Offset thường được lưu trong topic nội bộ `__consumer_offsets`.

### Ý nghĩa thực tế

Offset giúp Kafka biết:

- consumer group đang đọc tới đâu
- khi restart thì đọc tiếp từ đâu
- khi cần replay thì có thể reset offset để đọc lại

## 3. Khi nào thì nên dùng Kafka?

Nên dùng Kafka khi hệ thống có một hoặc nhiều đặc điểm sau:

- lượng event lớn
- cần xử lý realtime hoặc near realtime
- nhiều service cần consume cùng một dữ liệu
- cần replay để rebuild cache, read model, analytics
- cần audit trail hoặc lưu lịch sử event
- cần scale ngang bằng partition và consumer group

### Ví dụ phù hợp

- hệ thống đặt lệnh, thanh toán, giao dịch
- tracking hành vi user
- log pipeline
- fraud detection
- notification fan-out cho nhiều hệ
- đồng bộ dữ liệu giữa các microservice

### Khi không nên dùng Kafka

- chỉ cần queue đơn giản giữa 2 service
- cần request/response đồng bộ
- hệ thống nhỏ, traffic thấp, team chưa sẵn sàng vận hành Kafka
- cần routing message phức tạp hơn là streaming

## 4. Hệ thống đặt lệnh chứng khoán nhận 50.000 lệnh/giây. Chọn RabbitMQ hay Kafka? Vì sao?

### Câu trả lời ngắn

Tôi sẽ ưu tiên `Kafka`.

### Lý do

`50.000 lệnh/giây` là bài toán throughput lớn, cần khả năng scale ngang và chịu tải ổn định. Kafka phù hợp hơn vì:

- ghi tuần tự theo log nên throughput rất cao
- scale bằng `partition`
- nhiều consumer group có thể cùng đọc:
  - matching/risk engine
  - audit
  - monitoring
  - analytics
  - downstream settlement
- có retention để replay khi cần điều tra hoặc rebuild
- phù hợp kiến trúc event-driven cho giao dịch

### Nhưng cần nói rõ trade-off

Kafka không thay thế transaction DB của hệ thống lõi. Với hệ thống đặt lệnh chứng khoán:

- `DB giao dịch lõi` vẫn là nơi chốt trạng thái nghiệp vụ cuối cùng
- Kafka là `event backbone` để stream lệnh đi các hệ liên quan

### Nếu trả lời kiểu senior

Tôi sẽ nói thêm:

- nếu bài toán là `command queue` rất phức tạp, cần routing hoặc workflow đặc thù, RabbitMQ có thể phù hợp ở một số đoạn
- nhưng với `50.000 order/s`, nhiều consumer downstream, cần replay/audit, Kafka là lựa chọn mạnh hơn

## 5. Redis đang cache thông tin tài khoản chứng khoán. Khi khách hàng đổi thông tin tài khoản thì xử lý cache thế nào?

Đây là bài toán `cache invalidation`.

### Cách làm phổ biến nhất

Sau khi update DB thành công:

1. cập nhật DB
2. xóa cache key cũ trong Redis
3. lần đọc tiếp theo sẽ load lại từ DB và set lại cache

### Vì sao thường xóa cache thay vì update ngay?

Vì xóa cache:

- đơn giản hơn
- ít lỗi hơn
- tránh trường hợp cập nhật cache thiếu field hoặc sai format

### Flow đề xuất

Ví dụ key:

```text
account:12345
```

Khi khách đổi thông tin:

1. service update `account` trong DB
2. nếu DB commit thành công thì `DEL account:12345`
3. request đọc sau đó:
   - cache miss
   - đọc DB
   - set lại Redis với dữ liệu mới

### Nếu hệ thống nhiều instance

Nếu mỗi app node còn có local cache:

- phải xóa cả Redis cache
- đồng thời publish event `account.updated`
- các node subscribe event để clear local cache

### Trường hợp cần consistency cao hơn

Có thể dùng:

- `cache-aside` với delete sau update
- hoặc `write-through` nếu team chấp nhận độ phức tạp cao hơn

### Điểm cần nhấn mạnh trong phỏng vấn

- không update cache trước DB
- chỉ xóa hoặc cập nhật cache sau khi DB commit thành công
- phải tính đến local cache nếu có nhiều instance

## 6. Consumer Kafka xử lý thành công DB nhưng chết trước khi commit offset. Điều gì xảy ra?

### Điều gì xảy ra?

Kafka sẽ coi message đó `chưa được commit`.

Khi consumer restart hoặc partition được assign cho consumer khác:

- message sẽ bị đọc lại
- logic nghiệp vụ có thể chạy lại lần nữa

### Đây là semantics gì?

Đây là hành vi điển hình của `at-least-once`.

### Rủi ro

Nếu consumer đã:

- insert DB thành công
- nhưng chưa commit offset

thì lần đọc lại có thể gây:

- insert trùng
- cộng tiền hai lần
- tạo lệnh trùng
- gửi notification trùng

### Cách xử lý đúng

Consumer phải `idempotent`.

Các cách phổ biến:

- unique constraint theo `eventId` hoặc `business key`
- bảng `processed_events`
- upsert thay vì insert mù
- kiểm tra trạng thái trước khi apply

### Kết luận phỏng vấn

Không được giả định `xử lý DB xong` là đủ. Nếu chưa commit offset thì Kafka vẫn có thể gửi lại message. Vì vậy consumer phải thiết kế để chịu được duplicate.

## Mẫu trả lời cực ngắn khi đi phỏng vấn

### Kafka và RabbitMQ khác nhau thế nào?

Kafka thiên về event streaming, throughput cao, replay tốt. RabbitMQ thiên về queue truyền thống và routing linh hoạt.

### Offset là gì?

Là vị trí của message trong một partition. Consumer group commit offset để đánh dấu đã xử lý tới đâu.

### Khi nào dùng Kafka?

Khi cần throughput lớn, nhiều consumer đọc cùng dữ liệu, cần replay, audit và event-driven architecture.

### 50.000 lệnh/giây chọn gì?

Ưu tiên Kafka vì throughput, scale ngang, replay và nhiều downstream consumer.

### Update thông tin tài khoản thì cache xử lý sao?

Update DB xong mới xóa cache. Request sau đọc lại DB và set cache mới.

### Xử lý DB xong nhưng chết trước commit offset?

Message sẽ bị đọc lại. Đây là at-least-once, nên consumer phải idempotent.
