# Câu 3: Kiến trúc hướng sự kiện (Event-Driven) và xử lý Alert Storm

## 1. Cách xây dựng luồng cảnh báo thời gian thực

Tôi sẽ tách hệ thống thành các tầng sự kiện rõ ràng thay vì để service phân tích gọi trực tiếp service gửi notification.

Luồng điển hình:

1. Thiết bị hoặc pipeline phân tích phát hiện bất thường và phát sinh event `AnomalyDetected`.
2. Event được đẩy vào broker như Kafka hoặc RabbitMQ.
3. Một service chuyên trách `Alert Processor` consume event, enrich thêm metadata:
   - khu vực
   - mức độ nghiêm trọng
   - loại sự cố
   - người quản lý phụ trách
4. Service này quyết định:
   - có tạo alert hay không
   - có cần gộp với alert đang tồn tại không
   - có cần escalte mức độ ưu tiên không
5. Sau khi chuẩn hóa, hệ thống publish event `AlertCreated` hoặc `AlertAggregated`.
6. `Notification Service` consume các event này và gửi push notification qua FCM/APNs đến đúng nhóm người dùng.

Điểm quan trọng là broker đóng vai trò buffer và tách biệt producer với consumer để:

- chịu tải tốt khi số lượng event tăng đột biến
- retry độc lập nếu service gửi notification lỗi
- scale ngang từng thành phần
- dễ bổ sung thêm consumer khác như dashboard, audit, analytics

## 2. Chọn Kafka, RabbitMQ hay Pub/Sub

Nếu hệ thống là luồng telemetry lớn, nhiều cảm biến, throughput cao và cần replay event thì tôi ưu tiên Kafka.

Lý do:

- phù hợp streaming event volume lớn
- partition giúp scale consumer
- giữ được lịch sử event để replay hoặc điều tra sự cố
- phù hợp với bài toán correlation nhiều nguồn tín hiệu

Nếu hệ thống thiên về command/queue, cần routing linh hoạt, TTL, dead-letter queue đơn giản thì RabbitMQ phù hợp hơn.

Trong bài toán này, tôi thường dùng mô hình kết hợp:

- Kafka cho ingest và xử lý phân tích thời gian thực
- RabbitMQ hoặc một notification queue riêng cho bước dispatch push notification

Lý do là notification là tác vụ downstream, cần retry mềm, DLQ, rate limit và không nên làm ảnh hưởng đến pipeline phân tích chính.

## 3. Cách chống Alert Storm

Không nên gửi mỗi event bất thường thành một push notification. Tôi sẽ đưa thêm một tầng `Alert Aggregator` nằm giữa broker và notification service.

### a. Gộp theo khóa sự cố

Mỗi alert được nhóm theo một `dedup key`, ví dụ:

`siteId + zoneId + alertType + severity + timeWindow`

Ví dụ:

- cùng khu A
- cùng loại lỗi mất kết nối
- cùng mức critical
- trong cửa sổ 30 giây hoặc 1 phút

Thì coi là cùng một incident logic.

### b. Debounce

Khi event đầu tiên đến, chưa gửi push ngay trong mọi trường hợp. Hệ thống mở một cửa sổ ngắn, ví dụ 10 đến 30 giây, để chờ thêm event liên quan.

Nếu trong khoảng đó có thêm 200 cảm biến cùng báo lỗi, hệ thống không gửi 200 push mà tạo một alert tổng hợp như:

`Khu vực A đang có 217 cảm biến báo mất tín hiệu trong 20 giây gần nhất`

Debounce phù hợp khi muốn tránh cảnh báo trùng lặp từ cùng một sự cố vật lý.

### c. Throttle

Sau khi đã gửi một cảnh báo cho một incident, hệ thống đặt cooldown, ví dụ 5 phút. Trong thời gian đó:

- không gửi lại push cùng loại
- chỉ cập nhật counter hoặc severity trong backend
- chỉ gửi lại nếu mức độ thay đổi đáng kể, ví dụ từ warning lên critical

