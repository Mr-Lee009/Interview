# Oracle SQL - Tips thực chiến

Các ví dụ dùng Oracle XE 21c. Chạy câu lệnh DDL bằng user có quyền phù hợp, ví dụ `APP_USER` cho object trong schema ứng dụng.

## 1. Đặt tên và chọn kiểu dữ liệu hợp lý

- Dùng tên bảng/cột rõ ràng, không dùng từ khóa Oracle như `USER`, `DATE`, `STATUS` nếu không cần.
- Tiền, số lượng và dữ liệu cần chính xác dùng `NUMBER(p,s)`.
- Chuỗi thông thường dùng `VARCHAR2`, không dùng `CHAR` cho tên hoặc email.
- Ngày giờ giao dịch nên cân nhắc `TIMESTAMP WITH TIME ZONE` nếu hệ thống có nhiều múi giờ.
- Không lưu mật khẩu dạng rõ; chỉ lưu hash và salt từ tầng ứng dụng.

```sql
CREATE TABLE orders (
  order_id   NUMBER(19) PRIMARY KEY,
  user_id    NUMBER(19) NOT NULL,
  order_date TIMESTAMP(6) WITH TIME ZONE DEFAULT SYSTIMESTAMP NOT NULL,
  total      NUMBER(12, 2) DEFAULT 0 NOT NULL,
  status     VARCHAR2(20 CHAR) DEFAULT 'PENDING' NOT NULL,
  CONSTRAINT ck_orders_total CHECK (total >= 0),
  CONSTRAINT ck_orders_status CHECK (status IN ('PENDING', 'PAID', 'CANCELLED'))
);
```

## 2. Index: tạo đúng cột cần tìm kiếm

Index giúp Oracle tìm dòng nhanh hơn thay vì đọc toàn bộ bảng, nhưng index cũng tốn dung lượng và làm `INSERT`, `UPDATE`, `DELETE` chậm hơn. Không nên tạo index cho mọi cột.

### Index đơn

```sql
-- Tìm user theo email thường xuyên
CREATE INDEX idx_users_email ON users(email);

-- Tìm đơn hàng theo user
CREATE INDEX idx_orders_user_id ON orders(user_id);
```

Không cần tạo index riêng cho cột đã có `PRIMARY KEY` hoặc `UNIQUE`, vì Oracle thường tự tạo unique index cho constraint đó.

### Composite index

Thứ tự cột rất quan trọng. Index `(status, order_date)` phù hợp với truy vấn lọc `status` rồi sắp xếp/lọc `order_date`.

```sql
CREATE INDEX idx_orders_status_date
ON orders(status, order_date);

SELECT order_id, user_id, order_date, total
FROM orders
WHERE status = 'PAID'
  AND order_date >= TIMESTAMP '2026-01-01 00:00:00 +00:00'
ORDER BY order_date DESC;
```

Quy tắc thực tế:

- Đặt cột thường dùng trong `WHERE` ở đầu index.
- Với index `(a, b)`, truy vấn chỉ lọc `b` thường không tận dụng tốt index đó.
- Cột có độ phân biệt thấp như `gender` hoặc cờ `Y/N` thường không đáng tạo index đơn.
- Index trên cột foreign key có thể giảm lock và tăng tốc JOIN/xóa bản ghi cha.

### Function-based index

Nếu dùng hàm trên cột trong `WHERE`, index thông thường có thể không được dùng. Tạo function-based index hoặc viết điều kiện theo khoảng giá trị.

```sql
CREATE INDEX idx_users_lower_email
ON users(LOWER(email));

SELECT user_id, username, email
FROM users
WHERE LOWER(email) = 'duc@example.com';
```

### Tránh làm mất khả năng dùng index

```sql
-- Có thể khiến Oracle phải xử lý hàm trên toàn bộ cột
WHERE TO_CHAR(order_date, 'YYYY-MM-DD') = '2026-08-27'

-- Tốt hơn: giữ nguyên cột và dùng khoảng thời gian
WHERE order_date >= TIMESTAMP '2026-08-27 00:00:00'
  AND order_date <  TIMESTAMP '2026-08-28 00:00:00'
```

