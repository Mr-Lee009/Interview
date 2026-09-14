# Oracle PL/SQL - Procedure và Function

`Procedure` và `Function` là các **stored program unit** viết bằng PL/SQL và lưu trong schema Oracle. Chúng phù hợp để gom logic gần dữ liệu, tái sử dụng và kiểm soát quyền thực thi.

- **Procedure**: thực hiện một hành động; không bắt buộc trả về giá trị.
- **Function**: bắt buộc `RETURN` một giá trị; có thể được gọi trong biểu thức PL/SQL, và trong SQL nếu tuân thủ các giới hạn của SQL.

Các ví dụ dùng bảng `APP_USER.USERS` trong [doc.md](doc.md). Hãy kết nối bằng `APP_USER` trước khi chạy để không phải ghi tiền tố schema.

## 1. Khối PL/SQL cơ bản

PL/SQL có phần khai báo (`DECLARE`, tùy chọn), phần thực thi (`BEGIN ... END`) và phần bắt lỗi (`EXCEPTION`, tùy chọn). Dấu `/` ở dòng riêng là lệnh của SQL*Plus/SQLcl/SQL Developer để gửi cả block đến Oracle; nó không phải một phần của PL/SQL.

```sql
SET SERVEROUTPUT ON;

DECLARE
  v_total NUMBER;
BEGIN
  SELECT COUNT(*)
  INTO v_total
  FROM users
  WHERE status = 'ACTIVE';

  DBMS_OUTPUT.PUT_LINE('So user ACTIVE: ' || v_total);
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Loi: ' || SQLERRM);
    RAISE;
END;
/
```

`SELECT ... INTO` phải trả về đúng một dòng: không có dòng sẽ gây `NO_DATA_FOUND`, nhiều hơn một dòng sẽ gây `TOO_MANY_ROWS`. Dùng aggregate như `COUNT(*)` khi cần bảo đảm một dòng.

## 2. Procedure đầu tiên

Ví dụ dưới đây khóa một user theo username. Tham số `p_` là quy ước đặt tên để phân biệt parameter với cột/biến cục bộ.

```sql
CREATE OR REPLACE PROCEDURE lock_user (
  p_username IN users.username%TYPE
) AS
BEGIN
  UPDATE users
  SET status = 'LOCKED',
      updated_at = SYSTIMESTAMP
  WHERE username = p_username
    AND status <> 'LOCKED';

  IF SQL%ROWCOUNT = 0 THEN
    RAISE_APPLICATION_ERROR(-20001, 'Khong tim thay user, hoac user da bi khoa');
  END IF;
END lock_user;
/
```

Gọi procedure trong một anonymous block:

```sql
BEGIN
  lock_user(p_username => 'duc.le');
  COMMIT;
END;
/
```

`SQL%ROWCOUNT` là implicit cursor attribute, cho biết số dòng bị tác động bởi câu SQL gần nhất. Dùng named notation (`p_username => ...`) giúp lời gọi dễ đọc và an toàn hơn khi procedure có nhiều tham số.

> Procedure phía dưới **không** gọi `COMMIT` hoặc `ROLLBACK`. Transaction nên do tầng gọi quyết định: một API/service có thể cần gộp nhiều procedure thành một transaction nguyên tử.

## 3. Tham số `IN`, `OUT` và `IN OUT`

| Mode | Đọc trong procedure | Gán giá trị | Mục đích |
|---|---:|---:|---|
| `IN` | Có | Không | Nhận dữ liệu đầu vào; là mặc định |
| `OUT` | Sau khi gán | Có | Trả dữ liệu cho caller |
| `IN OUT` | Có | Có | Nhận vào rồi cập nhật giá trị |

```sql
CREATE OR REPLACE PROCEDURE get_user_summary (
  p_user_id  IN  users.user_id%TYPE,
  p_username OUT users.username%TYPE,
  p_status   OUT users.status%TYPE
) AS
BEGIN
  SELECT username, status
  INTO p_username, p_status
  FROM users
  WHERE user_id = p_user_id;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20002, 'User khong ton tai: ' || p_user_id);
END get_user_summary;
/

DECLARE
  v_username users.username%TYPE;
  v_status   users.status%TYPE;
BEGIN
  get_user_summary(1, v_username, v_status);
  DBMS_OUTPUT.PUT_LINE(v_username || ' - ' || v_status);
END;
/
```

`%TYPE` lấy kiểu dữ liệu từ cột, nên procedure ít bị lệch kiểu khi DDL thay đổi. Với record của cả dòng, dùng `%ROWTYPE`.

