# Câu 8. Nếu hệ thống có nhiều instance server, làm sao broadcast message qua WebSocket cho đúng tất cả client?

## 1. Ý chính

Khi hệ thống chỉ có `1 server`, việc broadcast khá đơn giản:

- server nhận message
- server biết toàn bộ client đang kết nối vào nó
- server đẩy message xuống tất cả client cần nhận

Nhưng khi có `nhiều instance server`, mỗi server chỉ biết:

- các client đang kết nối vào chính nó
- không biết client ở node khác

Vì vậy:

- nếu chỉ broadcast trong memory của một node
- thì chỉ client ở node đó nhận được
- client ở node khác sẽ bị bỏ sót

Đó là lý do cần thêm một tầng đồng bộ message chung.

## 2. Vấn đề xảy ra khi có nhiều server

Giả sử:

- `User A` kết nối vào `Server 1`
- `User B` kết nối vào `Server 2`
- `User C` kết nối vào `Server 3`

Nếu `User A` gửi một tin nhắn vào phòng chat:

- `Server 1` nhận được message
- nhưng `Server 1` không tự biết `User B` và `User C` đang ở node nào

Nếu hệ thống chỉ xử lý local:

- `User A` có thể nhận được
- client trên `Server 2` và `Server 3` không nhận được

## 3. Cách giải quyết chuẩn

Thêm một tầng trung gian để đồng bộ event giữa các node:

- `Redis Pub/Sub`
- `Kafka`
- `RabbitMQ`
- hoặc message broker khác

Ý tưởng:

1. một node nhận message từ client
2. node đó publish message ra broker
3. tất cả node khác subscribe broker đều nhận được event
4. mỗi node tự push event xuống các client đang kết nối vào nó

## 4. Luồng hoạt động dễ hiểu

Ví dụ hệ thống chat có 2 server:

- `User A` nối vào `Server 1`
- `User B` nối vào `Server 2`

Khi `User A` gửi tin nhắn:

1. `Server 1` nhận message từ WebSocket
2. `Server 1` lưu tin nhắn vào DB nếu cần
3. `Server 1` publish event vào `Redis/Kafka`
4. `Server 1` nhận lại event đó và push xuống client local
5. `Server 2` cũng nhận event đó từ broker
6. `Server 2` push xuống `User B`

Kết quả:

- tất cả user ở mọi node đều nhận được đúng message

## 5. Vì sao không nên chỉ dùng memory local?

Vì memory local chỉ đúng trong phạm vi một process.

Ví dụ:

- `Map<roomId, sessions>` ở `Server 1`
- không phản ánh gì về sessions ở `Server 2`

Nên nếu chỉ broadcast local:

- scale ngang sẽ sai hành vi
- mất đồng bộ giữa các node

## 6. Vai trò của từng thành phần

### WebSocket Server

- giữ kết nối với client
- nhận message từ client
- đẩy message xuống client

### Message Broker

- đóng vai trò bus trung gian giữa các node
- giúp mọi node cùng thấy một event

### Database hoặc Message Store

- dùng khi cần lưu lịch sử
- hỗ trợ reconnect và lấy lại message bị lỡ

## 7. Nên dùng Redis, Kafka hay RabbitMQ?

### Redis Pub/Sub

Phù hợp khi:

- hệ thống vừa và nhỏ
- cần realtime đơn giản
- muốn triển khai nhanh

Ưu điểm:

- nhanh
- nhẹ
- dễ dùng

Nhược điểm:

- không mạnh về durability như Kafka

### Kafka

Phù hợp khi:

- hệ thống lớn
- throughput cao
- cần replay event
- cần lưu log sự kiện

Ưu điểm:

- scale tốt
- mạnh về event streaming
- hỗ trợ replay

Nhược điểm:

- setup phức tạp hơn Redis

### RabbitMQ

Phù hợp khi:

- cần routing message linh hoạt
- cần queue theo pattern rõ ràng

Ưu điểm:

- routing tốt
- dễ mô hình hóa queue/workflow

Nhược điểm:

- không thiên về streaming lớn như Kafka

## 8. Có cần lưu DB trước rồi mới publish không?

Thường có 2 hướng:

### Hướng 1: Lưu DB rồi publish

Phù hợp khi:

- message quan trọng
- cần lịch sử
- cần đồng bộ lại khi reconnect

Luồng:

1. ghi DB
2. publish broker
3. push WebSocket

### Hướng 2: Publish ngay rồi lưu sau hoặc không lưu

Phù hợp khi:

- notification ngắn hạn
- event realtime không cần lưu lâu

Ví dụ:

- live typing
- online status

## 9. Những điểm cần lưu ý khi thiết kế

### Idempotency

- có thể một event bị nhận lại nhiều lần
- node phải tránh đẩy trùng hoặc xử lý trùng không mong muốn

### Ordering

- nếu chat room cần đúng thứ tự
- phải có cơ chế giữ ordering hợp lý

### Reconnect

- nếu client mất mạng rồi vào lại
- nên có cách lấy message còn thiếu từ DB hoặc cache

### Trace

- nên có `messageId`, `roomId`, `senderId`, `traceId`
- để debug luồng đi qua nhiều node

## 10. Ví dụ thực tế

### Ví dụ chat

- User A ở `Server 1`
- User B ở `Server 2`
- A gửi tin nhắn "Hello"
- `Server 1` publish event `chat.message.created`
- `Server 2` nhận event và đẩy xuống user B

### Ví dụ notification

- hệ thống billing tạo event `invoice.paid`
- event đi vào broker
- mọi WebSocket node nhận event
- node nào đang giữ connection của user đó thì push notification xuống

## 11. Kết luận ngắn

- một node không thể tự broadcast đúng cho client ở node khác
- khi scale nhiều WebSocket server, phải có tầng đồng bộ chung
- giải pháp phổ biến là:
  - `Redis Pub/Sub`
  - `Kafka`
  - `RabbitMQ`
- mỗi node:
  - nhận event từ broker
  - tự push xuống client local của mình

## Ghi nhớ nhanh

- `1 node`: broadcast local là đủ
- `n node`: phải có broker chung
- node nhận message không phải lúc nào cũng là node giữ toàn bộ người nhận
- muốn scale WebSocket đúng thì phải tách:
  - `connection handling`
  - `event distribution`
