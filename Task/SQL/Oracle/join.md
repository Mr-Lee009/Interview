# Oracle SQL - Các loại JOIN

`JOIN` dùng để kết hợp dữ liệu từ nhiều bảng dựa trên một điều kiện liên quan giữa các cột. Ví dụ dưới đây dùng mô hình đơn giản:

- `USERS`: thông tin người dùng.
- `ORDERS`: đơn hàng của người dùng.
- `ORDER_ITEMS`: các sản phẩm trong đơn hàng.
- `PRODUCTS`: danh sách sản phẩm.

## 1. Dữ liệu mẫu

```sql
CREATE TABLE users (
  user_id   NUMBER PRIMARY KEY,
  username  VARCHAR2(50) NOT NULL
);

CREATE TABLE orders (
  order_id   NUMBER PRIMARY KEY,
  user_id    NUMBER,
  order_date DATE NOT NULL,
  status     VARCHAR2(20) NOT NULL,
  CONSTRAINT fk_orders_user
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE products (
  product_id NUMBER PRIMARY KEY,
  name       VARCHAR2(100) NOT NULL,
  price      NUMBER(12, 2) NOT NULL
);

CREATE TABLE order_items (
  order_id   NUMBER,
  product_id NUMBER,
  quantity   NUMBER(10) NOT NULL,
  CONSTRAINT pk_order_items PRIMARY KEY (order_id, product_id),
  CONSTRAINT fk_items_order
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
  CONSTRAINT fk_items_product
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

INSERT INTO users VALUES (1, 'duc.le');
INSERT INTO users VALUES (2, 'lan.nguyen');
INSERT INTO users VALUES (3, 'minh.tran');

INSERT INTO orders VALUES (101, 1, DATE '2026-08-20', 'PAID');
INSERT INTO orders VALUES (102, 1, DATE '2026-08-21', 'PENDING');
INSERT INTO orders VALUES (103, 2, DATE '2026-08-22', 'PAID');

INSERT INTO products VALUES (10, 'Keyboard', 50.00);
INSERT INTO products VALUES (11, 'Mouse', 20.00);
INSERT INTO products VALUES (12, 'Monitor', 250.00);

INSERT INTO order_items VALUES (101, 10, 1);
INSERT INTO order_items VALUES (101, 11, 2);
INSERT INTO order_items VALUES (102, 12, 1);
INSERT INTO order_items VALUES (103, 11, 1);

COMMIT;
```

Kết quả có chủ ý: user `minh.tran` chưa có đơn hàng, còn sản phẩm `Monitor` có trong đơn hàng đang `PENDING`.

## 2. INNER JOIN

Chỉ lấy những dòng có bản ghi khớp ở **cả hai bảng**. Đây là loại JOIN được dùng phổ biến nhất.

```sql
SELECT u.user_id, u.username, o.order_id, o.status
FROM users u
INNER JOIN orders o ON o.user_id = u.user_id
ORDER BY u.user_id, o.order_id;
```

Kết quả không có `minh.tran` vì user này chưa có đơn hàng.

`INNER` có thể bỏ qua vì `JOIN` mặc định là `INNER JOIN`:

```sql
SELECT u.username, o.order_id
FROM users u
JOIN orders o ON o.user_id = u.user_id;
```

## 3. LEFT OUTER JOIN

Lấy **tất cả dòng của bảng bên trái**, kể cả khi không có dòng tương ứng bên phải. Cột của bảng phải sẽ là `NULL` nếu không khớp.

```sql
SELECT u.user_id, u.username, o.order_id, o.status
FROM users u
LEFT JOIN orders o ON o.user_id = u.user_id
ORDER BY u.user_id, o.order_id;
```

Truy vấn này vẫn trả về `minh.tran`, với `order_id` và `status` bằng `NULL`.

### Tìm user chưa từng đặt hàng

```sql
SELECT u.user_id, u.username
FROM users u
LEFT JOIN orders o ON o.user_id = u.user_id
WHERE o.order_id IS NULL;
```

Điều kiện `o.order_id IS NULL` phải đặt sau JOIN để lọc các dòng không khớp.

## 4. RIGHT OUTER JOIN

Lấy tất cả dòng của bảng bên phải, kể cả khi không có dòng tương ứng bên trái.

```sql
SELECT u.username, o.order_id, o.status
FROM users u
RIGHT JOIN orders o ON o.user_id = u.user_id;
```