### Kiểm tra index và kế hoạch thực thi

```sql
SELECT index_name, index_type, status, visibility
FROM user_indexes
WHERE table_name = 'ORDERS';

SELECT index_name, column_position, column_name
FROM user_ind_columns
WHERE table_name = 'ORDERS'
ORDER BY index_name, column_position;

EXPLAIN PLAN FOR
SELECT * FROM orders
WHERE status = 'PAID' AND order_date >= TIMESTAMP '2026-01-01 00:00:00';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
```

`EXPLAIN PLAN` là ước lượng. Khi cần phân tích truy vấn thật, xem execution plan sau khi chạy và kiểm tra số dòng thực tế.

## 3. Partition: chia bảng lớn thành các phần nhỏ

Partition không thay thế index. Partition giúp Oracle chỉ đọc partition liên quan, gọi là **partition pruning**, đặc biệt hữu ích với bảng log/giao dịch lớn có điều kiện theo ngày.

### Range partition theo tháng

Dùng cột ngày làm partition key. Mỗi partition chứa các giá trị nhỏ hơn mốc `VALUES LESS THAN`.

```sql
CREATE TABLE orders_by_month (
  order_id   NUMBER(19) NOT NULL,
  user_id    NUMBER(19) NOT NULL,
  order_date DATE NOT NULL,
  total      NUMBER(12, 2) NOT NULL,
  status     VARCHAR2(20 CHAR) NOT NULL,
  CONSTRAINT pk_orders_by_month PRIMARY KEY (order_id, order_date)
)
PARTITION BY RANGE (order_date) (
  PARTITION p2026_01 VALUES LESS THAN (DATE '2026-02-01'),
  PARTITION p2026_02 VALUES LESS THAN (DATE '2026-03-01'),
  PARTITION p2026_03 VALUES LESS THAN (DATE '2026-04-01'),
  PARTITION pmax    VALUES LESS THAN (MAXVALUE)
);
```

`p2026_01` chứa dữ liệu từ trước `2026-02-01`, bao gồm tháng 01. Không nên dùng `BETWEEN` để định nghĩa mốc partition vì có thể gây lỗi biên.

### Insert và query để partition pruning hoạt động

```sql
INSERT INTO orders_by_month (order_id, user_id, order_date, total, status)
VALUES (1001, 1, DATE '2026-02-15', 250.00, 'PAID');

COMMIT;

-- Oracle có thể chỉ đọc partition chứa tháng 02
SELECT order_id, user_id, total
FROM orders_by_month
WHERE order_date >= DATE '2026-02-01'
  AND order_date <  DATE '2026-03-01';
```

### Thêm partition cho tháng mới

```sql
ALTER TABLE orders_by_month
SPLIT PARTITION pmax AT (DATE '2026-04-01')
INTO (
  PARTITION p2026_04,
  PARTITION pmax
);
```

Cách khác, nếu bảng không có `pmax`:

```sql
ALTER TABLE orders_by_month
ADD PARTITION p2026_05 VALUES LESS THAN (DATE '2026-06-01');
```

### Partition theo HASH và LIST

`HASH` phân tán tương đối đều theo khóa, phù hợp khi cần chia dữ liệu để tăng khả năng song song nhưng không có điều kiện thời gian rõ ràng.

```sql
CREATE TABLE user_events_hash (
  event_id NUMBER PRIMARY KEY,
  user_id  NUMBER NOT NULL,
  payload  CLOB
)
PARTITION BY HASH (user_id)
PARTITIONS 4;
```

`LIST` phù hợp nhóm rời rạc như khu vực hoặc quốc gia.

```sql
CREATE TABLE users_by_region (
  user_id NUMBER,
  region  VARCHAR2(20),
  email   VARCHAR2(255)
)
PARTITION BY LIST (region) (
  PARTITION p_vietnam VALUES ('VN'),
  PARTITION p_asia   VALUES ('JP', 'KR', 'SG'),
  PARTITION p_other  VALUES (DEFAULT)
);
```

### Local index trên bảng partition

