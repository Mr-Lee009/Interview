# Menu Tài Liệu Interview

File này là mục lục nhanh cho thư mục `Task/sumolation`. Mục tiêu là giúp người mở project sau này biết từng tài liệu dùng để làm gì và nên đọc theo thứ tự nào.

## Tổng quan

- `README.md`: mô tả mục đích project, cấu trúc thư mục và quy ước bổ sung tài liệu.
- `SIMULATION_UI_RULES.md`: quy chuẩn thiết kế các màn hình mô phỏng HTML; lấy `AWS/index.html` làm mẫu.
- `message-systems-comparison.md`: bảng so sánh Kafka, RabbitMQ, Redis Pub/Sub và Redis Streams; nêu khi nào dùng, ưu/nhược điểm và case thực tế.
- `index.html`: demo mô phỏng nhận diện vân tay/sinh trắc học. Dùng để minh họa pipeline: scan dữ liệu, trích xuất đặc trưng, tạo template và đối chiếu.

## Redis

- `redis/doc.md`: note phỏng vấn Redis. Gồm mục tiêu học, khái niệm chính, câu hỏi hay gặp, lỗi thường gặp và hướng mở rộng.
- `redis/QA.md`: câu trả lời chi tiết theo dạng gạch đầu dòng về `RDB`, `AOF`, hybrid persistence, replication, ưu/nhược điểm, ví dụ và hướng xử lý.
- `redis/docker-config.md`: cấu hình Docker Redis cho 3 case persistence: chỉ `RDB`, chỉ `AOF`, và kết hợp `RDB + AOF`.
- `redis/docker-compose-rdb-master-replica.yml`: docker compose chạy Redis master/replica với backup `RDB`, có comment rõ từng cấu hình.
- `redis/redis-config-master-slave/`: cấu hình Redis master/replica tách riêng `docker-compose.yml` và file `.conf`, kèm `index.html` mô phỏng mô hình chạy.
- `redis/demo.html`: demo trực quan cho Redis. Dùng để trình bày hoặc tự ôn khi cần giải thích cache/Redis bằng hình ảnh.
- `redis/rdb-aof-backup.html`: demo mô phỏng từng bước quá trình backup/persistence của Redis bằng hai cơ chế `RDB` và `AOF`.

Nên đọc khi cần ôn: cache, TTL, eviction policy, distributed lock, pub/sub, stream, persistence, cache penetration, cache breakdown và cache avalanche.

## SQL Và NoSQL

- `sql/QA.md`: phân tích khi nào dùng SQL hoặc NoSQL, ưu/nhược điểm, bài toán thực tế, tốc độ và bảng so sánh.
- `sql/order-food-db-design.md`: case study thiết kế database hệ thống gọi món theo góc nhìn leader, gồm requirement, entity, table, transaction, index và checklist review.

Nên đọc khi cần ôn: relational database, document database, key-value store, transaction, consistency, schema design, query pattern, scale ngang và lựa chọn database theo bài toán.

## AWS

- `AWS/doc.md`: ghi chú tổng quan AWS, hiện đang là nơi mở rộng tài liệu.
- `AWS/index.html`: demo dạng tab mô phỏng các dịch vụ AWS phổ biến và cách chúng nằm trong kiến trúc backend/cloud.
- `AWS/QA.md`: 10 câu hỏi phỏng vấn AWS về EC2, S3, VPC, IAM, RDS, Load Balancer, Auto Scaling, CloudWatch, CloudTrail và Lambda.

Nên đọc khi cần ôn: cloud basics, compute, storage, networking, security, database, monitoring và kiến trúc backend trên AWS.

## Phân Tích Lỗi Microservices

- `phan_tich_loi/QA.md`: ghi chú 3 lỗi kinh điển trong microservices: cascading failure, data inconsistency và ghost/config error.
- `phan_tich_loi/index.html`: demo 3 tab mô phỏng từng lỗi, luồng xảy ra lỗi, cách check và cách giải quyết.

Nên đọc khi cần ôn: distributed tracing, circuit breaker, saga pattern, message broker, Kubernetes probe, service mesh và incident debugging.