Trong thực tế, có thể đổi thứ tự bảng và dùng `LEFT JOIN` để câu SQL dễ đọc hơn:

```sql
SELECT u.username, o.order_id, o.status
FROM orders o
LEFT JOIN users u ON u.user_id = o.user_id;
```

## 5. FULL OUTER JOIN

Lấy tất cả dòng của cả hai bảng. Dòng không khớp ở phía nào thì các cột phía đó là `NULL`.

```sql
SELECT u.user_id, u.username, o.order_id, o.user_id AS order_user_id
FROM users u
FULL OUTER JOIN orders o ON o.user_id = u.user_id
ORDER BY u.user_id, o.order_id;
```

`FULL JOIN` hữu ích khi đối chiếu hai nguồn dữ liệu và muốn nhìn thấy cả bản ghi thiếu ở hai phía.

## 6. JOIN nhiều bảng

Kết hợp đơn hàng, người dùng, sản phẩm và số lượng sản phẩm:

```sql
SELECT
  o.order_id,
  u.username,
  o.order_date,
  p.name AS product_name,
  oi.quantity,
  p.price,
  oi.quantity * p.price AS line_total
FROM orders o
JOIN users u ON u.user_id = o.user_id
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p ON p.product_id = oi.product_id
ORDER BY o.order_id, p.product_id;
```

Tính tổng tiền từng đơn hàng:

```sql
SELECT
  o.order_id,
  u.username,
  SUM(oi.quantity * p.price) AS order_total
FROM orders o
JOIN users u ON u.user_id = o.user_id
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p ON p.product_id = oi.product_id
GROUP BY o.order_id, u.username
ORDER BY o.order_id;
```

## 7. CROSS JOIN

Tạo tích Descartes: mỗi dòng bảng thứ nhất kết hợp với mọi dòng bảng thứ hai. Với 3 user và 3 product sẽ có 9 dòng.

```sql
SELECT u.username, p.name AS product_name
FROM users u
CROSS JOIN products p
ORDER BY u.user_id, p.product_id;
```

Chỉ dùng `CROSS JOIN` khi thực sự cần mọi tổ hợp. Quên điều kiện `ON` trong JOIN thường tạo ra kết quả rất lớn ngoài ý muốn.

## 8. SELF JOIN

Một bảng JOIN với chính nó. Ví dụ mở rộng bảng users để biểu diễn người giới thiệu:

```sql
ALTER TABLE users ADD referred_by NUMBER;

UPDATE users SET referred_by = 1 WHERE user_id = 2;
UPDATE users SET referred_by = 2 WHERE user_id = 3;
COMMIT;

SELECT
  child.username AS user_name,
  parent.username AS referred_by
FROM users child
LEFT JOIN users parent ON parent.user_id = child.referred_by
ORDER BY child.user_id;
```

Phải đặt alias khác nhau (`child`, `parent`) để phân biệt hai vai trò của cùng một bảng.

## 9. JOIN với USING

Khi hai bảng có cột nối cùng tên, có thể dùng `USING`. Cột nối không được ghi kèm alias trong phần `SELECT`.

```sql
SELECT user_id, username, order_id, status
FROM users
JOIN orders USING (user_id)
ORDER BY user_id, order_id;
```

Tương đương với:

```sql
SELECT u.user_id, u.username, o.order_id, o.status
FROM users u
JOIN orders o ON o.user_id = u.user_id;
```

`ON` linh hoạt hơn và thường rõ ràng hơn khi điều kiện nối phức tạp.

## 10. NON-EQUI JOIN

JOIN không dùng dấu `=`. Ví dụ tạo nhóm giá sản phẩm:

```sql
CREATE TABLE price_ranges (
  range_name VARCHAR2(30),
  min_price  NUMBER(12, 2),
  max_price  NUMBER(12, 2)
);

INSERT INTO price_ranges VALUES ('CHEAP', 0, 49.99);
INSERT INTO price_ranges VALUES ('MEDIUM', 50, 199.99);
INSERT INTO price_ranges VALUES ('EXPENSIVE', 200, 999999);
COMMIT;

SELECT p.name, p.price, r.range_name
FROM products p
JOIN price_ranges r
  ON p.price BETWEEN r.min_price AND r.max_price
ORDER BY p.price;
```

Phải bảo đảm các khoảng không chồng lấn, nếu không một sản phẩm có thể khớp nhiều dòng.

## 11. EXISTS và NOT EXISTS

