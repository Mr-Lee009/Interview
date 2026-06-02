Chào bạn, Spring Security là một framework cực kỳ mạnh mẽ nhưng cũng nổi tiếng là "phức tạp" vì nó có rất nhiều lớp (layers) đan xen vào nhau. Để dễ hiểu nhất, chúng ta hãy chia nó làm hai mảng chính: **Xác thực (Authentication - "Bạn là ai?")** và **Phân quyền (Authorization - "Bạn được phép làm gì?")**.

Dưới đây là bức tranh toàn cảnh về các thành phần cốt lõi và cách một Request đi qua hệ thống.

---

### Phần 1: Các thành phần quan trọng nhất và Chức năng

#### 1. Lõi lọc (The Filter Layer)

* **`SecurityFilterChain` (Chuỗi bộ lọc bảo mật):** Đây là tuyến phòng thủ đầu tiên. Khi một request đi vào server, nó phải đi qua một chuỗi các bộ lọc này trước khi chạm tới Controller của bạn.
* *Ví dụ:* `UsernamePasswordAuthenticationFilter` (chuyên chặn request đăng nhập), `JwtAuthenticationFilter` (do bạn tự viết để check token), `AuthorizationFilter` (kiểm tra quyền).



#### 2. Nhóm Xác thực (Authentication)

* **`Authentication` (Đối tượng Chứng thực):** Chứa thông tin về người dùng. Khi chưa đăng nhập, nó chứa username/password bạn vừa nhập. Khi đăng nhập thành công, nó chứa chi tiết tài khoản và danh sách các quyền (Roles).
* **`AuthenticationManager` (Người quản lý xác thực):** Giám đốc chịu trách nhiệm xác thực. Tuy nhiên, ông này không trực tiếp làm việc mà giao việc cho cấp dưới.
* **`AuthenticationProvider` (Đơn vị cung cấp xác thực):** Đây là người trực tiếp kiểm tra mật khẩu. Một hệ thống có thể có nhiều Provider (1 cái check DB, 1 cái check LDAP, 1 cái check OAuth2 Google). Phổ biến nhất là `DaoAuthenticationProvider`.
* **`UserDetailsService`:** Một interface chỉ có 1 nhiệm vụ duy nhất: Đi vào Database (hoặc nguồn dữ liệu nào đó) để lôi thông tin của User lên dựa vào username.
* **`PasswordEncoder`:** Công cụ dùng để băm (hash) mật khẩu và so sánh mật khẩu người dùng nhập vào với mật khẩu đã băm trong Database.

#### 3. Nhóm Lưu trữ (Storage)

* **`SecurityContextHolder`:** "Chiếc két sắt" lưu trữ thông tin của người dùng *hiện tại*. Nó sử dụng cơ chế `ThreadLocal`, nghĩa là mỗi Request (mỗi user) sẽ có một két sắt riêng, không ai đụng ai.

---

### Phần 2: Quá trình 1 Request đi qua Spring Security

Hãy tưởng tượng luồng đi của một Request giống như bạn đi qua trạm kiểm soát an ninh tại sân bay. Chúng ta lấy ví dụ phổ biến nhất là **Đăng nhập bằng Username/Password**.

#### Bước 1: Tiếp nhận và Trích xuất (Interception)

1. Client (Trình duyệt/App) gửi một HTTP POST request chứa `{username, password}` đến endpoint `/login`.
2. Request chạm vào **`SecurityFilterChain`**. Bộ lọc `UsernamePasswordAuthenticationFilter` phát hiện đây là luồng đăng nhập, nó tóm lấy request này.
3. Bộ lọc trích xuất `username` và `password`, bọc nó vào một đối tượng gọi là `UsernamePasswordAuthenticationToken` (lúc này cờ *authenticated = false*).

#### Bước 2: Bắt đầu Xác thực (Authentication Process)

4. Bộ lọc ném cái Token ở trên cho **`AuthenticationManager`** và bảo: *"Kiểm tra ông này giúp tôi"*.
5. `AuthenticationManager` tìm kiếm xem có **`AuthenticationProvider`** nào hỗ trợ loại Token này không. Nó giao việc cho `DaoAuthenticationProvider`.
6. `DaoAuthenticationProvider` gọi **`UserDetailsService.loadUserByUsername()`**.
7. Hệ thống chạy query xuống Database, tìm user có username tương ứng và trả về một đối tượng `UserDetails` chứa mật khẩu đã băm (hash) và các quyền (Roles).

#### Bước 3: Đối chiếu Mật khẩu (Password Matching)

8. `DaoAuthenticationProvider` sử dụng **`PasswordEncoder`** để lấy mật khẩu thô người dùng vừa nhập, băm nó ra và so sánh với mật khẩu lấy từ Database.
* *Trường hợp Sai:* Ném ra lỗi `BadCredentialsException`. Bộ lọc ở Bước 1 sẽ bắt lỗi này và trả về Client HTTP 401 (Unauthorized).
* *Trường hợp Đúng:* Chuyển sang Bước 4.



#### Bước 4: Lưu trữ Phiên làm việc (Context Storage)

9. Sau khi mật khẩu đúng, `AuthenticationProvider` tạo ra một đối tượng `Authentication` mới, chứa đầy đủ thông tin (cờ *authenticated = true*, kèm theo danh sách Roles/Quyền hạn).
10. Đối tượng này được lưu vào **`SecurityContextHolder`**. Từ lúc này trở đi, bất cứ hàm nào trong code của bạn cũng có thể biết được "Ai đang đăng nhập" bằng cách gọi `SecurityContextHolder`.

#### Bước 5: Phân quyền (Authorization)

*Giả sử ở một request sau đó, user yêu cầu lấy dữ liệu `GET /api/admin/users`.*
11. Request đi qua chuỗi Filter và chạm đến **`AuthorizationFilter`** (hoặc `FilterSecurityInterceptor`).
12. Filter này sẽ kiểm tra xem API `/api/admin/users` yêu cầu quyền gì (Ví dụ: `hasRole('ADMIN')`).
13. Nó lấy thông tin User từ `SecurityContextHolder` ra xem có Role `ADMIN` hay không.
* *Nếu không có:* Ném ra lỗi `AccessDeniedException` -> Trả về Client HTTP 403 (Forbidden).
* *Nếu có:* Cho phép Request đi xuyên qua Security Layer, chính thức chạm đến `@RestController` của bạn để xử lý logic lấy dữ liệu.

Đó là toàn bộ vòng đời khép kín! Sự phức tạp của Spring Security nằm ở chỗ nó chia nhỏ từng chức năng (Interface) ra để bạn có thể dễ dàng thay thế, tùy biến (Customize) bất kỳ mắt xích nào trong chuỗi 13 bước ở trên (ví dụ như viết custom Filter để dùng JWT thay vì Session mặc định).