Điều này tránh điện thoại bị spam liên tục dù sự cố chưa được xử lý xong.

### d. Correlation và incident model

Thay vì coi từng sensor alert là một alert độc lập, hệ thống nên có khái niệm `incident`.

Ví dụ:

- mất điện tại một tầng
- đứt mạng ở một gateway
- camera gateway lỗi khiến nhiều camera downstream cùng mất tín hiệu

Khi đó rule engine hoặc correlation service sẽ suy luận root cause và tạo 1 incident cha, còn các alert từ sensor con chỉ là evidence. Người dùng nhận 1 thông báo chính thay vì hàng trăm thông báo lẻ.

## 4. Thiết kế kỹ thuật cụ thể

### Broker và topic

- Topic `anomaly-detected`: nhận mọi bất thường thô từ pipeline phân tích
- Topic `alert-aggregated`: alert sau khi đã gộp và chuẩn hóa
- Topic `notification-dispatch`: alert đã sẵn sàng gửi cho mobile app
- DLQ: chứa message lỗi để retry hoặc kiểm tra thủ công

### Service chính

- `Detection Service`: phát hiện bất thường
- `Alert Aggregator`: dedup, debounce, throttle, correlation
- `Incident Service`: quản lý vòng đời incident open, update, resolved
- `Notification Service`: gửi push, retry, rate-limit theo user/device

### State để gộp alert

Aggregator cần state tạm thời, thường lưu ở Redis hoặc state store:

- key là `dedup key`
- value gồm:
  - số lượng sensor ảnh hưởng
  - sensor đầu tiên
  - sensor gần nhất
  - thời điểm bắt đầu
  - mức severity cao nhất
  - trạng thái đã gửi push hay chưa

Redis phù hợp nếu cần lookup nhanh và TTL rõ ràng. Nếu dùng Kafka Streams hoặc Flink thì có thể dùng windowed aggregation ngay trên stream processor.

## 5. Quy tắc gửi notification thực tế

Tôi thường áp dụng các rule như sau:

- Event đầu tiên mức critical: gửi gần như ngay, nhưng vẫn qua cửa sổ debounce rất ngắn 5 đến 10 giây
- Cùng incident trong cooldown: không gửi lại push
- Nếu số lượng sensor tăng mạnh hoặc severity tăng: gửi một bản cập nhật
- Khi incident được resolve: gửi 1 push đóng sự cố nếu nghiệp vụ cần

Ví dụ notification:

- `Critical: Mất kết nối diện rộng tại Khu A, ảnh hưởng 217 cảm biến`
- `Update: Sự cố đã lan sang 3 tầng, tổng 356 thiết bị bị ảnh hưởng`
- `Resolved: Kết nối tại Khu A đã ổn định trở lại`

## 6. Các điểm vận hành cần có

- Idempotency để tránh gửi trùng khi consumer retry
- DLQ cho notification lỗi
- Backpressure để notification service không bị nghẽn khi FCM/APNs chậm
- Rate limit theo user, khu vực, loại cảnh báo
- Observability: metric cho event rate, lag, số alert bị gộp, số push bị suppress
- Audit log để biết vì sao một alert bị gộp hoặc không được gửi

## 7. Kết luận

Tôi sẽ dùng kiến trúc event-driven với broker làm xương sống, tách rõ:

- phát hiện bất thường
- xử lý/gộp cảnh báo
- gửi notification

Để xử lý alert storm, cốt lõi không phải chỉ là queue message, mà là có tầng `Alert Aggregator/Incident Manager` để thực hiện:

- dedup theo khóa sự cố
- debounce theo time window
- throttle theo cooldown
- correlation nhiều alert thành một incident có ý nghĩa nghiệp vụ

Như vậy hệ thống vẫn phản ứng gần thời gian thực, nhưng người dùng chỉ nhận những cảnh báo quan trọng, có ngữ cảnh, và không bị spam.