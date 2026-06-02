# Case Study: Thiết kế Database cho hệ thống gọi món

Tài liệu này mô phỏng cách một technical leader phân tích và thiết kế database cho hệ thống gọi món. Mục tiêu không chỉ là liệt kê bảng, mà là hiểu phải dựa vào đâu để thiết kế được database đúng, mở rộng được, và dễ cho team triển khai.

## 1. Leader cần dựa vào đâu để thiết kế database?

### 1.1 Business requirement - yêu cầu nghiệp vụ

- Hệ thống phục vụ loại gọi món nào?
  - Gọi món tại bàn trong nhà hàng.
  - Đặt món mang đi.
  - Giao hàng.
  - Food court nhiều quầy.
  - App đặt món nhiều nhà hàng.
- Ai là người dùng?
  - Khách hàng.
  - Nhân viên phục vụ.
  - Bếp.
  - Thu ngân.
  - Quản lý nhà hàng.
  - Shipper nếu có giao hàng.
- Luồng nghiệp vụ chính là gì?
  - Khách xem menu.
  - Khách chọn món.
  - Khách thêm topping/ghi chú.
  - Tạo order.
  - Bếp nhận món.
  - Món được chuẩn bị.
  - Thanh toán.
  - Hoàn tất hoặc hủy order.

### 1.2 Data requirement - dữ liệu cần lưu

- Cần lưu thông tin gì?
  - Nhà hàng/chi nhánh.
  - Bàn ăn.
  - Menu.
  - Món ăn.
  - Topping/option.
  - Order.
  - Order item.
  - Thanh toán.
  - Trạng thái bếp.
  - Khuyến mãi.
  - Lịch sử thay đổi.
- Dữ liệu nào là source of truth?
  - Order và payment thường là dữ liệu chuẩn, không được mất.
  - Menu có thể cache nhưng dữ liệu gốc vẫn cần lưu bền vững.
  - Session/cart tạm có thể lưu Redis, không nhất thiết là source of truth.

### 1.3 Query requirement - hệ thống sẽ truy vấn gì?

- Màn hình khách hàng:
  - Xem menu theo nhà hàng.
  - Tìm món theo category.
  - Xem giá, trạng thái còn/hết món.
- Màn hình bếp:
  - Xem order item đang chờ làm.
  - Lọc theo trạng thái `PENDING`, `COOKING`, `READY`.
- Màn hình thu ngân:
  - Xem order chưa thanh toán.
  - Tính tổng tiền.
  - Ghi nhận payment.
- Màn hình quản lý:
  - Doanh thu theo ngày.
  - Top món bán chạy.
  - Tỷ lệ hủy đơn.

### 1.4 Consistency requirement - yêu cầu nhất quán

- Những dữ liệu cần đúng tuyệt đối:
  - Tổng tiền order.
  - Trạng thái payment.
  - Số lượng order item.
  - Lịch sử thanh toán.
- Những dữ liệu có thể eventual consistency:
  - Báo cáo doanh thu realtime.
  - Top món bán chạy.
  - Cache menu.

### 1.5 Scale requirement - yêu cầu tải

- Một nhà hàng nhỏ:
  - Một database SQL là đủ.
- Chuỗi nhà hàng:
  - Cần `restaurant_id` hoặc `branch_id` trong các bảng chính.
  - Cần index theo chi nhánh và thời gian.
- App nhiều nhà hàng:
  - Cần phân quyền multi-tenant.
  - Cần tính đến sharding/partitioning nếu dữ liệu rất lớn.

## 2. Các bước thiết kế database

### Bước 1: Xác định phạm vi version đầu tiên

- Không thiết kế quá rộng ngay từ đầu.
- Version đầu nên tập trung:
  - Quản lý nhà hàng/chi nhánh.
  - Quản lý bàn.
  - Menu/category/item.
  - Tạo order.
  - Order item.
  - Thanh toán.
  - Trạng thái bếp cơ bản.

### Bước 2: Xác định entity chính

- `restaurants`: nhà hàng hoặc brand.
- `branches`: chi nhánh.
- `tables`: bàn ăn.
- `menu_categories`: nhóm món.
- `menu_items`: món ăn.
- `menu_item_options`: option/topping.
- `orders`: đơn gọi món.
- `order_items`: từng món trong order.
- `order_item_options`: option/topping được chọn cho từng món.
- `payments`: thanh toán.
- `users`: user hệ thống.
- `staff`: nhân viên.
- `order_status_history`: lịch sử đổi trạng thái order.

