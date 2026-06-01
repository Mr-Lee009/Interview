# Hệ thống chữ ký số

## 1. Chữ ký số là gì?

Chữ ký số là cơ chế dùng mật mã khóa công khai để chứng minh:

- Ai là người đã ký dữ liệu.
- Dữ liệu có bị sửa sau khi ký hay không.
- Người ký khó thể chối bỏ hành vi ký của mình.

Khác với chữ ký tay, chữ ký số không ký trực tiếp lên toàn bộ tài liệu bằng mắt thường, mà ký lên `hash` của dữ liệu bằng `private key`.

## 2. Mục tiêu của một hệ thống chữ ký số

Một hệ thống chữ ký số thường phải đảm bảo 3 thuộc tính chính:

- `Authenticity`: xác thực đúng người ký.
- `Integrity`: dữ liệu không bị thay đổi.
- `Non-repudiation`: người ký không dễ phủ nhận việc đã ký.

## 3. Các thành phần chính

### 3.1 Người dùng / người ký

Là cá nhân hoặc tổ chức cần ký tài liệu, hợp đồng, hóa đơn, giao dịch, API request hoặc email.

Người dùng sở hữu:

- `Private key`: khóa bí mật, dùng để ký.
- `Public key`: khóa công khai, dùng để cho bên khác xác minh.

### 3.2 CA (Certificate Authority)

CA là tổ chức cấp phát và xác thực `chứng thư số`.

Vai trò:

- Xác minh danh tính người đăng ký.
- Phát hành chứng thư số gắn `public key` với danh tính thật.
- Thu hồi chứng thư khi khóa lộ, hết hiệu lực hoặc thông tin sai.

### 3.3 Chứng thư số (Digital Certificate)

Chứng thư số là một tài liệu điện tử chứa:

- Thông tin chủ thể: cá nhân, doanh nghiệp, máy chủ.
- `Public key` của chủ thể.
- Thời hạn hiệu lực.
- Thông tin CA phát hành.
- Chữ ký số của CA.

Chứng thư số thường theo chuẩn `X.509`.

### 3.4 RA (Registration Authority)

RA là thành phần hỗ trợ CA trong bước đăng ký và kiểm tra danh tính.  
Trong nhiều hệ thống, RA và CA có thể là hai vai trò tách biệt.

### 3.5 Hệ thống xác minh

Là bên nhận tài liệu hoặc dịch vụ kiểm tra chữ ký.  
Hệ thống này cần:

- Có dữ liệu gốc.
- Có chữ ký số.
- Có chứng thư số của người ký.
- Có chuỗi tin cậy đến CA gốc.

## 4. Luồng hoạt động

### Bước 1: Tạo cặp khóa

Người dùng tạo:

- `Private key`
- `Public key`

`Private key` phải được bảo vệ rất chặt, thường lưu trong:

- USB Token
- HSM
- Smart card
- Secure enclave

### Bước 2: Xin cấp chứng thư số

Người dùng gửi `public key` và thông tin định danh đến CA/RA.  
CA kiểm tra danh tính rồi phát hành chứng thư số.

### Bước 3: Ký dữ liệu

Khi ký một tài liệu:

1. Hệ thống tạo `hash` của tài liệu, ví dụ bằng `SHA-256`.
2. Dùng `private key` mã hóa hoặc ký lên giá trị `hash`.
3. Kết quả tạo ra `digital signature`.

Lưu ý: thực tế không ký trực tiếp lên file lớn, mà ký lên `hash` để nhanh và hiệu quả hơn.

### Bước 4: Gửi tài liệu đã ký

Bên gửi thường gửi kèm:

- Tài liệu gốc
- Chữ ký số
- Chứng thư số của người ký

### Bước 5: Xác minh chữ ký

Bên nhận sẽ:

1. Tạo lại `hash` từ tài liệu nhận được.
2. Dùng `public key` trong chứng thư số để kiểm tra chữ ký.
3. So sánh `hash` tính lại với `hash` đã được ký.
4. Kiểm tra chứng thư còn hiệu lực hay không.
5. Kiểm tra chứng thư có bị thu hồi qua `CRL` hoặc `OCSP` hay không.
6. Kiểm tra chuỗi tin cậy đến CA gốc.

Nếu tất cả hợp lệ thì chữ ký được xem là hợp lệ.

## 5. Kiến trúc PKI

Hệ thống chữ ký số trong thực tế thường dựa trên `PKI` (`Public Key Infrastructure`).

PKI bao gồm:

- CA gốc (`Root CA`)
- CA trung gian (`Intermediate CA`)
- RA
- Kho chứng thư
- Danh sách thu hồi `CRL`
- Dịch vụ kiểm tra trạng thái `OCSP`
- Chính sách và quy trình quản trị khóa

Mô hình tin cậy thường là:

`Root CA -> Intermediate CA -> End User Certificate`

## 6. Ví dụ luồng ký số trong doanh nghiệp

Ví dụ ký hóa đơn điện tử:

1. Doanh nghiệp tạo file hóa đơn XML/PDF.
2. Hệ thống băm nội dung hóa đơn.
3. USB Token hoặc HSM dùng `private key` để ký.
4. Chữ ký số được nhúng vào file hoặc đính kèm.
5. Cơ quan thuế hoặc khách hàng dùng chứng thư số để xác minh.

Kết quả đạt được:

- Biết hóa đơn do đúng doanh nghiệp phát hành.
- Phát hiện được chỉnh sửa sau khi ký.
- Có giá trị pháp lý nếu dùng chứng thư hợp lệ.

## 7. Thuật toán thường dùng

- Hàm băm: `SHA-256`, `SHA-384`
- Chữ ký bất đối xứng: `RSA`, `ECDSA`
- Chuẩn chứng thư: `X.509`
- Chuẩn đóng gói chữ ký: `PKCS#7`, `CMS`, `XMLDSig`, `PAdES`

## 8. Ưu điểm

- Xác thực mạnh hơn chữ ký tay trong môi trường số.
- Kiểm tra toàn vẹn tự động.
- Hỗ trợ giao dịch điện tử quy mô lớn.
- Dễ tích hợp vào hóa đơn điện tử, hợp đồng điện tử, email, API.

## 9. Rủi ro và điểm cần quản trị

- Lộ `private key` là rủi ro nghiêm trọng nhất.
- Chứng thư hết hạn hoặc bị thu hồi sẽ làm chữ ký không còn hợp lệ.
- Nếu không kiểm tra `CRL/OCSP`, hệ thống có thể tin nhầm chứng thư đã bị thu hồi.
- Cần quản lý thời gian ký, log kiểm toán và phân quyền sử dụng khóa.

## 10. Phân biệt nhanh

- `Mã hóa`: dùng để giữ bí mật dữ liệu.
- `Chữ ký số`: dùng để xác thực người ký và bảo vệ toàn vẹn dữ liệu.
- `Chứng thư số`: tài liệu xác nhận `public key` thuộc về ai.
- `CA`: đơn vị phát hành và bảo đảm niềm tin cho chứng thư số.

## 11. Tóm tắt ngắn

Một hệ thống chữ ký số là sự kết hợp giữa:

- Cặp khóa công khai/bí mật
- Chứng thư số
- CA/PKI
- Quy trình ký và xác minh

Mục tiêu cuối cùng là bảo đảm `đúng người ký`, `đúng dữ liệu`, và `có thể kiểm chứng được`.
