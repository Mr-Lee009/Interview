# Menu Tài Liệu Interview

Đây là mục lục chính của repo `Interview`. Repo này dùng để lưu tài liệu ôn phỏng vấn backend/Java và các demo mô phỏng giúp giải thích khái niệm kỹ thuật.

## Java Interview

- `java-mid-level-interview-questions.md`: danh sách câu hỏi Java mid-level.
- `java-mid-level-interview-answers.md`: câu trả lời tham khảo cho nhóm câu hỏi Java mid-level.
- `java-advanced-interview-questions.md`: câu hỏi Java nâng cao.
- `tip.md`: ghi chú/tip phỏng vấn và kiến thức bổ sung.

Nên đọc khi cần ôn: OOP, collection, exception, string, thread, Java 8, performance, database access và các chủ đề Java backend thường gặp.

## Simulation And Topic Notes

- `Task/sumolation/README.md`: mô tả mục tiêu và cấu trúc nhóm tài liệu mô phỏng.
- `Task/sumolation/menu.md`: mục lục chi tiết cho các chủ đề Redis, Kafka, CA/X.509, chữ ký số và Design Pattern.
- `Task/sumolation/SIMULATION_UI_RULES.md`: rule chuẩn để thiết kế các màn hình mô phỏng HTML, lấy `AWS/index.html` làm mẫu.
- `Task/sumolation/index.html`: demo mô phỏng nhận diện vân tay/sinh trắc học.

Ghi chú: thư mục hiện tên là `sumolation`, có thể hiểu là nhóm tài liệu `simulation`.

## Redis

- `Task/sumolation/redis/doc.md`: note Redis cho phỏng vấn.
- `Task/sumolation/redis/QA.md`: hỏi đáp chi tiết về RDB, AOF, hybrid persistence và replication.
- `Task/sumolation/redis/docker-config.md`: cấu hình Docker cho Redis persistence theo 3 case RDB, AOF và hybrid.
- `Task/sumolation/redis/docker-compose-rdb-master-replica.yml`: docker compose Redis master/replica với backup RDB và comment cấu hình.
- `Task/sumolation/redis/redis-config-master-slave/`: cấu hình Redis master/replica tách file `.conf` riêng và demo HTML mô tả mô hình.
- `Task/sumolation/redis/demo.html`: demo trực quan Redis.
- `Task/sumolation/redis/rdb-aof-backup.html`: mô phỏng chi tiết từng bước backup Redis bằng RDB và AOF.

## SQL Và NoSQL

- `Task/sumolation/sql/QA.md`: phân tích khi nào dùng SQL hoặc NoSQL, ưu/nhược điểm, bài toán thực tế, tốc độ và bảng so sánh.
- `Task/sumolation/sql/order-food-db-design.md`: case study thiết kế database gọi món theo góc nhìn leader.

## AWS

- `Task/sumolation/AWS/doc.md`: ghi chú tổng quan AWS.
- `Task/sumolation/AWS/index.html`: demo dạng tab mô phỏng các dịch vụ AWS phổ biến.
- `Task/sumolation/AWS/QA.md`: 10 câu hỏi phỏng vấn AWS kèm trả lời và ví dụ thực tế.

## Phân Tích Lỗi Microservices

- `Task/sumolation/phan_tich_loi/QA.md`: ghi chú 3 lỗi microservices thường gặp.
- `Task/sumolation/phan_tich_loi/index.html`: demo 3 tab mô phỏng lỗi và hướng xử lý.

## Payment

- `Task/sumolation/payment/doc.md`: hướng dẫn tích hợp thanh toán MoMo cho Spring Boot.
- `Task/sumolation/payment/test_momo_request.md`: request/response mẫu để test MoMo sandbox.
- `Task/sumolation/payment/glossary.md`: giải thích thuật ngữ payment gateway như IPN, callback, redirect, signature và idempotency.
- `Task/sumolation/payment/compare-gateways.md`: so sánh MoMo, VNPAY, ZaloPay để thiết kế class thanh toán chung.
- `Task/sumolation/payment/design-class.md`: thiết kế class, config, package structure và flow triển khai payment nhiều cổng.
- `Task/sumolation/payment/design-class.html`: mô phỏng quan hệ class payment theo các layer và adapter gateway.
- `Task/sumolation/payment/momo/doc.md`: tài liệu chi tiết riêng cho tích hợp MoMo.
- `Task/sumolation/payment/momo/test_momo_request.md`: request/response mẫu MoMo sandbox trong thư mục MoMo.
- `Task/sumolation/payment/momo/index.html`: mô phỏng luồng thanh toán MoMo từ create payment, redirect user, IPN, verify signature đến cập nhật `SUCCESS/FAILED`.
- `Task/sumolation/payment/vnpay/doc.md`: tài liệu tích hợp VNPAY cho Spring Boot.
- `Task/sumolation/payment/vnpay/test_vnpay_request.md`: request/response mẫu để test VNPAY sandbox.
- `Task/sumolation/payment/vnpay/index.html`: mô phỏng luồng thanh toán VNPAY từ build payment URL, redirect user, IPN, verify hash đến cập nhật `SUCCESS/FAILED`.
- `Task/sumolation/payment/zalopay/doc.md`: tài liệu tích hợp ZaloPay cho Spring Boot.
- `Task/sumolation/payment/zalopay/test_zalopay_request.md`: request/response mẫu để test ZaloPay sandbox.
- `Task/sumolation/payment/zalopay/index.html`: mô phỏng luồng thanh toán ZaloPay từ create order, redirect user, callback, verify mac đến cập nhật `SUCCESS/FAILED`.

## Kafka

- `Task/sumolation/kafka/index.html`: demo Kafka chính.
- `Task/sumolation/kafka/index-2.html`: demo Kafka phụ hoặc biến thể.

## CA, PKI Và X.509

- `Task/sumolation/CA/doc.md`: tổng quan chữ ký số, PKI, CA, RA, signing và verification.
- `Task/sumolation/CA/X509.md`: ghi chú về chuẩn certificate X.509.
- `Task/sumolation/CA/index.html`: demo chính cho CA/chữ ký số.
- `Task/sumolation/CA/index-2.html`: demo phụ hoặc biến thể.

## Design Pattern

- `Task/sumolation/patten/doc.md`: tổng quan 23 Design Pattern GoF.
- `Task/sumolation/patten/creational_patterns/`: nhóm khởi tạo object.
- `Task/sumolation/patten/structural_patterns/`: nhóm cấu trúc object/class.
- `Task/sumolation/patten/behavioral_patterns/`: nhóm hành vi và giao tiếp giữa object.

Ghi chú: thư mục hiện tên là `patten`, có thể hiểu là `pattern`.

## Thứ Tự Ôn Đề Xuất

1. Đọc `menu.md` này để nắm bản đồ repo.
2. Đọc nhóm Java ở thư mục gốc.
3. Đọc `Task/sumolation/menu.md` để chọn chủ đề mô phỏng cần ôn.
4. Ôn Design Pattern nếu phỏng vấn thiên về OOP/system design nhỏ.
5. Ôn Redis/Kafka nếu phỏng vấn backend, cache hoặc distributed system.
6. Ôn CA/X.509 nếu phỏng vấn có security, TLS, chữ ký số hoặc certificate.