## 4. Function: trả về một giá trị

Function luôn khai báo kiểu trả về và phải có `RETURN` trên mọi nhánh thực thi.

```sql
CREATE OR REPLACE FUNCTION user_display_name (
  p_user_id IN users.user_id%TYPE
) RETURN VARCHAR2 AS
  v_name users.full_name%TYPE;
BEGIN
  SELECT NVL(full_name, username)
  INTO v_name
  FROM users
  WHERE user_id = p_user_id;

  RETURN v_name;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN NULL;
END user_display_name;
/

SELECT user_id, user_display_name(user_id) AS display_name
FROM users
ORDER BY user_id;
```

Function gọi từ SQL nên có tính toán nhỏ, rõ ràng và không tạo side effect. Không gọi `COMMIT`, `ROLLBACK`, DDL, hoặc ghi dữ liệu trong function được dùng bởi `SELECT`; các thao tác đó có thể bị Oracle từ chối hoặc tạo hành vi khó dự đoán. Nếu function cần truy vấn bảng, hãy cân nhắc chi phí vì Oracle có thể gọi nó cho từng dòng.

Ví dụ function thuần tính toán, an toàn để dùng trong SQL:

```sql
CREATE OR REPLACE FUNCTION calculate_discount (
  p_total IN NUMBER
) RETURN NUMBER DETERMINISTIC AS
BEGIN
  RETURN CASE
           WHEN p_total >= 1000 THEN p_total * 0.10
           WHEN p_total >= 500  THEN p_total * 0.05
           ELSE 0
         END;
END calculate_discount;
/

SELECT 750 AS total, calculate_discount(750) AS discount
FROM dual;
```

Chỉ khai báo `DETERMINISTIC` khi cùng input **luôn** cho cùng output và function không phụ thuộc thời gian, session hay bảng có thể đổi. Từ khóa này là cam kết với optimizer, không tự làm function được kiểm tra đúng.

## 5. Procedure với validation và lỗi nghiệp vụ

Mã lỗi tự định nghĩa nên nằm trong khoảng `-20000` đến `-20999`. Caller (Java/JDBC chẳng hạn) có thể đọc mã `ORA-200xx` để ánh xạ lỗi nghiệp vụ.

```sql
CREATE OR REPLACE PROCEDURE change_user_status (
  p_user_id    IN users.user_id%TYPE,
  p_new_status IN users.status%TYPE
) AS
  v_exists NUMBER;
BEGIN
  IF p_new_status NOT IN ('ACTIVE', 'LOCKED', 'INACTIVE') THEN
    RAISE_APPLICATION_ERROR(-20010, 'Trang thai khong hop le: ' || p_new_status);
  END IF;

  SELECT COUNT(*) INTO v_exists
  FROM users
  WHERE user_id = p_user_id;

  IF v_exists = 0 THEN
    RAISE_APPLICATION_ERROR(-20011, 'Khong tim thay user: ' || p_user_id);
  END IF;

  UPDATE users
  SET status = p_new_status,
      updated_at = SYSTIMESTAMP
  WHERE user_id = p_user_id;
END change_user_status;
/
```

Với thao tác cập nhật đơn giản, cũng có thể bỏ `COUNT(*)`, chạy `UPDATE` trước rồi kiểm tra `SQL%ROWCOUNT`; cách này thường tránh thêm một lần đọc bảng.

## 6. Xử lý exception đúng cách

Các exception thường gặp:

| Exception | Khi nào xảy ra |
|---|---|
| `NO_DATA_FOUND` | `SELECT INTO` không trả dòng nào |
| `TOO_MANY_ROWS` | `SELECT INTO` trả từ hai dòng trở lên |
| `DUP_VAL_ON_INDEX` | Vi phạm unique/primary key |
| `VALUE_ERROR` | Lỗi chuyển đổi hoặc gán giá trị |
| `OTHERS` | Các lỗi chưa được bắt riêng |

```sql
CREATE OR REPLACE PROCEDURE create_simple_user (
  p_username IN users.username%TYPE,
  p_email    IN users.email%TYPE,
  p_hash     IN users.password_hash%TYPE
) AS
BEGIN
  INSERT INTO users (username, email, password_hash)
  VALUES (p_username, p_email, p_hash);
EXCEPTION
  WHEN DUP_VAL_ON_INDEX THEN
    RAISE_APPLICATION_ERROR(-20020, 'Username hoac email da ton tai');
  WHEN OTHERS THEN
    -- Luu log neu he thong co bang/package logging; sau do luon nem lai loi.
    RAISE;
END create_simple_user;
/
```

