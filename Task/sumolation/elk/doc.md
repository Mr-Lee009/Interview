# ELK là gì?

`ELK` là bộ giải pháp gồm `Elasticsearch`, `Logstash` và `Kibana`, dùng để thu thập, xử lý, lưu trữ, tìm kiếm và trực quan hóa log hoặc dữ liệu sự kiện.

Trong thực tế, nhiều hệ thống còn dùng thêm `Beats`, nên đôi khi người ta gọi rộng hơn là `Elastic Stack`.

## 1. ELK phục vụ công việc gì?

ELK phục vụ các bài toán quan sát hệ thống và khai thác dữ liệu vận hành.

Các nhu cầu điển hình:
- tập trung log từ nhiều server, nhiều service, nhiều môi trường
- tìm kiếm log nhanh khi hệ thống có lỗi
- phân tích nguyên nhân sự cố theo thời gian thực hoặc gần thời gian thực
- theo dõi hành vi hệ thống, hiệu năng, cảnh báo bất thường
- hỗ trợ audit, security monitoring, troubleshooting
- tạo dashboard cho vận hành, DevOps, backend, security, business analytics

Ví dụ thực tế:
- hệ thống microservices có 30 service, mỗi service ghi log riêng: ELK gom tất cả về một nơi
- khi API lỗi `500`, ta có thể search theo `traceId`, `userId`, `orderId`
- khi số lỗi đăng nhập tăng mạnh, dashboard ELK giúp phát hiện nhanh

## 2. Vì sao ELK quan trọng?

Nếu không có ELK hoặc công cụ tương tự:
- log nằm rải rác trên nhiều máy
- debug phải SSH vào từng server
- khó đối chiếu log giữa các service
- khó tìm liên hệ giữa lỗi ứng dụng, hạ tầng và hành vi người dùng

ELK giúp biến log từ dữ liệu thô thành dữ liệu có thể tra cứu và phân tích được.

## 3. Các thành phần chính của ELK

### 3.1 Elasticsearch

`Elasticsearch` là lõi lưu trữ và tìm kiếm.

Chức năng chính:
- lưu dữ liệu dạng document, thường là JSON
- index dữ liệu để tìm kiếm nhanh
- hỗ trợ full-text search, filter, aggregate
- hỗ trợ scale ngang bằng cluster và shard

Nói ngắn gọn: nếu ELK là hệ thống phân tích log thì Elasticsearch là nơi chứa dữ liệu và trả lời truy vấn.

Ví dụ:
- tìm tất cả log lỗi trong 15 phút gần nhất
- đếm số request lỗi theo từng service
- thống kê top IP gọi API nhiều nhất

### 3.2 Logstash

`Logstash` là thành phần ingest và xử lý dữ liệu.

Chức năng chính:
- nhận dữ liệu từ nhiều nguồn
- parse, transform, enrich dữ liệu
- đẩy dữ liệu sang Elasticsearch hoặc nơi khác

Logstash thường làm theo pipeline gồm 3 phần:
- `input`: nhận dữ liệu
- `filter`: xử lý dữ liệu
- `output`: ghi dữ liệu ra đích

Ví dụ:
- đọc file log từ ứng dụng Java
- bóc tách timestamp, level, message, traceId
- đổi format log text sang JSON
- đẩy sang Elasticsearch

### 3.3 Kibana

`Kibana` là lớp giao diện và trực quan hóa.

Chức năng chính:
- search log bằng UI
- vẽ dashboard, chart, bảng thống kê
- xem dữ liệu theo timeline
- tạo alert và rule nếu hệ thống có cấu hình phù hợp

Nói ngắn gọn: Elasticsearch là nơi lưu và tìm, còn Kibana là nơi con người quan sát và phân tích.

Ví dụ:
- dashboard lỗi theo giờ
- số request theo API
- heatmap truy cập theo địa lý
- trang khám phá log theo `traceId`

### 3.4 Beats

`Beats` không nằm trong tên ELK gốc nhưng rất hay đi cùng.

Đây là các agent nhẹ để gửi dữ liệu về Elastic Stack.

Một số loại phổ biến:
- `Filebeat`: ship log file
- `Metricbeat`: ship metric hệ thống
- `Packetbeat`: ship network data
- `Winlogbeat`: ship Windows event log

Trong nhiều hệ thống hiện đại, Beats thay cho một phần ingest nhẹ, còn Logstash chỉ dùng khi cần transform phức tạp.

## 4. Kiến trúc tổng quát của ELK

Một kiến trúc ELK cơ bản thường như sau:
1. ứng dụng, server, container tạo ra log hoặc event
2. `Beats` hoặc `Logstash` thu thập dữ liệu
3. `Logstash` parse và enrich nếu cần
4. dữ liệu được đẩy vào `Elasticsearch`
5. `Kibana` đọc dữ liệu từ Elasticsearch để hiển thị
6. người vận hành dùng Kibana để search, dashboard, alert

Mô hình ngắn:
`Application/Server -> Beats/Logstash -> Elasticsearch -> Kibana`

## 5. ELK phục vụ ai trong công việc hằng ngày?

### Với Backend Developer
- tra cứu lỗi theo request
- đối chiếu log giữa nhiều service
- phân tích nguyên nhân lỗi production
- kiểm tra hành vi API theo thời gian

### Với DevOps/SRE
- quan sát hệ thống tập trung
- phát hiện bất thường
- hỗ trợ incident response
- làm dashboard vận hành

### Với Security
- theo dõi login thất bại
- phát hiện truy cập bất thường
- audit log tập trung

### Với Business hoặc Product
- phân tích hành vi người dùng nếu log có chứa event nghiệp vụ
- theo dõi số lượng giao dịch, đơn hàng, lỗi thanh toán

## 6. Điểm mạnh của ELK

- mạnh về search log và dữ liệu text
- scale tốt nếu thiết kế cluster hợp lý
- hỗ trợ gần thời gian thực
- giao diện Kibana trực quan
- hệ sinh thái rộng, cộng đồng lớn
- phù hợp cho log, audit, observability, security analytics

## 7. Hạn chế và lưu ý

- tốn tài nguyên, đặc biệt là Elasticsearch
- cần quản trị index, shard, retention, lifecycle cẩn thận
- nếu log quá lớn mà không chuẩn hóa sẽ rất khó dùng
- Logstash có thể trở thành bottleneck nếu pipeline nặng
- chi phí lưu trữ tăng nhanh nếu giữ log lâu

Khi triển khai thực tế cần quan tâm:
- chuẩn format log
- retention policy
- index naming strategy
- mapping dữ liệu
- monitoring cho chính cụm ELK

## 8. Khi nào nên dùng ELK?

Nên dùng khi:
- hệ thống có nhiều service hoặc nhiều server
- cần tập trung log
- cần search và dashboard mạnh
- cần hỗ trợ vận hành, debug, audit hoặc security

Không nhất thiết dùng ELK khi:
- hệ thống rất nhỏ
- log ít
- chưa có nhu cầu search hoặc phân tích tập trung

## 9. Tóm tắt ngắn

ELK là bộ công cụ dùng để:
- thu thập log
- xử lý log
- lưu trữ log
- tìm kiếm log
- trực quan hóa log

Ba thành phần cốt lõi:
- `Elasticsearch`: lưu trữ và tìm kiếm
- `Logstash`: ingest và xử lý dữ liệu
- `Kibana`: quan sát và trực quan hóa

Nếu mở rộng thêm `Beats`, ta có một hệ sinh thái hoàn chỉnh hơn cho observability và vận hành hệ thống.
