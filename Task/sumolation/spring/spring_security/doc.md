# Spring Security

`Spring Security` là framework của Spring dùng để xử lý:

- `Authentication`: bạn là ai
- `Authorization`: bạn được phép làm gì
- Bảo vệ ứng dụng khỏi các rủi ro phổ biến như:
  - truy cập trái phép
  - session fixation
  - CSRF
  - một phần các vấn đề liên quan đến security headers

Tài liệu này tập trung vào 2 phần:

1. Các thành phần chính của Spring Security
2. Các class quan trọng và chức năng của từng class

## 1. Luồng tổng quát

Khi request đi vào ứng dụng Spring Boot:

1. Request đi qua `SecurityFilterChain`
2. Filter phù hợp trích xuất thông tin xác thực
3. `AuthenticationManager` nhận request xác thực
4. `AuthenticationProvider` kiểm tra thông tin đăng nhập
5. `UserDetailsService` tải thông tin user
6. Nếu hợp lệ, tạo `Authentication` đã xác thực
7. Thông tin được lưu vào `SecurityContextHolder`
8. Hệ thống tiếp tục kiểm tra quyền truy cập
9. Nếu đủ quyền thì request mới được vào `Controller`

## 2. Các thành phần chính của Spring Security

## 2.1 SecurityFilterChain

Đây là thành phần trung tâm ở tầng web security.  
Nó là chuỗi các filter bảo mật chạy trước khi request vào controller.

Vai trò:

1. Chặn mọi HTTP request đi vào ứng dụng
2. Xác định filter nào cần chạy
3. Thực hiện authentication và authorization
4. Trả về `401`, `403` hoặc cho phép đi tiếp

Ví dụ các filter thường gặp:

1. `UsernamePasswordAuthenticationFilter`
2. `BasicAuthenticationFilter`
3. `BearerTokenAuthenticationFilter`
4. `ExceptionTranslationFilter`
5. `AuthorizationFilter`

## 2.2 Authentication

`Authentication` là object đại diện cho thông tin xác thực của user.

Nó thường chứa:

1. `principal`: user đang đăng nhập
2. `credentials`: mật khẩu hoặc token
3. `authorities`: danh sách quyền/role
4. `authenticated`: đã xác thực hay chưa

Lúc đầu object có thể là chưa xác thực.  
Sau khi xác thực thành công, Spring Security tạo ra object `Authentication` đã xác thực.

## 2.3 AuthenticationManager

`AuthenticationManager` là nơi nhận yêu cầu xác thực.

Vai trò:

1. Nhận `Authentication` từ filter
2. Chuyển tiếp việc xác thực cho `AuthenticationProvider`
3. Trả về `Authentication` đã xác thực nếu thành công
4. Ném exception nếu thất bại

Implementation phổ biến nhất là `ProviderManager`.

## 2.4 AuthenticationProvider

`AuthenticationProvider` là nơi chứa logic xác thực cụ thể.

Ví dụ:

1. Kiểm tra username/password
2. Kiểm tra JWT
3. Kiểm tra OTP
4. Kiểm tra LDAP

Một ứng dụng có thể có nhiều provider khác nhau.

## 2.5 UserDetailsService

`UserDetailsService` chịu trách nhiệm tải user từ nguồn dữ liệu.

Nguồn dữ liệu có thể là:

1. Database
2. In-memory
3. LDAP
4. Dịch vụ ngoài

Nó thường được dùng trong authentication theo username/password.

## 2.6 UserDetails

`UserDetails` là object mô tả thông tin người dùng theo chuẩn Spring Security.

Nó thường chứa:

1. username
2. password
3. authorities
4. account non expired
5. account non locked
6. credentials non expired
7. enabled

## 2.7 SecurityContextHolder

`SecurityContextHolder` là nơi Spring Security lưu thông tin bảo mật của request hiện tại.

Thông thường nó lưu:

1. `SecurityContext`
2. Trong `SecurityContext` có `Authentication`

Trong ứng dụng web truyền thống, nó thường dùng `ThreadLocal`.

## 2.8 Authorization

Sau khi xác thực xong, Spring Security kiểm tra phân quyền.

Việc này có thể diễn ra ở:

1. URL level
2. Method level

Ví dụ:

1. `requestMatchers("/admin/**").hasRole("ADMIN")`
2. `@PreAuthorize("hasRole('ADMIN')")`

## 2.9 PasswordEncoder

`PasswordEncoder` dùng để mã hóa và so sánh mật khẩu.

Không nên lưu plaintext password.  
Implementation phổ biến nhất là:

1. `BCryptPasswordEncoder`

## 2.10 Session hoặc Token

Spring Security có thể hoạt động theo:

1. `Session-based authentication`
2. `Token-based authentication` như JWT