```sql
CREATE INDEX idx_orders_month_status
ON orders_by_month(status)
LOCAL;
```

Local index được chia theo partition của bảng, dễ bảo trì khi thêm/xóa partition. Chỉ dùng partition cho bảng đủ lớn và có chiến lược quản trị dữ liệu rõ ràng; bảng nhỏ thường không cần partition.

## 4. So sánh ngày và giờ

### Dùng literal thay vì chuỗi mơ hồ

```sql
-- DATE literal, không phụ thuộc NLS_DATE_FORMAT
SELECT * FROM orders
WHERE order_date >= DATE '2026-08-01'
  AND order_date <  DATE '2026-09-01';

-- TIMESTAMP literal
SELECT * FROM orders
WHERE order_date >= TIMESTAMP '2026-08-27 00:00:00 +07:00';
```

`DATE 'YYYY-MM-DD'` không chứa giờ, nên dùng khoảng `[ngày bắt đầu, ngày kế tiếp)` để lấy trọn một ngày.

### So sánh ngày hôm nay

```sql
-- SYSDATE trả về DATE theo thời gian máy chủ DB
SELECT * FROM orders
WHERE order_date >= TRUNC(SYSDATE)
  AND order_date <  TRUNC(SYSDATE) + 1;

-- SYSTIMESTAMP trả về TIMESTAMP WITH TIME ZONE
SELECT * FROM orders
WHERE order_date >= SYSTIMESTAMP - INTERVAL '7' DAY;
```

Không nên viết `TRUNC(order_date) = TRUNC(SYSDATE)` trên bảng lớn nếu chưa có function-based index, vì hàm `TRUNC` được áp dụng lên cột.

### So sánh chỉ phần ngày

```sql
-- Tốt cho index trên order_date
WHERE order_date >= :date_from
  AND order_date <  :date_to + 1
```

Nếu `:date_from` và `:date_to` là `DATE` không chứa giờ, điều kiện trên lấy từ đầu ngày đầu tiên đến hết ngày cuối cùng.

## 5. Convert kiểu dữ liệu

### Chuỗi sang DATE/TIMESTAMP

Luôn chỉ rõ format để không phụ thuộc cấu hình NLS của session.

```sql
SELECT TO_DATE('27/08/2026', 'DD/MM/YYYY') AS order_day
FROM dual;

SELECT TO_TIMESTAMP(
  '27/08/2026 14:30:45',
  'DD/MM/YYYY HH24:MI:SS'
) AS created_time
FROM dual;

SELECT TO_TIMESTAMP_TZ(
  '2026-08-27 14:30:45 +07:00',
  'YYYY-MM-DD HH24:MI:SS TZH:TZM'
) AS created_time
FROM dual;
```

### DATE/TIMESTAMP sang chuỗi

```sql
SELECT TO_CHAR(order_date, 'YYYY-MM-DD HH24:MI:SS') AS formatted_date
FROM orders;
```

`TO_CHAR` dùng để hiển thị, không nên dùng để so sánh ngày trong `WHERE` nếu có thể so sánh bằng kiểu ngày.

### CAST

```sql
SELECT CAST(order_date AS DATE) AS order_date_only_type
FROM orders;

SELECT CAST(total AS NUMBER(12, 2)) AS normalized_total
FROM orders;

SELECT CAST('123.45' AS NUMBER(10, 2)) AS amount
FROM dual;
```

`CAST` chuyển kiểu theo quy tắc SQL; `TO_DATE`, `TO_NUMBER`, `TO_TIMESTAMP` cho phép chỉ rõ format phù hợp dữ liệu chuỗi.

### Xử lý chuỗi không hợp lệ

Oracle 12.2+ có thể trả về `NULL` thay vì báo lỗi khi convert thất bại:

```sql
SELECT TO_DATE(
         '2026-99-99' DEFAULT NULL ON CONVERSION ERROR,
         'YYYY-MM-DD'
       ) AS converted_date
FROM dual;
```

Dù dùng cách này, dữ liệu đầu vào vẫn nên được kiểm tra từ ứng dụng.

## 6. Câu lệnh rẽ nhánh

