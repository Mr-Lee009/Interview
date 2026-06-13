# Nếu hệ thống có 1 triệu bản ghi thì xử lý tìm kiếm như thế nào?

Đây là câu hỏi rất hay trong phỏng vấn vì `1 triệu bản ghi` chưa phải dữ liệu khổng lồ, nhưng đủ lớn để cách làm ngây thơ như:

- `SELECT *`
- lọc trong memory
- phân trang bằng cách lấy toàn bộ rồi cắt list

trở thành sai thiết kế.

## 1. Ý chính cần trả lời

Với `1 triệu bản ghi`, tôi sẽ không nhảy ngay sang công nghệ lớn như Elasticsearch nếu bài toán chỉ là tìm kiếm cơ bản.  
Tôi sẽ đi theo thứ tự:

1. tối ưu `database query`
2. thêm `index` đúng
3. phân trang đúng cách
4. cache nếu dữ liệu đọc nhiều
5. chỉ dùng `search engine` như Elasticsearch/OpenSearch khi có nhu cầu full-text, ranking, fuzzy search hoặc traffic lớn

Tức là phải chọn giải pháp theo `kiểu tìm kiếm`, không phải chỉ theo số lượng record.

---

## 2. Trước hết phải phân loại bài toán tìm kiếm

Không phải mọi tìm kiếm đều giống nhau.

### Loại 1. Tìm kiếm chính xác theo ID hoặc mã

Ví dụ:

- tìm theo `accountId`
- tìm theo `orderId`
- tìm theo `email`

Trường hợp này chỉ cần:

- database quan hệ như MySQL/PostgreSQL
- index chuẩn trên cột tìm kiếm

Với `1 triệu record`, DB vẫn xử lý tốt nếu index đúng.

### Loại 2. Tìm kiếm theo điều kiện lọc

Ví dụ:

- trạng thái = `ACTIVE`
- ngày tạo từ `2026-01-01` đến `2026-06-01`
- chi nhánh = `HCM`
- loại tài khoản = `MARGIN`

Trường hợp này cần:

- index cho các cột filter chính
- có thể dùng `composite index`
- query chỉ select cột cần thiết

### Loại 3. Tìm kiếm text

Ví dụ:

- tìm theo tên khách hàng
- tìm theo mô tả lệnh
- tìm gần đúng, không dấu, typo, ranking

Trường hợp này DB thường bắt đầu yếu nếu yêu cầu:

- `contains`
- `LIKE %keyword%`
- sắp xếp theo độ liên quan
- gợi ý từ khóa

Lúc này nên cân nhắc:

- `full-text index` nếu bài toán còn đơn giản
- `Elasticsearch/OpenSearch` nếu search là chức năng quan trọng

---

## 3. Cách xử lý đúng với 1 triệu bản ghi

## 3.1 Không quét toàn bảng nếu có thể tránh

Sai lầm phổ biến:

```sql
SELECT * FROM customers WHERE name LIKE '%anh%';
```

Nếu không có index phù hợp, DB phải scan rất nhiều dòng.

Cách xử lý:

- tạo index cho cột thường tìm kiếm
- tránh `LIKE %keyword%` nếu không cần
- ưu tiên query có thể tận dụng index

Ví dụ tốt hơn:

```sql
SELECT id, name, email
FROM customers
WHERE email = ?
```

Nếu `email` có index hoặc unique index, query sẽ rất nhanh.

---

## 3.2 Tạo index đúng

Index là thứ đầu tiên cần nghĩ tới.

### Ví dụ index đơn

```sql
CREATE INDEX idx_customer_email ON customers(email);
CREATE INDEX idx_customer_created_at ON customers(created_at);
```

### Ví dụ composite index

Nếu query hay dùng:

```sql
WHERE branch_id = ? AND status = ? AND created_at >= ?
```

thì có thể tạo:

```sql
CREATE INDEX idx_customer_branch_status_created
ON customers(branch_id, status, created_at);
```

### Lưu ý

- không tạo quá nhiều index vì sẽ làm chậm `insert/update`
- index phải bám theo query thực tế
- nên dùng `EXPLAIN` để kiểm tra DB có dùng index không

---

## 3.3 Phân trang đúng cách

Nếu có `1 triệu record`, không được trả toàn bộ về frontend.

### Cách cơ bản

```sql
SELECT id, name, status
FROM customers
ORDER BY id
LIMIT 20 OFFSET 0;
```

### Vấn đề của OFFSET lớn

Nếu:

```sql
LIMIT 20 OFFSET 900000
```

thì DB vẫn phải bỏ qua rất nhiều dòng trước khi lấy được 20 dòng cần thiết.

### Cách tốt hơn: keyset pagination

Ví dụ:

```sql
SELECT id, name, status
FROM customers
WHERE id > ?
ORDER BY id
LIMIT 20;
```

Ưu điểm:

- nhanh hơn với dataset lớn
- phù hợp infinite scroll hoặc next page
- ổn định hơn khi dữ liệu thay đổi liên tục

### Kết luận

- admin page đơn giản có thể dùng `LIMIT/OFFSET`
- traffic lớn hoặc page sâu nên dùng `keyset pagination`

---

## 3.4 Chỉ lấy cột cần thiết

Không nên:

```sql
SELECT *
```

Nên:

```sql
SELECT id, full_name, phone, status
```

Lý do:

- giảm IO
- giảm network payload
- giảm memory ứng dụng