`EXISTS` kiểm tra có ít nhất một dòng liên quan. Nó phù hợp khi chỉ cần biết có tồn tại hay không, không cần lấy cột từ bảng phụ.

### User có ít nhất một đơn hàng

```sql
SELECT u.user_id, u.username
FROM users u
WHERE EXISTS (
  SELECT 1
  FROM orders o
  WHERE o.user_id = u.user_id
);
```

### User không có đơn hàng

```sql
SELECT u.user_id, u.username
FROM users u
WHERE NOT EXISTS (
  SELECT 1
  FROM orders o
  WHERE o.user_id = u.user_id
);
```

So với `NOT IN`, `NOT EXISTS` an toàn hơn khi cột phụ có thể chứa `NULL`.

## 12. Điều kiện trong `ON` và `WHERE`

Với `LEFT JOIN`, vị trí điều kiện tạo ra kết quả khác nhau.

### Giữ user chưa có đơn hàng

```sql
SELECT u.username, o.order_id, o.status
FROM users u
LEFT JOIN orders o
  ON o.user_id = u.user_id
 AND o.status = 'PAID';
```

Điều kiện trạng thái nằm trong `ON`, nên vẫn giữ user không có đơn `PAID`.

### Chỉ lấy user có đơn `PAID`

```sql
SELECT u.username, o.order_id, o.status
FROM users u
LEFT JOIN orders o ON o.user_id = u.user_id
WHERE o.status = 'PAID';
```

Điều kiện trong `WHERE` loại các dòng có `o.status IS NULL`, nên kết quả gần như một `INNER JOIN` cho điều kiện đó.

## 13. Lỗi JOIN thường gặp

### Quên điều kiện nối

```sql
-- Không nên: tạo tích Descartes ngoài ý muốn
SELECT u.username, o.order_id
FROM users u, orders o;
```

Nên dùng cú pháp ANSI JOIN và luôn viết điều kiện `ON` rõ ràng.

### Nối sai cấp độ dữ liệu

`users -> orders` nối bằng `user_id`, còn `orders -> order_items` nối bằng `order_id`. Không dùng nhầm `user_id` để nối trực tiếp với `order_items`.

### Bị nhân bản dòng

Một user có nhiều orders và một order có nhiều items là quan hệ one-to-many. Khi JOIN, số dòng tăng theo số bản ghi khớp. Dùng `DISTINCT`, `GROUP BY` hoặc điều kiện lọc đúng mục đích, không dùng `DISTINCT` để che giấu một điều kiện JOIN sai.

### Lọc `NULL`

```sql
-- Đúng
WHERE o.order_id IS NULL

-- Sai
WHERE o.order_id = NULL
```

Trong SQL, `NULL` biểu thị giá trị không xác định; dùng `IS NULL` hoặc `IS NOT NULL`.

## 14. Tối ưu JOIN

- Tạo khóa chính và khóa ngoại đúng cho các cột liên kết.
- Tạo index cho cột foreign key thường xuyên JOIN hoặc lọc, ví dụ `orders(user_id)`.
- Chỉ lấy cột cần thiết, tránh `SELECT *` trong API.
- Lọc dữ liệu sớm bằng `WHERE`, nhưng kiểm tra kỹ điều kiện với `LEFT JOIN`.
- Dùng `EXPLAIN PLAN` để xem kế hoạch thực thi:

```sql
EXPLAIN PLAN FOR
SELECT u.username, o.order_id
FROM users u
JOIN orders o ON o.user_id = u.user_id
WHERE o.status = 'PAID';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
```

Index mẫu:

```sql
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_orders_status_user ON orders(status, user_id);
```

## 15. Bảng tóm tắt

| Loại JOIN | Kết quả |
|---|---|
| `INNER JOIN` | Chỉ dòng khớp ở cả hai bảng |
| `LEFT JOIN` | Tất cả bảng trái và dòng khớp bảng phải |
| `RIGHT JOIN` | Tất cả bảng phải và dòng khớp bảng trái |
| `FULL OUTER JOIN` | Tất cả dòng của hai bảng |
| `CROSS JOIN` | Mọi tổ hợp giữa hai bảng |
| `SELF JOIN` | Một bảng JOIN với chính nó |
| `NON-EQUI JOIN` | JOIN bằng `BETWEEN`, `<`, `>`, ... thay vì chỉ `=` |
| `EXISTS` | Kiểm tra có dòng liên quan |
| `NOT EXISTS` | Kiểm tra không có dòng liên quan |