### CASE

`CASE` là lựa chọn rõ ràng và linh hoạt nhất.

```sql
SELECT order_id, total,
  CASE
    WHEN total >= 1000 THEN 'VIP'
    WHEN total >= 500  THEN 'PREMIUM'
    WHEN total >= 100   THEN 'STANDARD'
    ELSE 'BASIC'
  END AS customer_level
FROM orders;
```

CASE trong `UPDATE`:

```sql
UPDATE orders
SET status = CASE
               WHEN total = 0 THEN 'CANCELLED'
               WHEN total >= 1000 THEN 'PAID'
               ELSE status
             END
WHERE status = 'PENDING';
```

### NVL, COALESCE và NULLIF

```sql
-- Giá trị thay thế khi total là NULL
SELECT order_id, NVL(total, 0) AS safe_total
FROM orders;

-- Lấy giá trị khác NULL đầu tiên
SELECT COALESCE(phone, email, 'NO_CONTACT') AS contact
FROM users;

-- Tránh chia cho 0
SELECT total / NULLIF(item_count, 0) AS average_item_value
FROM order_summary;
```

`COALESCE` hỗ trợ nhiều giá trị; `NVL` là hàm Oracle quen thuộc với hai giá trị.

### DECODE

`DECODE` phù hợp ánh xạ giá trị đơn giản, nhưng `CASE` dễ đọc hơn khi có điều kiện khoảng.

```sql
SELECT order_id,
       DECODE(status,
              'PAID', 'Đã thanh toán',
              'PENDING', 'Đang chờ',
              'CANCELLED', 'Đã hủy',
              'Không xác định') AS status_name
FROM orders;
```

## 7. Truy vấn lồng (subquery)

### Scalar subquery

Trả về một giá trị duy nhất cho mỗi dòng bên ngoài.

```sql
SELECT u.username,
       (SELECT COUNT(*)
        FROM orders o
        WHERE o.user_id = u.user_id) AS order_count
FROM users u;
```

Subquery phải trả tối đa một dòng. Nếu trả nhiều dòng, Oracle báo `ORA-01427: single-row subquery returns more than one row`.

### Subquery trong WHERE

```sql
-- User có đơn hàng đã thanh toán
SELECT user_id, username
FROM users
WHERE user_id IN (
  SELECT user_id
  FROM orders
  WHERE status = 'PAID'
);
```

Nếu chỉ cần kiểm tra tồn tại, ưu tiên `EXISTS`:

```sql
SELECT u.user_id, u.username
FROM users u
WHERE EXISTS (
  SELECT 1
  FROM orders o
  WHERE o.user_id = u.user_id
    AND o.status = 'PAID'
);
```

### Subquery trong FROM (inline view)

```sql
SELECT username, total_orders
FROM (
  SELECT u.username, COUNT(o.order_id) AS total_orders
  FROM users u
  LEFT JOIN orders o ON o.user_id = u.user_id
  GROUP BY u.username
)
WHERE total_orders >= 2;
```

### CTE với WITH

CTE làm truy vấn dài dễ đọc và có thể tách từng bước xử lý.

```sql
WITH paid_orders AS (
  SELECT user_id, COUNT(*) AS paid_count, SUM(total) AS paid_total
  FROM orders
  WHERE status = 'PAID'
  GROUP BY user_id
)
SELECT u.username,
       NVL(p.paid_count, 0) AS paid_count,
       NVL(p.paid_total, 0) AS paid_total
FROM users u
LEFT JOIN paid_orders p ON p.user_id = u.user_id
ORDER BY paid_total DESC;
```

## 8. Một số tip truy vấn quan trọng

### Dùng bind variable

```sql
SELECT order_id, total
FROM orders
WHERE user_id = :user_id
  AND status = :status;
```

Bind variable giúp tái sử dụng execution plan và giảm rủi ro SQL injection. Ứng dụng phải truyền giá trị bằng API bind parameter, không nối chuỗi SQL thủ công.

### Phân trang ổn định