Không dùng `WHEN OTHERS THEN NULL`; nó nuốt lỗi, khiến caller tưởng thao tác thành công. Nếu bắt `OTHERS` để thêm log/ngữ cảnh, hãy `RAISE;` để giữ nguyên lỗi và stack ban đầu.

## 7. Trả nhiều dòng bằng `SYS_REFCURSOR`

Procedure không trả table trực tiếp như một function SQL, nhưng có thể mở `SYS_REFCURSOR` cho caller.

```sql
CREATE OR REPLACE PROCEDURE find_users_by_status (
  p_status IN  users.status%TYPE,
  p_result OUT SYS_REFCURSOR
) AS
BEGIN
  OPEN p_result FOR
    SELECT user_id, username, full_name, email, status, created_at
    FROM users
    WHERE status = p_status
    ORDER BY created_at DESC, user_id DESC;
END find_users_by_status;
/
```

Trong SQL Developer có thể kiểm tra nhanh:

```sql
VAR result REFCURSOR;
EXEC find_users_by_status('ACTIVE', :result);
PRINT result;
```

Với JDBC, đăng ký tham số `OUT` kiểu `OracleTypes.CURSOR` (hoặc kiểu cursor tương ứng của driver), gọi `CallableStatement`, rồi đọc `ResultSet` trả về. Cursor chỉ còn hợp lệ trong lúc connection/session còn mở.

## 8. Cursor và xử lý theo tập dữ liệu

Ưu tiên một câu SQL theo tập dữ liệu (`UPDATE ... WHERE ...`) thay vì loop từng dòng. Chỉ dùng cursor khi logic thật sự cần xử lý từng bản ghi.

```sql
CREATE OR REPLACE PROCEDURE deactivate_inactive_users (
  p_before IN TIMESTAMP
) AS
BEGIN
  FOR r IN (
    SELECT user_id
    FROM users
    WHERE status = 'ACTIVE'
      AND last_login_at < p_before
  ) LOOP
    UPDATE users
    SET status = 'INACTIVE',
        updated_at = SYSTIMESTAMP
    WHERE user_id = r.user_id;
  END LOOP;
END deactivate_inactive_users;
/
```

Ví dụ trên nhằm minh họa cursor `FOR LOOP`; phiên bản set-based hiệu quả hơn là:

```sql
UPDATE users
SET status = 'INACTIVE',
    updated_at = SYSTIMESTAMP
WHERE status = 'ACTIVE'
  AND last_login_at < :p_before;
```

Khi bắt buộc xử lý số lượng lớn theo mảng, tìm hiểu `BULK COLLECT` và `FORALL`; tránh `COMMIT` trong từng vòng lặp vì làm chậm và phá vỡ tính nguyên tử.

## 9. Package: đóng gói API PL/SQL

Package tách **specification** (public API) và **body** (cài đặt). Đây là cách tốt để nhóm các procedure/function cùng nghiệp vụ, ẩn helper nội bộ và giúp application chỉ phụ thuộc interface ổn định.

```sql
CREATE OR REPLACE PACKAGE user_api AS
  PROCEDURE lock_user(p_username IN users.username%TYPE);

  FUNCTION display_name(p_user_id IN users.user_id%TYPE)
    RETURN VARCHAR2;
END user_api;
/

CREATE OR REPLACE PACKAGE BODY user_api AS
  PROCEDURE lock_user(p_username IN users.username%TYPE) AS
  BEGIN
    UPDATE users
    SET status = 'LOCKED', updated_at = SYSTIMESTAMP
    WHERE username = p_username AND status <> 'LOCKED';

    IF SQL%ROWCOUNT = 0 THEN
      RAISE_APPLICATION_ERROR(-20001, 'Khong tim thay user, hoac user da bi khoa');
    END IF;
  END lock_user;

  FUNCTION display_name(p_user_id IN users.user_id%TYPE)
    RETURN VARCHAR2 AS
    v_name users.full_name%TYPE;
  BEGIN
    SELECT NVL(full_name, username)
    INTO v_name
    FROM users
    WHERE user_id = p_user_id;
    RETURN v_name;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN RETURN NULL;
  END display_name;
END user_api;
/
```

Gọi object trong package bằng `user_api.lock_user(...)` và `user_api.display_name(...)`. Không tạo standalone procedure/function trùng tên với API package nếu không cần, để tránh nhầm lẫn.

