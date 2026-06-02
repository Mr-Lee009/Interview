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
- `Task/sumolation/index.html`: demo mô phỏng nhận diện vân tay/sinh trắc học.

Ghi chú: thư mục hiện tên là `sumolation`, có thể hiểu là nhóm tài liệu `simulation`.

## Redis

- `Task/sumolation/redis/doc.md`: note Redis cho phỏng vấn.
- `Task/sumolation/redis/QA.md`: hỏi đáp chi tiết về RDB, AOF, hybrid persistence và replication.
- `Task/sumolation/redis/docker-config.md`: cấu hình Docker cho Redis persistence theo 3 case RDB, AOF và hybrid.
- `Task/sumolation/redis/demo.html`: demo trực quan Redis.
- `Task/sumolation/redis/rdb-aof-backup.html`: mô phỏng chi tiết từng bước backup Redis bằng RDB và AOF.

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