```sql
SELECT order_id, user_id, order_date, total
FROM orders
ORDER BY order_date DESC, order_id DESC
OFFSET :offset_rows ROWS
FETCH NEXT :page_size ROWS ONLY;
```

Luôn thêm cột duy nhất như `order_id` vào `ORDER BY` để các dòng có cùng ngày vẫn có thứ tự ổn định.

### Không dùng SELECT * trong ứng dụng

```sql
-- Nên lấy đúng cột cần dùng
SELECT order_id, status, total
FROM orders
WHERE user_id = :user_id;
```

Điều này giảm dữ liệu truyền qua mạng và giúp code ít phụ thuộc vào việc thêm cột mới.

### Transaction

```sql
UPDATE orders
SET status = 'PAID'
WHERE order_id = :order_id;

-- COMMIT khi nghiệp vụ hoàn tất
COMMIT;

-- ROLLBACK nếu phát hiện lỗi trước COMMIT
-- ROLLBACK;
```

Không gọi `COMMIT` sau từng dòng trong một batch lớn; hãy commit theo ranh giới nghiệp vụ hoặc kích thước batch phù hợp.

## 9. Cheat sheet nhanh

| Nhu cầu | Nên dùng |
|---|---|
| Tiền/số chính xác | `NUMBER(p,s)` |
| So sánh ngày | `DATE`/`TIMESTAMP` literal và khoảng thời gian |
| Hiển thị ngày | `TO_CHAR` |
| Chuỗi sang ngày | `TO_DATE` với format rõ ràng |
| Chuỗi sang số | `TO_NUMBER` hoặc `CAST` |
| Điều kiện nhiều nhánh | `CASE` |
| Thay thế `NULL` | `COALESCE` hoặc `NVL` |
| Tránh chia cho 0 | `NULLIF` |
| Kiểm tra có bản ghi | `EXISTS` |
| Query trung gian nhiều bước | `WITH` (CTE) |
| Tìm nhanh theo cột | Index phù hợp và kiểm tra execution plan |
| Bảng giao dịch rất lớn theo ngày | Range partition theo ngày/tháng |

## 10. Xem chiến lược thực thi SQL

Oracle gọi chiến lược thực thi là **execution plan**. Kế hoạch cho biết Oracle sẽ đọc bảng, dùng index, JOIN và sắp xếp dữ liệu như thế nào.

### Cách 1: `EXPLAIN PLAN`

`EXPLAIN PLAN` chỉ tạo kế hoạch dự kiến, không thực thi câu SQL.

```sql
EXPLAIN PLAN FOR
SELECT o.order_id, o.order_date, o.total
FROM orders o
WHERE o.user_id = 1
  AND o.status = 'PAID'
ORDER BY o.order_date DESC;

SELECT *
FROM TABLE(DBMS_XPLAN.DISPLAY(
  NULL,
  NULL,
  'BASIC +PREDICATE +ALIAS'
));
```

Nếu query chạy trong schema hiện tại, bảng kế hoạch mặc định là `PLAN_TABLE`. Nếu chưa có bảng này, user có quyền DBA có thể chạy script Oracle cung cấp:

```sql
@?/rdbms/admin/utlxplan.sql
```

### Cách 2: Xem kế hoạch thực tế bằng `DBMS_XPLAN.DISPLAY_CURSOR`

Đây là cách đáng tin cậy hơn vì có thể xem số dòng Oracle **ước tính** và **thực tế**.

```sql
SELECT /*+ gather_plan_statistics */
       o.order_id, o.order_date, o.total
FROM orders o
WHERE o.user_id = 1
  AND o.status = 'PAID'
ORDER BY o.order_date DESC;

SELECT *
FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(
  NULL,
  NULL,
  'ALLSTATS LAST +PREDICATE +ALIAS'
));
```

`gather_plan_statistics` yêu cầu Oracle thu thập thống kê cho lần chạy đó. Nếu ứng dụng không cho phép hint hoặc không muốn dùng hint, có thể bật thống kê cho session:

```sql
ALTER SESSION SET statistics_level = ALL;
```

Sau đó chạy query, rồi gọi lại `DBMS_XPLAN.DISPLAY_CURSOR`.