## 10. Quyền và `AUTHID`

Object mới được tạo thuộc schema hiện tại. Cấp đúng quyền chạy cho schema khác:

```sql
GRANT EXECUTE ON app_user.user_api TO report_user;
```

Mặc định stored program chạy theo quyền của owner (**definer rights**). Nếu cần procedure chạy theo quyền của người gọi, khai báo `AUTHID CURRENT_USER`:

```sql
CREATE OR REPLACE PROCEDURE current_user_name
  AUTHID CURRENT_USER
AS
BEGIN
  DBMS_OUTPUT.PUT_LINE(USER);
END;
/
```

Hãy dùng `AUTHID CURRENT_USER` có chủ đích vì nó thay đổi mô hình quyền. Với definer rights, quyền truy cập object trong code cần được cấp **trực tiếp** cho owner (không chỉ thông qua role).

## 11. Dynamic SQL: chỉ dùng khi cần thiết

Dynamic SQL dùng `EXECUTE IMMEDIATE` khi tên bảng/cột hoặc cấu trúc câu lệnh chỉ biết lúc chạy. Giá trị dữ liệu phải luôn dùng bind variable.

```sql
CREATE OR REPLACE PROCEDURE count_by_status (
  p_status IN  users.status%TYPE,
  p_total  OUT NUMBER
) AS
BEGIN
  EXECUTE IMMEDIATE
    'SELECT COUNT(*) FROM users WHERE status = :status'
    INTO p_total
    USING p_status;
END;
/
```

Không nối trực tiếp input người dùng vào SQL. Khi buộc phải dynamic tên object, validate bằng allow-list hoặc `DBMS_ASSERT`; bind variable không thể thay thế tên bảng/cột.

## 12. Kiểm tra, biên dịch và xóa object

```sql
-- Xem source và trạng thái object trong schema hiện tại
SELECT object_name, object_type, status
FROM user_objects
WHERE object_name IN ('LOCK_USER', 'USER_DISPLAY_NAME', 'USER_API')
ORDER BY object_type, object_name;

SELECT line, text
FROM user_source
WHERE name = 'LOCK_USER'
  AND type = 'PROCEDURE'
ORDER BY line;

-- Xem lỗi compile, nếu object INVALID
SELECT line, position, text
FROM user_errors
WHERE name = 'LOCK_USER'
ORDER BY sequence;

ALTER PROCEDURE lock_user COMPILE;
ALTER FUNCTION user_display_name COMPILE;

-- Cẩn thận: xóa object, các caller phụ thuộc sẽ lỗi khi chạy.
DROP PROCEDURE lock_user;
DROP FUNCTION user_display_name;
DROP PACKAGE user_api;
```

## 13. Checklist khi viết cho production

- Chọn procedure cho command/thay đổi dữ liệu; chọn function cho phép tính hoặc tra cứu có giá trị trả về rõ ràng.
- Khai báo parameter bằng `%TYPE`, record bằng `%ROWTYPE`; đặt tên `p_`, `v_`, `c_` nhất quán.
- Không `COMMIT`/`ROLLBACK` trong procedure dùng chung, trừ khi đó thực sự là ranh giới transaction đã được thiết kế.
- Bắt exception cụ thể trước; nếu bắt `OTHERS`, log có kiểm soát rồi `RAISE` lại.
- Dùng bind variable; không nối input vào dynamic SQL.
- Tối ưu theo tập dữ liệu trước cursor/loop; đo execution plan trước khi tối ưu phỏng đoán.
- Cấp `EXECUTE` tối thiểu cần thiết; tránh cấp quyền rộng như `DBA` cho application schema.
- Viết test cho dữ liệu hợp lệ, không tồn tại, trùng unique key, `NULL`, boundary và rollback.

## 14. Tóm tắt nhanh

| Nhu cầu | Nên dùng |
|---|---|
| Khóa user, tạo đơn, cập nhật trạng thái | Procedure |
| Tính discount, chuẩn hóa chuỗi, trả một giá trị | Function |
| Trả danh sách cho application | Procedure với `SYS_REFCURSOR` |
| Gom nhóm API cùng nghiệp vụ | Package |
| Báo lỗi nghiệp vụ | `RAISE_APPLICATION_ERROR(-20000 .. -20999, ...)` |
| Thao tác dữ liệu theo nhiều câu lệnh | Caller quản lý `COMMIT`/`ROLLBACK` |