### Bước 3: Xác định quan hệ

- Một `restaurant` có nhiều `branches`.
- Một `branch` có nhiều `tables`.
- Một `branch` có nhiều `menu_categories`.
- Một `menu_category` có nhiều `menu_items`.
- Một `order` có nhiều `order_items`.
- Một `order_item` có nhiều `order_item_options`.
- Một `order` có thể có nhiều `payments` nếu hỗ trợ trả nhiều lần hoặc retry.
- Một `order` có nhiều dòng lịch sử trạng thái.

### Bước 4: Xác định rule dữ liệu

- `orders.total_amount` không nên tin hoàn toàn từ client.
- Server phải tính lại tổng tiền từ `order_items`.
- Giá tại thời điểm order phải được snapshot vào `order_items.unit_price`.
- Nếu giá món thay đổi sau đó, order cũ vẫn giữ giá cũ.
- Không xóa vật lý order/payment, nên dùng status hoặc soft delete nếu cần.
- Payment thành công thì order mới được xem là đã thanh toán.

### Bước 5: Chọn SQL hay NoSQL

- Với hệ thống gọi món, leader nên chọn `SQL` làm database chính.
- Lý do:
  - Order/payment cần transaction.
  - Dữ liệu có quan hệ rõ: order, item, payment, table, branch.
  - Cần báo cáo doanh thu.
  - Cần constraint để tránh dữ liệu sai.
- Có thể dùng thêm NoSQL/Redis cho phần phụ:
  - Redis cache menu.
  - Redis lưu cart tạm.
  - Elasticsearch search món nếu menu lớn.
  - Kafka/event log cho analytics.

## 3. Thiết kế bảng đề xuất

### 3.1 `restaurants`

