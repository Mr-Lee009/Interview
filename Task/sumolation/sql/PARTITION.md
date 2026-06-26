Để chia phân vùng (Partitioning) trong MySQL, thông thường chúng ta sử dụng **Range Partitioning** dựa trên khoảng thời gian (như cột `created_at` trong bảng lịch sử giao dịch). Cách này giúp MySQL tự động định tuyến các câu truy vấn vào đúng bảng con, giúp tăng tốc báo cáo.

Dưới đây là các bước và cú pháp thực hiện chuẩn trên MySQL:

---

### 1. Cú pháp tạo bảng với Partition theo tháng

Khi tạo bảng mới, bạn thêm mệnh đề `PARTITION BY RANGE` ở cuối câu lệnh `CREATE TABLE`.

Giả sử bạn muốn chia phân vùng cho bảng `payment_transaction` theo từng tháng dựa trên cột `created_at`:

```sql
CREATE TABLE payment_transaction (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    payment_code VARCHAR(64) NOT NULL,
    order_id VARCHAR(64) NOT NULL,
    provider VARCHAR(20) NOT NULL,
    amount BIGINT NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id, created_at) -- Lưu ý: Trong MySQL, nếu bảng có Partition theo cột nào, cột đó phải là một phần của Primary Key
) ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_unicode_ci
PARTITION BY RANGE (UNIX_TIMESTAMP(created_at)) (
    PARTITION p_2026_05 VALUES LESS THAN (UNIX_TIMESTAMP('2026-06-01 00:00:00')),
    PARTITION p_2026_06 VALUES LESS THAN (UNIX_TIMESTAMP('2026-07-01 00:00:00')),
    PARTITION p_2026_07 VALUES LESS THAN (UNIX_TIMESTAMP('2026-08-01 00:00:00')),
    PARTITION p_2026_08 VALUES LESS THAN (UNIX_TIMESTAMP('2026-09-01 00:00:00')),
    PARTITION p_catch_all VALUES LESS THAN MAXVALUE
);

```

* **Giải thích:**
* `PARTITION BY RANGE (UNIX_TIMESTAMP(created_at))`: MySQL không hỗ trợ trực tiếp hàm `DATE()` hoặc `DATETIME` trong Range Partitioning, nên ta phải chuyển nó về dạng số nguyên bằng hàm `UNIX_TIMESTAMP()`.
* `VALUES LESS THAN (...)`: Mốc thời gian giới hạn (được tính bằng timestamp). Ví dụ phân vùng `p_2026_05` sẽ chứa dữ liệu trước ngày `2026-06-01`.
* `PARTITION p_catch_all VALUES LESS THAN MAXVALUE`: Phân vùng dự phòng. Nếu có dữ liệu vượt quá các mốc trên, nó sẽ tự động rơi vào đây để hệ thống không bị lỗi chèn dữ liệu.



---

### 2. Cách thêm Partition mới cho các tháng tiếp theo

Khi hệ thống chạy sang tháng mới (ví dụ tháng 9), bạn cần chủ động thêm phân vùng mới bằng lệnh `ALTER TABLE`:

```sql
ALTER TABLE payment_transaction ADD PARTITION (
    PARTITION p_2026_09 VALUES LESS THAN (UNIX_TIMESTAMP('2026-10-01 00:00:00'))
);

```

---

### 3. Kiểm tra các Partition đã hoạt động chưa

Bạn có thể kiểm tra xem dữ liệu của mình đang nằm ở những phân vùng nào bằng câu lệnh:

```sql
SELECT 
    PARTITION_NAME, 
    TABLE_ROWS, 
    CREATE_TIME, 
    TABLE_NAME 
FROM information_schema.PARTITIONS 
WHERE TABLE_SCHEMA = 'bkis_edu' -- Thay bằng tên database của bạn
  AND TABLE_NAME = 'payment_transaction';

```

---

### 💡 Lưu ý cực kỳ quan trọng khi dùng Partition trong MySQL

1. **Ràng buộc Khóa chính (Primary Key):** Nếu bảng của bạn có khóa chính, cột dùng để chia partition (trong trường hợp này là `created_at`) **bắt buộc phải nằm trong định nghĩa Khóa chính**. Đó là lý do khóa chính trong đoạn lệnh mẫu được khai báo là `PRIMARY KEY (id, created_at)`.
2. **Partition Pruning (Tối ưu hóa tự động):** Khi bạn viết câu lệnh `WHERE created_at >= '2026-05-01...'`, bộ tối ưu hóa của MySQL rất thông minh, nó sẽ tự động bỏ qua các phân vùng tháng 6, tháng 7 mà chỉ quét đúng phân vùng `p_2026_05`, giúp câu lệnh báo cáo chạy nhanh tức thì.