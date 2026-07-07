# Kafka vs RabbitMQ: Khi nào dùng cái nào?

Tài liệu này so sánh ngắn gọn nhưng thực tế giữa `Kafka` và `RabbitMQ`, tập trung vào câu hỏi quan trọng nhất trong phỏng vấn hoặc khi thiết kế hệ thống: khi nào nên dùng cái nào, và nếu áp dụng vào một bài toán cụ thể thì ưu nhược điểm ra sao.

## 1. Tóm tắt rất ngắn

- `Kafka` phù hợp khi bài toán là `event streaming`, cần throughput lớn, nhiều service cùng consume một luồng dữ liệu, và cần replay event.
- `RabbitMQ` phù hợp khi bài toán là `message queue` truyền thống, cần routing linh hoạt, xử lý task/command, retry/delay và workflow rõ ràng.

## 2. So sánh nhanh

| Tiêu chí | Kafka | RabbitMQ |
|---|---|---|
| Mô hình chính | Distributed log / event streaming | Message broker / queue |
| Cách lưu message | Append vào log, giữ theo retention | Message nằm trong queue, ack xong thường bị remove |
| Replay | Rất mạnh, có thể reset offset để đọc lại | Không phải điểm mạnh chính |
| Throughput | Rất cao, hợp luồng event lớn | Tốt, nhưng thường không tối ưu bằng Kafka ở scale rất lớn |
| Routing | Đơn giản hơn, chủ yếu topic/partition | Mạnh với exchange, binding, routing key |
| Consumer | Consumer chủ động poll | Broker push message cho consumer |
| Ordering | Đảm bảo trong từng partition | Đảm bảo trong từng queue nếu cấu hình phù hợp |
| Multi-service consume | Rất mạnh | Có thể làm, nhưng không tự nhiên bằng Kafka cho event fan-out |
| Use case mạnh | Event bus, analytics, audit, streaming | Task queue, command queue, retry, delay, workflow |

## 3. Khi nào dùng Kafka?

Dùng Kafka khi hệ thống có các đặc điểm sau:

- có rất nhiều event phát sinh liên tục;
- nhiều service khác nhau cần đọc cùng một event;
- cần giữ lịch sử để audit hoặc replay;
- cần scale ngang theo partition;
- cần xử lý realtime hoặc near realtime.

Ví dụ phù hợp:

- tracking hành vi người dùng;
- log pipeline;
- fraud detection;
- đồng bộ dữ liệu giữa microservice;
- hệ thống thanh toán hoặc giao dịch lớn.

## 4. Khi nào dùng RabbitMQ?

Dùng RabbitMQ khi hệ thống thiên về xử lý tác vụ hơn là phát luồng sự kiện:

- cần gửi job cho worker xử lý;
- cần routing message phức tạp;
- cần retry, delay queue, dead-letter rõ ràng;
- cần mô hình command/task queue đơn giản;
- số lượng message không quá lớn hoặc không cần replay dài hạn.

Ví dụ phù hợp:

- gửi email / SMS / push notification;
- xử lý background job;
- phân phối task cho worker;
- workflow có nhiều nhánh routing.

## 5. Bài toán cụ thể: Hệ thống đặt hàng thương mại điện tử

Giả sử có một hệ thống bán hàng online với luồng như sau:

1. Khách đặt hàng.
2. Hệ thống trừ tồn kho.
3. Thanh toán được xử lý.
4. Gửi email/SMS xác nhận.
5. Cập nhật báo cáo doanh thu.
6. Đồng bộ dữ liệu sang hệ thống phân tích.

### 5.1 Nếu dùng Kafka

Luồng có thể là:

```text
Order Service -> Kafka topic: order.created
Inventory Service consume
Payment Service consume
Notification Service consume
Analytics Service consume
```

#### Ưu điểm

- Nhiều service có thể consume cùng một `order.created` event mà không cần producer gửi riêng từng nơi.
- Dễ mở rộng khi sau này thêm service mới như fraud check, recommendation, BI.
- Có thể replay để rebuild báo cáo hoặc xử lý lại khi bug được sửa.
- Hợp với kiến trúc event-driven, tách lỏng các service.
- Scale tốt khi lượng đơn hàng tăng mạnh.

#### Nhược điểm

- Không phải lựa chọn tối ưu nếu chỉ cần một hàng đợi tác vụ đơn giản.
- Vận hành và tư duy offset/partition phức tạp hơn RabbitMQ.
- Nếu cần routing kiểu exchange/binding rất chi tiết, Kafka kém tự nhiên hơn.
- Xử lý retry/delay/workflow chi tiết thường phải tự thiết kế thêm.

### 5.2 Nếu dùng RabbitMQ

Luồng có thể là:

```text
Order Service -> Exchange
  -> Inventory Queue
  -> Payment Queue
  -> Notification Queue
  -> Analytics Queue
```

#### Ưu điểm

- Routing rất linh hoạt, dễ chia message theo từng queue/worker.
- Phù hợp cho xử lý job theo từng bước, retry/delay, dead-letter.
- Dễ hiểu hơn nếu hệ thống chủ yếu là task queue.
- Phù hợp khi cần deliver message cho một số worker cụ thể thay vì nhiều consumer đọc cùng một event stream.

#### Nhược điểm

- Khi số lượng event tăng rất lớn, bài toán event streaming và replay không thuận lợi bằng Kafka.
- Không mạnh bằng Kafka trong việc lưu lịch sử dài hạn để phân tích lại.
- Nếu nhiều hệ cùng cần đọc một sự kiện, thiết kế fan-out có thể trở nên nặng hơn.
- Scale theo kiểu event pipeline lớn thường không “đã” bằng Kafka.

## 6. Chọn cái nào cho bài toán đặt hàng?

### Chọn Kafka nếu:

- bạn xem đơn hàng là một `domain event`;
- nhiều service khác nhau cần cùng đọc đơn hàng;
- bạn cần audit, analytics, replay;
- traffic tăng cao theo thời gian;
- kiến trúc thiên về event-driven hoặc data pipeline.

### Chọn RabbitMQ nếu:

- bài toán chủ yếu là đẩy task cho worker xử lý;
- cần routing rõ ràng theo queue;
- cần retry/delay/dead-letter dễ triển khai;
- hệ thống nhỏ hoặc trung bình, không cần replay dài hạn;
- không có nhu cầu nhiều service cùng đọc một stream sự kiện.

## 7. Kết luận thực dụng

- Nếu bài toán là `event stream` lớn, nhiều consumer, cần replay và mở rộng lâu dài, chọn `Kafka`.
- Nếu bài toán là `task queue` hoặc `command queue`, cần routing linh hoạt và workflow xử lý rõ ràng, chọn `RabbitMQ`.
- Trong thực tế, nhiều hệ thống dùng cả hai: Kafka cho event backbone, RabbitMQ cho job nội bộ hoặc workflow tác vụ.

## 8. Câu trả lời ngắn gọn khi phỏng vấn

Bạn có thể trả lời:

> Kafka phù hợp khi cần xử lý luồng event lớn, nhiều service cùng consume và cần replay. RabbitMQ phù hợp khi cần queue tác vụ, routing linh hoạt, retry/delay và workflow đơn giản hơn. Với bài toán đặt hàng thương mại điện tử, nếu muốn xây kiến trúc event-driven và mở rộng lâu dài thì nghiêng về Kafka; nếu chủ yếu là phân phối task cho worker thì RabbitMQ hợp hơn.
