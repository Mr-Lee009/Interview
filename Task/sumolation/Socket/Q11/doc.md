# Câu 11. Làm thế nào để scale hệ thống chat WebSocket lên 100.000 kết nối đồng thời, đồng bộ message giữa nhiều instance Spring Boot, và xử lý khi user offline?

## 1. Ý chính

Muốn chat WebSocket scale lớn thì phải tách 3 bài toán:

- `connection handling`: node nào giữ kết nối của user
- `message distribution`: message đi từ node này sang node khác thế nào
- `offline delivery`: user rớt mạng hoặc offline thì message được giữ và trả lại ra sao

Một instance Spring Boot không nên vừa giữ toàn bộ `100.000` connection vừa ôm toàn bộ state nghiệp vụ.

## 2. Scale 100.000 kết nối đồng thời

Hướng chuẩn là scale ngang:

- nhiều `WebSocket Gateway` hoặc `Chat Node`
- phía trước có `Load Balancer`
- mỗi node chỉ giữ một phần connection

Thường sẽ có thêm:

- `Redis` để giữ presence hoặc session mapping
- `Kafka` hoặc `Redis Pub/Sub` để fan-out event
- `DB / Message Store` để lưu message bền vững

### Những điểm cần tối ưu

- giảm memory mỗi connection
- tune thread pool, connection timeout, heartbeat
- dùng stateless auth như `JWT`
- không giữ state quan trọng chỉ trong RAM local
- có `backpressure` hoặc queue khi fan-out lớn

## 3. Nếu chạy nhiều instance Spring Boot thì đồng bộ message thế nào?

Node nhận message từ client không chắc là node đang giữ người nhận.

Ví dụ:

- `User A` nối vào `Node 1`
- `User B` nối vào `Node 5`

Luồng đúng:

1. `Node 1` nhận message từ A
2. ghi message vào `DB / Outbox`
3. publish event vào `Kafka / Redis / RabbitMQ`
4. `Node 5` subscribe được event
5. `Node 5` push message xuống WebSocket của B

Ý chính:

- local memory chỉ biết session của chính node đó
- muốn multi-instance đúng thì phải có broker chung

## 4. Khi user offline thì xử lý thế nào?

WebSocket chỉ là kênh realtime, không phải nơi đảm bảo dữ liệu.

Khi recipient offline:

- vẫn lưu message vào `DB`
- đánh dấu trạng thái như `SENT`, `DELIVERED`, `READ`
- không push realtime được thì để `pending`
- khi user reconnect, server query các message có `id > lastMessageId`
- replay phần còn thiếu

Nếu cần báo ngay:

- kết hợp `FCM`, `APNs`, email hoặc notification service

## 5. Kiến trúc nên nhớ

- `Load Balancer` phân phối kết nối
- `WebSocket Nodes` giữ connection
- `Presence Store` biết user đang ở node nào
- `Broker` đồng bộ event giữa các node
- `Message Store` giữ dữ liệu bền vững để replay

## 6. Kết luận ngắn

- scale `100k` bằng nhiều node, không bằng một node rất lớn
- multi-instance phải có `Redis/Kafka/RabbitMQ` để đồng bộ event
- offline thì vẫn lưu DB, reconnect thì replay phần bị lỡ