### Tìm SQL vừa chạy trong shared pool

Nếu không truyền `NULL`, có thể tìm `SQL_ID` trong `V$SQL`:

```sql
SELECT sql_id, child_number, executions, buffer_gets, disk_reads,
       elapsed_time, rows_processed, sql_text
FROM v$sql
WHERE sql_text LIKE 'SELECT%FROM orders%'
ORDER BY last_active_time DESC;
```

Xem kế hoạch của một SQL cụ thể:

```sql
SELECT *
FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(
  'SQL_ID_CAN_TIM',
  NULL,
  'ALLSTATS LAST +PEEKED_BINDS +PREDICATE'
));
```

`V$SQL` cần quyền phù hợp, thường là `SELECT_CATALOG_ROLE` hoặc quyền `SELECT` trên view.

### Cách đọc một số operation thường gặp

| Operation | Ý nghĩa | Nhận xét |
|---|---|---|
| `TABLE ACCESS FULL` | Đọc toàn bộ bảng | Có thể bình thường với bảng nhỏ hoặc khi cần phần lớn dữ liệu |
| `INDEX UNIQUE SCAN` | Tìm đúng một khóa duy nhất | Thường hiệu quả với primary key/unique key |
| `INDEX RANGE SCAN` | Đọc một khoảng giá trị trong index | Phù hợp điều kiện bằng hoặc khoảng trên cột có index |
| `TABLE ACCESS BY INDEX ROWID` | Dùng rowid từ index để lấy dòng trong bảng | Thường đi sau index scan |
| `HASH JOIN` | Tạo hash để JOIN hai tập dữ liệu | Thường phù hợp tập dữ liệu lớn |
| `NESTED LOOPS` | Lặp bảng ngoài và tìm bảng trong | Tốt khi bảng ngoài ít dòng và bảng trong có index |
| `MERGE JOIN` | Sắp xếp rồi ghép hai tập dữ liệu | Có thể phù hợp khi dữ liệu đã được sắp xếp/index |
| `SORT ORDER BY` | Sắp xếp theo `ORDER BY` | Có thể tốn bộ nhớ nếu nhiều dòng |
| `SORT GROUP BY` | Gom nhóm cho `GROUP BY` | Kiểm tra lượng dữ liệu đầu vào |

Ví dụ index phù hợp với query ở trên:

```sql
CREATE INDEX idx_orders_user_status_date
ON orders(user_id, status, order_date);
```

Không kết luận chỉ dựa vào `COST` thấp. Hãy so sánh thêm `A-Rows` (số dòng thực tế), `E-Rows` (số dòng ước tính), `Buffers`, `Reads` và `A-Time`.

### Ví dụ kết quả cần chú ý

Trong output `DBMS_XPLAN`, các cột quan trọng thường có dạng:

```text
Id  Operation                   E-Rows  A-Rows  Buffers  A-Time
--  -------------------------  ------  ------  -------  ------
 1  TABLE ACCESS BY INDEX ROWID      5       5       12  00:00:00.01
 2   INDEX RANGE SCAN                5       5        3  00:00:00.01
```

- `E-Rows`: số dòng Oracle dự đoán.
- `A-Rows`: số dòng thực tế.
- Chênh lệch rất lớn giữa `E-Rows` và `A-Rows` có thể làm Oracle chọn JOIN/index không phù hợp.
- `Buffers` là số logical I/O; thường hữu ích hơn chỉ nhìn thời gian trong một lần chạy.
- `A-Time` là thời gian thực tế của operation.

### Cập nhật statistics khi kế hoạch sai

Statistics cũ có thể khiến optimizer ước lượng sai. Sau khi nạp nhiều dữ liệu, có thể cập nhật statistics:

```sql
BEGIN
  DBMS_STATS.GATHER_TABLE_STATS(
    ownname => USER,
    tabname => 'ORDERS',
    cascade => TRUE
  );
END;
/
```

Không nên tùy tiện ép hint hoặc xóa index chỉ vì một execution plan. Hãy kiểm tra dữ liệu thực tế, bind variable, statistics và chạy thử trên môi trường gần giống production.