## Payment

- `payment/doc.md`: hướng dẫn chọn phương án tích hợp MoMo cho website và cấu hình Spring Boot, gồm flow `captureWallet`, tạo chữ ký, create payment, IPN, DB status và checklist production.
- `payment/test_momo_request.md`: request/response mẫu để test MoMo sandbox bằng Postman hoặc cURL, gồm create payment, response success/error và IPN mẫu.
- `payment/glossary.md`: bảng giải thích thuật ngữ payment gateway như IPN, callback server-to-server, redirectUrl, signature, secure hash, idempotency và reconcile.
- `payment/compare-gateways.md`: bảng so sánh MoMo, VNPAY, ZaloPay về config, request/response, callback/IPN và gợi ý thiết kế class `PaymentGateway`.
- `payment/design-class.md`: tài liệu thiết kế class cho tính năng payment nhiều cổng, gồm config từng gateway, cấu trúc thư mục, class/function và flow triển khai.
- `payment/design-class.html`: demo mô phỏng quan hệ giữa các class payment theo layer: presentation, application, domain và infrastructure adapters.
- `payment/momo/doc.md`: tài liệu riêng cho tích hợp MoMo, nhấn mạnh luồng `create payment`, `payUrl`, `redirectUrl`, `ipnUrl`, verify signature và cập nhật trạng thái DB.
- `payment/momo/test_momo_request.md`: request/response mẫu cho MoMo sandbox trong thư mục MoMo.
- `payment/momo/index.html`: màn hình mô phỏng 12 bước thanh toán MoMo, có flow user redirect, server-to-server IPN, check DB và cập nhật `SUCCESS/FAILED`.
- `payment/vnpay/doc.md`: tài liệu tích hợp VNPAY cho Spring Boot, gồm build `paymentUrl`, `vnp_SecureHash`, `vnp_ReturnUrl`, IPN, QueryDR và checklist production.
- `payment/vnpay/test_vnpay_request.md`: request/response mẫu để test VNPAY sandbox, gồm params tạo URL, ReturnUrl, IPN và QueryDR mẫu.
- `payment/vnpay/index.html`: màn hình mô phỏng 13 bước thanh toán VNPAY theo layout chuẩn 3 hàng, có flow build URL, redirect, IPN, verify hash và cập nhật `SUCCESS/FAILED`.
- `payment/zalopay/doc.md`: tài liệu tích hợp ZaloPay cho Spring Boot, gồm `/v2/create`, `order_url`, `callback_url`, `key1/key2`, query order và checklist production.
- `payment/zalopay/test_zalopay_request.md`: request/response mẫu để test ZaloPay sandbox, gồm create order, callback và query order.
- `payment/zalopay/index.html`: màn hình mô phỏng 14 bước thanh toán ZaloPay theo layout chuẩn 3 hàng, có flow create order, redirect, callback, verify mac và cập nhật `SUCCESS/FAILED`.

Nên đọc khi cần ôn: payment gateway, MoMo, redirectUrl, ipnUrl, HMAC SHA256, idempotency và xử lý trạng thái thanh toán.

## Kafka

- `kafka/doc.md`: tài liệu Kafka đầy đủ cho Java Developer/Senior, gồm kiến trúc, topic/partition, consumer group, offset, delivery semantics, rebalance, retry/DLQ, Spring Boot Kafka và câu hỏi phỏng vấn.
- `kafka/bank-fraud-detection.md`: case study ứng dụng Kafka cho hệ thống ngân hàng phát hiện giao dịch nghi ngờ, gồm service, topic, flow, retry/DLQ và monitoring.
- `kafka/bank-fraud-detection.html`: demo mô phỏng realtime flow phát hiện giao dịch nghi ngờ bằng Kafka.
- `kafka/index.html`: demo Kafka phiên bản chính.
- `kafka/index-2.html`: demo Kafka phiên bản phụ hoặc biến thể.

Nên đọc khi cần ôn: producer, consumer, broker, topic, partition, consumer group, offset, replication, delivery semantics và xử lý message trong hệ thống phân tán.