Với `1 triệu record`, tối ưu nhỏ kiểu này cộng dồn lại rất đáng kể.

---

## 3.5 Cache cho dữ liệu đọc nhiều

Nếu một số truy vấn lặp lại nhiều lần, có thể cache bằng Redis.

Ví dụ:

- top khách hàng mới nhất
- danh sách mã chứng khoán phổ biến
- thông tin tài khoản đọc nhiều nhưng ít thay đổi

### Cách làm

- query DB lần đầu
- lưu kết quả vào Redis với TTL
- các request sau đọc từ cache

### Lưu ý

- cache chỉ giúp giảm tải
- cache không thay thế index hay query tối ưu
- phải có chiến lược invalidation khi dữ liệu đổi

---

## 3.6 Dùng search engine khi bài toán search phức tạp

Nếu yêu cầu là:

- search theo tên gần đúng
- không dấu
- typo tolerant
- ranking theo độ liên quan
- highlight keyword
- autocomplete

thì tôi sẽ tách search ra `Elasticsearch/OpenSearch`.

### Kiến trúc phổ biến

1. dữ liệu gốc vẫn nằm ở `MySQL/PostgreSQL`
2. khi dữ liệu thay đổi, publish event
3. worker đồng bộ sang Elasticsearch
4. user search thì query vào Elasticsearch

### Vì sao không dùng DB luôn?

Vì DB quan hệ mạnh về:

- transaction
- lọc chính xác
- join

Nhưng không phải công cụ tốt nhất cho:

- full-text search
- fuzzy search
- relevance scoring

---

## 4. Nếu là câu hỏi phỏng vấn, nên trả lời theo từng mức

## Mức 1: 1 triệu record chưa cần quá phức tạp

Tôi sẽ nói:

`1 triệu bản ghi chưa phải quy mô buộc phải dùng công nghệ đặc biệt. Nếu tìm kiếm theo ID, mã, trạng thái, ngày tạo thì chỉ cần thiết kế query đúng, tạo index phù hợp, phân trang chuẩn và tránh full table scan là database vẫn xử lý tốt.`

## Mức 2: Nếu search bắt đầu nặng

Tôi sẽ thêm:

- dùng `EXPLAIN`
- tối ưu index
- keyset pagination
- cache Redis cho truy vấn lặp lại

## Mức 3: Nếu search là tính năng chính

Tôi sẽ nói tiếp:

`Nếu yêu cầu search theo text, gần đúng, ranking hoặc autocomplete thì tôi sẽ tách search sang Elasticsearch/OpenSearch, còn DB vẫn là source of truth.`

---

## 5. Ví dụ thực tế

Giả sử có bảng `orders` với `1 triệu` lệnh chứng khoán.

Người dùng tìm theo:

- `orderId`
- `accountId`
- `status`
- `createdAt`

### Cách thiết kế

- index `order_id`
- index `account_id, created_at`
- index `status, created_at` nếu filter nhiều theo trạng thái
- API bắt buộc phân trang
- chỉ trả về các cột hiển thị ở list page

Ví dụ:

```sql
SELECT order_id, account_id, symbol, side, quantity, status, created_at
FROM orders
WHERE account_id = ?
  AND created_at >= ?
ORDER BY created_at DESC
LIMIT 50;
```

Nếu người dùng cần search theo `symbol name`, `customer name`, gần đúng hoặc autocomplete:

- đồng bộ dữ liệu sang Elasticsearch
- search ở Elasticsearch
- click vào kết quả thì đọc chi tiết từ DB

---

## 6. Các lỗi thiết kế thường gặp

### Lỗi 1. Đọc toàn bộ rồi lọc trong Java

Sai vì:

- tốn RAM
- chậm
- không scale

### Lỗi 2. Dùng `LIKE %keyword%` cho mọi thứ

Sai vì:

- khó dùng index
- dễ full scan

### Lỗi 3. Phân trang bằng OFFSET rất sâu

Sai vì:

- page càng sâu càng chậm

### Lỗi 4. Lạm dụng cache khi query gốc chưa tối ưu

Sai vì:

- che giấu vấn đề thật
- invalidation phức tạp

### Lỗi 5. Dùng Elasticsearch quá sớm

Sai vì:

- tăng độ phức tạp vận hành
- thêm chi phí đồng bộ dữ liệu
- chưa chắc cần nếu chỉ là exact match/filter

---

## 7. Câu trả lời ngắn gọn mẫu

`Nếu hệ thống có 1 triệu bản ghi thì tôi sẽ không load hết dữ liệu để tìm kiếm. Tôi sẽ xác định loại search là exact match, filter hay full-text. Với tìm kiếm thông thường, tôi tối ưu bằng index phù hợp, query chỉ lấy cột cần thiết, phân trang đúng cách và dùng Redis cache cho truy vấn lặp lại. Nếu search phức tạp như gần đúng, autocomplete hoặc ranking thì tôi sẽ tách sang Elasticsearch/OpenSearch, còn database vẫn là nguồn dữ liệu gốc.`

---

## 8. Kết luận

Với `1 triệu bản ghi`, cách xử lý đúng không phải là đổi công nghệ ngay, mà là:

1. thiết kế query đúng
2. tạo index đúng
3. phân trang đúng
4. cache đúng chỗ
5. chỉ tách sang search engine khi bài toán search thực sự cần

Đó là cách trả lời vừa thực tế vừa đúng tư duy thiết kế hệ thống.