```sql
CREATE TABLE restaurants (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

**Vai trò**

- Lưu brand hoặc nhà hàng chính.
- Nếu hệ thống chỉ có một nhà hàng, vẫn nên giữ bảng này để sau dễ mở rộng.

### 3.2 `branches`

```sql
CREATE TABLE branches (
    id BIGSERIAL PRIMARY KEY,
    restaurant_id BIGINT NOT NULL REFERENCES restaurants(id),
    name VARCHAR(255) NOT NULL,
    address TEXT,
    phone VARCHAR(50),
    status VARCHAR(30) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_branches_restaurant_id ON branches(restaurant_id);
```

**Vai trò**

- Lưu từng chi nhánh.
- Hầu hết dữ liệu vận hành nên gắn với `branch_id`.

### 3.3 `tables`

```sql
CREATE TABLE tables (
    id BIGSERIAL PRIMARY KEY,
    branch_id BIGINT NOT NULL REFERENCES branches(id),
    table_code VARCHAR(50) NOT NULL,
    name VARCHAR(100),
    capacity INT,
    status VARCHAR(30) NOT NULL DEFAULT 'AVAILABLE',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (branch_id, table_code)
);

CREATE INDEX idx_tables_branch_id ON tables(branch_id);
```

**Vai trò**

- Lưu bàn ăn trong chi nhánh.
- `table_code` dùng cho QR code hoặc nhận diện bàn.

### 3.4 `menu_categories`

```sql
CREATE TABLE menu_categories (
    id BIGSERIAL PRIMARY KEY,
    branch_id BIGINT NOT NULL REFERENCES branches(id),
    name VARCHAR(255) NOT NULL,
    display_order INT NOT NULL DEFAULT 0,
    status VARCHAR(30) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_menu_categories_branch_id ON menu_categories(branch_id);
```

**Vai trò**

- Nhóm món theo chi nhánh.
- Ví dụ: khai vị, món chính, nước uống, combo.

### 3.5 `menu_items`

```sql
CREATE TABLE menu_items (
    id BIGSERIAL PRIMARY KEY,
    branch_id BIGINT NOT NULL REFERENCES branches(id),
    category_id BIGINT NOT NULL REFERENCES menu_categories(id),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(12, 2) NOT NULL,
    image_url TEXT,
    is_available BOOLEAN NOT NULL DEFAULT TRUE,
    display_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_menu_items_branch_category ON menu_items(branch_id, category_id);
CREATE INDEX idx_menu_items_available ON menu_items(branch_id, is_available);
```

**Vai trò**

- Lưu món ăn hiện có.
- `price` là giá hiện tại, không phải giá lịch sử trong order.

### 3.6 `menu_item_options`

```sql
CREATE TABLE menu_item_options (
    id BIGSERIAL PRIMARY KEY,
    menu_item_id BIGINT NOT NULL REFERENCES menu_items(id),
    name VARCHAR(255) NOT NULL,
    extra_price DECIMAL(12, 2) NOT NULL DEFAULT 0,
    is_required BOOLEAN NOT NULL DEFAULT FALSE,
    max_select INT,
    status VARCHAR(30) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_menu_item_options_item_id ON menu_item_options(menu_item_id);
```

**Vai trò**

- Lưu topping/option.
- Ví dụ:
  - Thêm phô mai.
  - Ít cay.
  - Size M/L.
  - Thêm trứng.

### 3.7 `orders`

```sql
CREATE TABLE orders (
    id BIGSERIAL PRIMARY KEY,
    branch_id BIGINT NOT NULL REFERENCES branches(id),
    table_id BIGINT REFERENCES tables(id),
    order_code VARCHAR(50) NOT NULL,
    order_type VARCHAR(30) NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'CREATED',
    subtotal_amount DECIMAL(12, 2) NOT NULL DEFAULT 0,
    discount_amount DECIMAL(12, 2) NOT NULL DEFAULT 0,
    service_fee DECIMAL(12, 2) NOT NULL DEFAULT 0,
    tax_amount DECIMAL(12, 2) NOT NULL DEFAULT 0,
    total_amount DECIMAL(12, 2) NOT NULL DEFAULT 0,
    note TEXT,
    created_by BIGINT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (branch_id, order_code)
);

CREATE INDEX idx_orders_branch_status ON orders(branch_id, status);
CREATE INDEX idx_orders_branch_created_at ON orders(branch_id, created_at);
CREATE INDEX idx_orders_table_status ON orders(table_id, status);
```

**Vai trò**

- Lưu header của order.
- `order_type` có thể là:
  - `DINE_IN`: ăn tại bàn.
  - `TAKE_AWAY`: mang đi.
  - `DELIVERY`: giao hàng.
- `status` có thể là:
  - `CREATED`
  - `CONFIRMED`
  - `PREPARING`
  - `READY`
  - `SERVED`
  - `PAID`
  - `CANCELLED`

### 3.8 `order_items`

```sql
CREATE TABLE order_items (
    id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES orders(id),
    menu_item_id BIGINT REFERENCES menu_items(id),
    item_name VARCHAR(255) NOT NULL,
    unit_price DECIMAL(12, 2) NOT NULL,
    quantity INT NOT NULL,
    total_price DECIMAL(12, 2) NOT NULL,
    kitchen_status VARCHAR(30) NOT NULL DEFAULT 'PENDING',
    note TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_kitchen_status ON order_items(kitchen_status);
```

**Vai trò**

- Lưu từng món trong order.
- `item_name` và `unit_price` là snapshot tại thời điểm đặt món.
- Nếu món bị đổi tên hoặc đổi giá sau đó, order cũ vẫn đúng.

### 3.9 `order_item_options`

```sql
CREATE TABLE order_item_options (
    id BIGSERIAL PRIMARY KEY,
    order_item_id BIGINT NOT NULL REFERENCES order_items(id),
    option_name VARCHAR(255) NOT NULL,
    extra_price DECIMAL(12, 2) NOT NULL DEFAULT 0,
    quantity INT NOT NULL DEFAULT 1,
    total_price DECIMAL(12, 2) NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_order_item_options_item_id ON order_item_options(order_item_id);
```

**Vai trò**

- Lưu option/topping thực tế khách đã chọn.
- Cũng cần snapshot tên và giá để order cũ không bị ảnh hưởng khi menu thay đổi.

### 3.10 `payments`

```sql
CREATE TABLE payments (
    id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES orders(id),
    payment_method VARCHAR(30) NOT NULL,
    amount DECIMAL(12, 2) NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'PENDING',
    transaction_ref VARCHAR(255),
    paid_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_payments_order_id ON payments(order_id);
CREATE INDEX idx_payments_status ON payments(status);
CREATE UNIQUE INDEX idx_payments_transaction_ref
ON payments(transaction_ref)
WHERE transaction_ref IS NOT NULL;
```

**Vai trò**

- Lưu thanh toán.
- `payment_method`:
  - `CASH`
  - `CARD`
  - `MOMO`
  - `BANK_TRANSFER`
  - `VNPAY`
- `status`:
  - `PENDING`
  - `SUCCESS`
  - `FAILED`
  - `REFUNDED`

### 3.11 `order_status_history`

```sql
CREATE TABLE order_status_history (
    id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES orders(id),
    old_status VARCHAR(30),
    new_status VARCHAR(30) NOT NULL,
    changed_by BIGINT,
    reason TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_order_status_history_order_id ON order_status_history(order_id);
```

**Vai trò**

- Lưu lịch sử đổi trạng thái.
- Hữu ích để audit, debug, xử lý khiếu nại.

## 4. Luồng tạo order chuẩn

### Step 1: Client gửi request tạo order

- Request gồm:
  - `branch_id`
  - `table_id`
  - danh sách món
  - topping/option
  - ghi chú

### Step 2: Server validate dữ liệu

- Kiểm tra chi nhánh có tồn tại không.
- Kiểm tra bàn có thuộc chi nhánh không.
- Kiểm tra món còn bán không.
- Kiểm tra option có thuộc món không.
- Không tin giá client gửi lên.

### Step 3: Server tính tiền

- Lấy giá món từ `menu_items`.
- Lấy giá option từ `menu_item_options`.
- Tính:
  - `subtotal_amount`
  - `discount_amount`
  - `service_fee`
  - `tax_amount`
  - `total_amount`

### Step 4: Ghi database trong transaction

- Tạo record `orders`.
- Tạo các record `order_items`.
- Tạo các record `order_item_options`.
- Tạo dòng đầu tiên trong `order_status_history`.
- Commit transaction.

### Step 5: Gửi event cho bếp

- Sau khi commit thành công:
  - Publish event `OrderCreated`.
  - Bếp nhận order mới.
  - Cache/report/search xử lý async nếu cần.

## 5. Transaction mẫu khi tạo order

```sql
BEGIN;

INSERT INTO orders (
    branch_id,
    table_id,
    order_code,
    order_type,
    status,
    subtotal_amount,
    total_amount,
    note
) VALUES (
    1,
    10,
    'ORD-20260602-0001',
    'DINE_IN',
    'CREATED',
    250000,
    250000,
    'Ít cay'
) RETURNING id;

INSERT INTO order_items (
    order_id,
    menu_item_id,
    item_name,
    unit_price,
    quantity,
    total_price,
    kitchen_status
) VALUES (
    100,
    5,
    'Mì bò cay',
    120000,
    2,
    240000,
    'PENDING'
);

INSERT INTO order_item_options (
    order_item_id,
    option_name,
    extra_price,
    quantity,
    total_price
) VALUES (
    200,
    'Thêm trứng',
    10000,
    1,
    10000
);

INSERT INTO order_status_history (
    order_id,
    old_status,
    new_status,
    reason
) VALUES (
    100,
    NULL,
    'CREATED',
    'Order created by customer'
);

COMMIT;
```

Ghi chú leader:

- Đây là ví dụ minh họa, id `100`, `200` thực tế phải lấy từ `RETURNING id`.
- Không hardcode giá từ client.
- Nếu insert bất kỳ phần nào fail, phải rollback toàn bộ.

## 6. Index cần có và lý do

| Bảng | Index | Lý do |
|---|---|---|
| `branches` | `restaurant_id` | Lấy danh sách chi nhánh theo nhà hàng |
| `tables` | `(branch_id, table_code)` | Tìm bàn theo chi nhánh và mã bàn |
| `menu_categories` | `branch_id` | Load menu theo chi nhánh |
| `menu_items` | `(branch_id, category_id)` | Load món theo category |
| `menu_items` | `(branch_id, is_available)` | Lọc món đang bán |
| `orders` | `(branch_id, status)` | Thu ngân/bếp lọc order theo trạng thái |
| `orders` | `(branch_id, created_at)` | Báo cáo order theo ngày |
| `order_items` | `order_id` | Load chi tiết order |
| `order_items` | `kitchen_status` | Màn hình bếp lọc món cần làm |
| `payments` | `order_id` | Xem payment của order |
| `payments` | `transaction_ref` unique | Tránh ghi trùng giao dịch thanh toán |

## 7. Các quyết định thiết kế quan trọng

### 7.1 Vì sao `order_items` cần lưu `item_name` và `unit_price`?

- Vì menu có thể thay đổi sau khi khách đặt.
- Nếu chỉ lưu `menu_item_id`, khi giá món đổi thì order cũ có thể hiển thị sai.
- Snapshot tên và giá giúp order cũ luôn đúng.

### 7.2 Vì sao không xóa order?

- Order liên quan đến doanh thu, payment, audit.
- Xóa vật lý làm mất lịch sử.
- Nên dùng status:
  - `CANCELLED`
  - `REFUNDED`
  - `VOID`

### 7.3 Vì sao payment nên là bảng riêng?

- Một order có thể thanh toán thất bại nhiều lần.
- Có thể hỗ trợ nhiều phương thức thanh toán.
- Có thể cần refund.
- Cần lưu `transaction_ref` từ cổng thanh toán.

### 7.4 Vì sao cần `order_status_history`?

- Debug khi order bị sai trạng thái.
- Audit thao tác nhân viên.
- Giải quyết khiếu nại.
- Phân tích thời gian xử lý order.

## 8. Khi nào cần thêm Redis/NoSQL?

### Redis

- Dùng cho:
  - Cache menu.
  - Session.
  - Rate limit.
  - Lock ngắn hạn khi thanh toán hoặc cập nhật trạng thái.
- Không dùng Redis làm source of truth cho order/payment.

### Elasticsearch

- Dùng khi:
  - Menu rất lớn.
  - Cần search theo keyword.
  - Cần autocomplete.
  - Cần filter phức tạp.

### Kafka hoặc message queue

- Dùng khi:
  - Gửi order sang bếp async.
  - Đồng bộ report.
  - Gửi notification.
  - Tracking event.

## 9. Checklist review database design với team

- Entity chính đã đủ chưa?
- Có bảng nào đang chứa quá nhiều trách nhiệm không?
- Có dữ liệu nào cần snapshot không?
- Có transaction nào cần đảm bảo atomic không?
- Có query quan trọng nào chưa có index không?
- Có trường nào không nên cho phép null không?
- Có unique constraint nào cần thêm không?
- Có audit/history cho dữ liệu quan trọng không?
- Có tách được dữ liệu source of truth và cache không?
- Có kế hoạch migration khi schema thay đổi không?

## 10. Sai lầm thường gặp

- Tin giá tiền client gửi lên.
- Không snapshot giá món trong order item.
- Chỉ có một bảng `orders` chứa cả order detail, payment, trạng thái bếp.
- Không có transaction khi tạo order.
- Không có lịch sử trạng thái.
- Xóa vật lý order/payment.
- Không có index cho màn hình bếp hoặc thu ngân.
- Dùng Redis làm database chính cho order.
- Thiết kế quá nhiều bảng phức tạp ngay từ version đầu.

## 11. Cách trình bày khi phỏng vấn

- "Đầu tiên em sẽ hỏi requirement: hệ thống gọi món tại bàn, takeaway hay delivery, có nhiều chi nhánh không, có thanh toán online không."
- "Sau đó em xác định entity chính: branch, table, menu category, menu item, order, order item, payment."
- "Em chọn SQL làm database chính vì order/payment cần transaction, dữ liệu có quan hệ rõ và cần báo cáo."
- "Với order item, em sẽ snapshot tên món và giá tại thời điểm đặt để tránh menu thay đổi làm sai order cũ."
- "Em sẽ tạo index theo query thực tế: order theo branch/status cho bếp và thu ngân, order theo branch/created_at cho báo cáo."
- "Redis chỉ dùng cho cache/session/lock ngắn hạn, không làm source of truth cho order/payment."

## 12. Mô hình tối thiểu cho version 1

Nếu cần làm nhanh MVP, có thể bắt đầu với:

- `branches`
- `tables`
- `menu_categories`
- `menu_items`
- `orders`
- `order_items`
- `order_item_options`
- `payments`
- `order_status_history`

Sau đó mới mở rộng:

- promotion.
- coupon.
- customer.
- loyalty point.
- delivery.
- refund.
- kitchen station.
- inventory.
