# Menu Tài Liệu Interview

File này là mục lục nhanh cho thư mục `Task/sumolation`. Mục tiêu là giúp người mở project sau này biết từng tài liệu dùng để làm gì và nên đọc theo thứ tự nào.

## Tổng quan

- `README.md`: mô tả mục đích project, cấu trúc thư mục và quy ước bổ sung tài liệu.
- `index.html`: demo mô phỏng nhận diện vân tay/sinh trắc học. Dùng để minh họa pipeline: scan dữ liệu, trích xuất đặc trưng, tạo template và đối chiếu.

## Redis

- `redis/doc.md`: note phỏng vấn Redis. Gồm mục tiêu học, khái niệm chính, câu hỏi hay gặp, lỗi thường gặp và hướng mở rộng.
- `redis/QA.md`: câu trả lời chi tiết theo dạng gạch đầu dòng về `RDB`, `AOF`, hybrid persistence, replication, ưu/nhược điểm, ví dụ và hướng xử lý.
- `redis/docker-config.md`: cấu hình Docker Redis cho 3 case persistence: chỉ `RDB`, chỉ `AOF`, và kết hợp `RDB + AOF`.
- `redis/demo.html`: demo trực quan cho Redis. Dùng để trình bày hoặc tự ôn khi cần giải thích cache/Redis bằng hình ảnh.
- `redis/rdb-aof-backup.html`: demo mô phỏng từng bước quá trình backup/persistence của Redis bằng hai cơ chế `RDB` và `AOF`.

Nên đọc khi cần ôn: cache, TTL, eviction policy, distributed lock, pub/sub, stream, persistence, cache penetration, cache breakdown và cache avalanche.

## Kafka

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