Nếu là session:

- server lưu trạng thái đăng nhập

Nếu là JWT:

- client giữ token
- mỗi request gửi token lên để xác thực lại

## 3. Các class quan trọng và chức năng của từng class

## 3.1 SecurityFilterChain

Chức năng:

1. Định nghĩa luật bảo mật cho HTTP request
2. Khai báo endpoint nào public, endpoint nào cần login
3. Cấu hình csrf, session, formLogin, httpBasic, jwt filter

Ví dụ cấu hình:

```java
@Bean
SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
    http
        .csrf(csrf -> csrf.disable())
        .authorizeHttpRequests(auth -> auth
            .requestMatchers("/public/**").permitAll()
            .requestMatchers("/admin/**").hasRole("ADMIN")
            .anyRequest().authenticated()
        )
        .formLogin(Customizer.withDefaults());

    return http.build();
}
```

## 3.2 HttpSecurity

`HttpSecurity` là class builder để cấu hình bảo mật web.

Chức năng:

1. Bật/tắt CSRF
2. Cấu hình authorize request
3. Cấu hình form login
4. Cấu hình logout
5. Cấu hình session management
6. Thêm custom filter

## 3.3 UsernamePasswordAuthenticationFilter

Đây là filter xử lý đăng nhập bằng username/password.

Chức năng:

1. Đọc username/password từ request
2. Tạo `UsernamePasswordAuthenticationToken`
3. Gọi `AuthenticationManager`

Nó thường dùng trong form login.

## 3.4 BasicAuthenticationFilter

Chức năng:

1. Đọc `Authorization: Basic ...`
2. Giải mã thông tin đăng nhập
3. Gọi xác thực

Phù hợp cho API đơn giản hoặc môi trường internal.

## 3.5 BearerTokenAuthenticationFilter

Chức năng:

1. Đọc `Authorization: Bearer <token>`
2. Trích token
3. Chuyển token sang cơ chế xác thực phù hợp

Thường gặp trong OAuth2 Resource Server hoặc JWT-based API.

## 3.6 AuthenticationManager

Method quan trọng:

```java
Authentication authenticate(Authentication authentication)
```

Chức năng:

1. Là cổng vào chung cho quá trình xác thực
2. Điều phối provider phù hợp

## 3.7 ProviderManager

`ProviderManager` là implementation phổ biến của `AuthenticationManager`.

Chức năng:

1. Giữ danh sách `AuthenticationProvider`
2. Chọn provider nào hỗ trợ loại authentication hiện tại
3. Dừng khi có provider xác thực thành công

## 3.8 AuthenticationProvider

Interface này có 2 method quan trọng:

1. `authenticate(...)`
2. `supports(...)`

Chức năng:

1. Xác thực một loại `Authentication` cụ thể
2. Khai báo provider có hỗ trợ kiểu token hiện tại hay không

## 3.9 DaoAuthenticationProvider

Đây là provider rất phổ biến khi login bằng username/password từ database.

Chức năng:

1. Gọi `UserDetailsService`
2. Lấy user từ DB
3. So sánh password bằng `PasswordEncoder`
4. Trả về `Authentication` đã xác thực

## 3.10 UserDetailsService

Method chính:

```java
UserDetails loadUserByUsername(String username)
```

Chức năng:

1. Tìm user theo username
2. Trả về object `UserDetails`
3. Ném `UsernameNotFoundException` nếu không tìm thấy

## 3.11 UserDetails

Đây là interface mô tả user theo chuẩn bảo mật của Spring.

Chức năng:

1. Cung cấp thông tin user cho quá trình xác thực
2. Cung cấp danh sách quyền để phân quyền

Implementation có sẵn hay gặp:

1. `org.springframework.security.core.userdetails.User`

## 3.12 UsernamePasswordAuthenticationToken

Đây là implementation phổ biến của `Authentication`.

Chức năng:

1. Đại diện cho request login bằng username/password
2. Trạng thái ban đầu là chưa xác thực
3. Sau khi xác thực thành công, object mới có authorities và `authenticated = true`

## 3.13 GrantedAuthority

Đây là interface đại diện cho một quyền.

Ví dụ:

1. `ROLE_ADMIN`
2. `ROLE_USER`
3. `READ_REPORT`

Implementation phổ biến:

1. `SimpleGrantedAuthority`

## 3.14 SecurityContext

`SecurityContext` là object chứa `Authentication`.

Chức năng:

1. Lưu identity của user hiện tại
2. Được dùng xuyên suốt request

## 3.15 SecurityContextHolder

Chức năng:

1. Cung cấp cách truy xuất `SecurityContext` ở bất kỳ đâu trong request hiện tại

Ví dụ:

```java
Authentication auth = SecurityContextHolder.getContext().getAuthentication();
String username = auth.getName();
```

## 3.16 PasswordEncoder

Interface dùng cho password hashing và matching.

Method chính:

1. `encode(rawPassword)`
2. `matches(rawPassword, encodedPassword)`

Implementation phổ biến:

1. `BCryptPasswordEncoder`
2. `Pbkdf2PasswordEncoder`
3. `SCryptPasswordEncoder`

## 3.17 ExceptionTranslationFilter

Filter này xử lý các exception bảo mật phát sinh trong filter chain.

Chức năng:

1. Bắt `AuthenticationException`
2. Bắt `AccessDeniedException`
3. Trả response phù hợp như `401` hoặc `403`

## 3.18 AuthenticationEntryPoint

Chức năng:

1. Xử lý khi user chưa đăng nhập hoặc token không hợp lệ
2. Trả về `401 Unauthorized`

Ví dụ thường dùng trong API:

- trả JSON lỗi unauthorized

## 3.19 AccessDeniedHandler

Chức năng:

1. Xử lý khi user đã đăng nhập nhưng không đủ quyền
2. Trả về `403 Forbidden`

## 3.20 AuthorizationFilter

Chức năng:

1. Kiểm tra request hiện tại có đủ quyền hay không
2. Áp các rule từ cấu hình authorize request

## 3.21 @EnableMethodSecurity

Đây không phải class business chính, nhưng là annotation rất quan trọng.

Chức năng:

1. Bật security ở mức method
2. Cho phép dùng:
   - `@PreAuthorize`
   - `@PostAuthorize`
   - `@Secured`
   - `@RolesAllowed`

Ví dụ:

```java
@EnableMethodSecurity
@Configuration
public class SecurityConfig {
}
```

## 3.22 @PreAuthorize

Chức năng:

1. Kiểm tra quyền trước khi method chạy

Ví dụ:

```java
@PreAuthorize("hasRole('ADMIN')")
public String adminOnly() {
    return "secret";
}
```

## 3.23 OncePerRequestFilter

Đây là base class rất hay dùng khi viết custom JWT filter.

Chức năng:

1. Đảm bảo filter chỉ chạy một lần cho mỗi request
2. Làm nền để tự viết filter kiểm tra JWT

## 4. Nhóm class thường gặp theo chức năng

## 4.1 Nhóm cấu hình

1. `SecurityFilterChain`
2. `HttpSecurity`
3. `@EnableMethodSecurity`

## 4.2 Nhóm xác thực

1. `Authentication`
2. `AuthenticationManager`
3. `ProviderManager`
4. `AuthenticationProvider`
5. `DaoAuthenticationProvider`
6. `UsernamePasswordAuthenticationToken`
7. `UserDetailsService`
8. `UserDetails`
9. `PasswordEncoder`

## 4.3 Nhóm lưu context

1. `SecurityContext`
2. `SecurityContextHolder`

## 4.4 Nhóm filter

1. `UsernamePasswordAuthenticationFilter`
2. `BasicAuthenticationFilter`
3. `BearerTokenAuthenticationFilter`
4. `ExceptionTranslationFilter`
5. `AuthorizationFilter`
6. `OncePerRequestFilter`

## 4.5 Nhóm xử lý lỗi và phân quyền

1. `AuthenticationEntryPoint`
2. `AccessDeniedHandler`
3. `GrantedAuthority`
4. `@PreAuthorize`

## 5. Ví dụ mapping đơn giản giữa thành phần và vai trò

1. `SecurityFilterChain`: cổng bảo vệ request
2. `UsernamePasswordAuthenticationFilter`: lấy user/pass từ request
3. `AuthenticationManager`: điều phối xác thực
4. `DaoAuthenticationProvider`: xác thực dựa trên DB
5. `UserDetailsService`: tải user
6. `PasswordEncoder`: kiểm tra password
7. `SecurityContextHolder`: giữ user hiện tại
8. `AuthorizationFilter`: kiểm tra quyền
9. `AuthenticationEntryPoint`: trả `401`
10. `AccessDeniedHandler`: trả `403`

## 6. Tóm tắt ngắn

Spring Security hoạt động theo tư duy:

1. Chặn request bằng filter chain
2. Xác thực danh tính
3. Lưu user vào security context
4. Kiểm tra quyền truy cập
5. Cho phép hoặc từ chối request

Nếu học để phỏng vấn, nên nắm chắc các class sau trước:

1. `SecurityFilterChain`
2. `HttpSecurity`
3. `Authentication`
4. `AuthenticationManager`
5. `AuthenticationProvider`
6. `UserDetailsService`
7. `UserDetails`
8. `PasswordEncoder`
9. `SecurityContextHolder`
10. `@PreAuthorize`