## CA, PKI Và Chữ Ký Số

- `CA/doc.md`: tài liệu tổng quan về hệ thống chữ ký số, PKI, CA, RA, certificate, signing và verification.
- `CA/X509.md`: ghi chú riêng về chuẩn chứng thư số X.509, cấu trúc certificate, định dạng file và ứng dụng thực tế.
- `CA/index.html`: demo trực quan chính cho chủ đề CA/chữ ký số.
- `CA/index-2.html`: demo trực quan phụ hoặc biến thể.

Nên đọc khi cần ôn: public/private key, digital signature, certificate chain, Root CA, Intermediate CA, CRL, OCSP, X.509, TLS/HTTPS và ký tài liệu.

## Design Pattern

- `patten/doc.md`: tổng quan 23 Design Pattern theo nhóm GoF.
- `patten/creational_patterns/doc.md`: mục lục nhóm khởi tạo object.
- `patten/structural_patterns/doc.md`: mục lục nhóm cấu trúc object/class.
- `patten/behavioral_patterns/doc.md`: mục lục nhóm hành vi và giao tiếp giữa object.

### Creational Patterns

- `patten/creational_patterns/singleton.md`: chỉ có một instance dùng chung.
- `patten/creational_patterns/factory_method.md`: tạo object qua factory method.
- `patten/creational_patterns/abstract_factory.md`: tạo họ object liên quan.
- `patten/creational_patterns/builder.md`: dựng object phức tạp theo từng bước.
- `patten/creational_patterns/prototype.md`: tạo object mới bằng cách clone object mẫu.

### Structural Patterns

- `patten/structural_patterns/adapter.md`: chuyển đổi interface để hai hệ không tương thích làm việc với nhau.
- `patten/structural_patterns/bridge.md`: tách abstraction khỏi implementation.
- `patten/structural_patterns/composite.md`: tổ chức object dạng cây.
- `patten/structural_patterns/decorator.md`: thêm hành vi cho object mà không sửa class gốc.
- `patten/structural_patterns/facade.md`: tạo interface đơn giản cho hệ thống phức tạp.
- `patten/structural_patterns/flyweight.md`: chia sẻ object để tiết kiệm bộ nhớ.
- `patten/structural_patterns/proxy.md`: object đại diện kiểm soát truy cập object thật.

### Behavioral Patterns

- `patten/behavioral_patterns/chain_of_responsibility.md`: truyền request qua chuỗi handler.
- `patten/behavioral_patterns/command.md`: đóng gói request thành object.
- `patten/behavioral_patterns/interpreter.md`: diễn giải ngôn ngữ hoặc biểu thức.
- `patten/behavioral_patterns/iterator.md`: duyệt collection mà không lộ cấu trúc bên trong.
- `patten/behavioral_patterns/mediator.md`: gom giao tiếp giữa object qua trung gian.
- `patten/behavioral_patterns/memento.md`: lưu và khôi phục trạng thái object.
- `patten/behavioral_patterns/observer.md`: thông báo khi subject thay đổi.
- `patten/behavioral_patterns/state.md`: thay đổi hành vi theo state nội bộ.
- `patten/behavioral_patterns/strategy.md`: thay đổi thuật toán linh hoạt.
- `patten/behavioral_patterns/template_method.md`: định nghĩa skeleton thuật toán cho subclass triển khai chi tiết.
- `patten/behavioral_patterns/visitor.md`: thêm hành vi mới cho cấu trúc object mà không sửa class phần tử.

## Gợi Ý Thứ Tự Ôn Phỏng Vấn

1. Đọc `README.md` để hiểu project.
2. Đọc các file Java ở thư mục gốc của repo nếu cần ôn nền tảng Java.
3. Đọc `patten/doc.md` để nắm Design Pattern.
4. Đọc `redis/doc.md` và mở `redis/demo.html`.
5. Mở demo Kafka khi cần ôn message queue/event streaming.
6. Đọc `CA/doc.md` và `CA/X509.md` nếu buổi phỏng vấn có security, TLS, chữ ký số hoặc certificate.
