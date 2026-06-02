# Interview Simulation Notes

Thư mục này là bộ tài liệu ôn tập và mô phỏng kiến thức dùng cho phỏng vấn backend/Java. Nội dung được gom theo từng chủ đề kỹ thuật để có thể đọc nhanh trước buổi phỏng vấn, hoặc dùng làm nguồn tham chiếu khi cần tạo thêm demo, câu hỏi, câu trả lời và ví dụ thực tế.

## Mục tiêu project

- Lưu trữ tài liệu phỏng vấn theo chủ đề: Java, Redis, Kafka, CA/X.509, chữ ký số và Design Pattern.
- Có các file HTML demo trực quan cho một số chủ đề để giải thích luồng xử lý hoặc khái niệm khó.
- Giữ mỗi chủ đề trong một thư mục riêng để sau này dễ bổ sung câu hỏi, note, flow, sơ đồ hoặc demo mới.
- Làm tài liệu nội bộ cho người mở project lần sau hiểu nhanh: project này không phải app production, mà là kho kiến thức luyện phỏng vấn.

## Cách đọc nhanh

1. Mở `menu.md` để xem toàn bộ bản đồ tài liệu.
2. Đọc file `doc.md` trong từng thư mục chủ đề để nắm khái niệm chính.
3. Mở các file `index.html`, `index-2.html` hoặc `demo.html` nếu muốn xem phần mô phỏng trực quan.
4. Với Design Pattern, đọc file tổng quan trước rồi đi vào từng nhóm `creational_patterns`, `structural_patterns`, `behavioral_patterns`.

## Cấu trúc chính

- `redis/`: ghi chú và demo về Redis, cache, TTL, eviction, distributed lock và các câu hỏi phỏng vấn liên quan.
- `kafka/`: demo HTML về Kafka, dùng để mô phỏng producer, broker, consumer, topic, partition hoặc message flow.
- `CA/`: tài liệu chữ ký số, PKI, Certificate Authority và X.509.
- `patten/`: tài liệu Design Pattern theo nhóm GoF. Tên thư mục hiện đang là `patten`; có thể hiểu là `pattern`.
- `index.html`: demo mô phỏng nhận diện vân tay/sinh trắc học, dùng như ví dụ trực quan về quy trình scan, trích xuất đặc trưng và đối chiếu dữ liệu.

## Quy ước khi bổ sung tài liệu

- Mỗi chủ đề nên có một `doc.md` làm điểm vào chính.
- Nếu thêm demo HTML, ghi chú lại trong `menu.md` để biết demo đó phục vụ mục đích gì.
- Ưu tiên viết theo format phỏng vấn: khái niệm ngắn, luồng hoạt động, câu hỏi hay gặp, lỗi thường gặp và ví dụ thực tế.
- Không cần biến project thành ứng dụng hoàn chỉnh nếu mục tiêu chỉ là lưu note phỏng vấn.
