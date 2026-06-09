# Câu 7. Làm sao xác thực người dùng khi thiết lập kết nối WebSocket?

## 1. Ý chính

WebSocket thường được xác thực ngay ở lúc `handshake`.

Lý do:

- đây là thời điểm đầu tiên server nhận yêu cầu mở kết nối
- nếu user không hợp lệ thì nên chặn ngay từ đầu
- tránh mở connection rồi mới phát hiện không có quyền

Luồng chung:

1. client gửi yêu cầu mở WebSocket
2. client mang theo thông tin xác thực
3. server kiểm tra thông tin đó
4. nếu hợp lệ thì cho phép upgrade sang WebSocket
5. nếu không hợp lệ thì từ chối kết nối

## 2. Có những cách xác thực nào?

Thường có 4 cách phổ biến:

1. dùng `session cookie`
2. dùng `JWT token`
3. dùng `access token` trong header
4. dùng `token` trong query param

## 3. Xác thực bằng session cookie

### Cách hoạt động

- user login bằng HTTP trước
- server tạo `session`
- browser giữ `session cookie`
- khi mở WebSocket, cookie được gửi kèm theo handshake
- server đọc session từ cookie rồi xác định user là ai

### Ví dụ

User login vào website:

- `POST /login`
- server trả về cookie như `JSESSIONID=abc123`

Khi browser mở WebSocket:

- `ws://example.com/chat`
- cookie `JSESSIONID=abc123` được gửi kèm

Server kiểm tra:

- session có tồn tại không
- session thuộc user nào
- session còn hạn không

### Ưu điểm

- dễ làm nếu hệ thống web đã dùng session sẵn
- phù hợp với ứng dụng web truyền thống
- browser tự gửi cookie, client code đơn giản

### Nhược điểm

- scale nhiều node thì phải xử lý session store
- không tiện bằng token cho mobile hoặc SPA tách backend riêng
- dễ bị phụ thuộc vào trạng thái server

### Khi nào nên dùng

- hệ thống web server-rendered
- backend dùng Spring Security session-based
- internal tool hoặc admin portal

## 4. Xác thực bằng JWT token

### Cách hoạt động

- user login trước qua HTTP
- server trả về `JWT`
- client lưu token
- khi mở WebSocket, client gửi token cho server
- server verify chữ ký, thời hạn, quyền và thông tin user trong token

### Ví dụ

Token:

```text
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

Client gửi khi mở kết nối:

- qua query param
- hoặc qua header tùy client/library hỗ trợ

Server kiểm tra:

- token có đúng chữ ký không
- token còn hạn không
- token có role phù hợp không

### Ưu điểm

- stateless, dễ scale
- hợp với SPA, mobile app, microservices
- không cần giữ session ở server

### Nhược điểm

- phải quản lý expiration cẩn thận
- revoke token khó hơn session
- nếu truyền token sai cách thì dễ lộ thông tin

### Khi nào nên dùng

- frontend tách riêng backend
- mobile app
- hệ thống microservices
- hệ thống cần scale ngang tốt

## 5. Xác thực bằng access token trong header

### Cách hoạt động

- client gửi token trong HTTP header của handshake
- server đọc header rồi xác thực

Ví dụ header:

```http
Authorization: Bearer <token>
```

### Ưu điểm

- rõ ràng
- cùng kiểu với REST API
- dễ reuse logic security sẵn có

### Nhược điểm

- không phải mọi WebSocket client đều hỗ trợ custom header tốt, nhất là browser native
- browser `new WebSocket()` thường không cho set `Authorization` header trực tiếp

### Khi nào nên dùng

- mobile app
- backend-to-backend
- desktop app
- client framework có hỗ trợ custom header

### Lưu ý quan trọng

Trong browser thuần:

- thường không set được `Authorization` header trực tiếp bằng API WebSocket native
- vì vậy người ta hay chuyển sang:
  - cookie
  - query param
  - hoặc handshake phụ qua HTTP trước

## 6. Xác thực bằng token trong query param

### Cách hoạt động

- client gắn token ngay trên URL khi mở WebSocket

Ví dụ:

```text
wss://example.com/chat?token=abc123
```

Server sẽ:

- đọc token từ query param
- xác thực token
- nếu hợp lệ thì mở kết nối

### Ưu điểm

- dễ làm
- rất tiện trong browser
- phù hợp khi không set được custom header

### Nhược điểm

- token dễ xuất hiện trong log, history, proxy log
- kém an toàn hơn header hoặc cookie
- cần cực kỳ cẩn thận khi logging

### Khi nào nên dùng

- browser client đơn giản
- demo
- hệ thống nội bộ

### Khuyến nghị

- chỉ dùng với `wss://`
- token nên ngắn hạn
- tránh log full URL

## 7. So sánh nhanh các cách

| Cách | Dễ triển khai | Dễ scale | Phù hợp browser | Mức an toàn |
|---|---|---|---|---|
| `Session cookie` | Dễ | Trung bình | Tốt | Tốt |
| `JWT token` | Tốt | Tốt | Tốt | Tốt |
| `Header token` | Tốt | Tốt | Hạn chế với browser native | Tốt |
| `Query param token` | Rất dễ | Tốt | Tốt | Trung bình |

## 8. Nên chọn cách nào?

### Trường hợp 1: Web app truyền thống

- nên dùng `session cookie`

Vì:

- đơn giản
- tận dụng Spring Security hiện có

### Trường hợp 2: SPA hoặc mobile app

- nên dùng `JWT token`

Vì:

- stateless
- phù hợp scale
- đồng bộ cách auth với REST API

### Trường hợp 3: Browser không set được header

- có thể dùng:
  - cookie
  - hoặc query param token

Nhưng nếu dùng query param thì phải siết bảo mật kỹ hơn.

## 9. Sau khi xác thực xong thì làm gì tiếp?

Sau khi xác thực thành công, server thường:

1. gắn `userId` vào session WebSocket
2. gắn `roles` hoặc `authorities`
3. lưu mapping giữa `connectionId` và `userId`
4. dùng thông tin đó để:
   - gửi message đúng user
   - kiểm tra quyền subscribe/send
   - theo dõi online/offline

Ví dụ:

- user `A` chỉ được subscribe `/user/queue/notifications`
- user `B` không được gửi vào room admin nếu không có role phù hợp

## 10. Cần kiểm tra gì ngoài authentication?

Authentication chỉ trả lời câu hỏi:

- "Bạn là ai?"

Nhưng còn cần `authorization`:

- "Bạn được phép làm gì?"

Ví dụ:

- user hợp lệ nhưng không được subscribe phòng của người khác
- user hợp lệ nhưng không được gửi message vào channel admin

Vì vậy khi thiết kế WebSocket cần cả:

1. `authentication`
2. `authorization`

## 11. Ví dụ thực tế dễ hiểu

Giả sử hệ thống chat nội bộ công ty.

### Cách 1: Dùng session cookie

- user login website
- browser có `JSESSIONID`
- mở WebSocket chat
- server đọc cookie và biết user là `duc.le`

### Cách 2: Dùng JWT

- mobile app login
- app nhận JWT
- app mở WebSocket và gửi JWT
- server verify token rồi bind kết nối với user `duc.le`

### Cách 3: Dùng query param

- browser mở:
  `wss://chat.company.com/ws?token=jwt_xyz`
- server đọc token từ URL và xác thực

## 12. Kết luận ngắn

- cách tốt nhất phụ thuộc vào loại client
- với web truyền thống: `session cookie` là tự nhiên nhất
- với SPA, mobile, microservices: `JWT` thường là lựa chọn tốt hơn
- `header token` sạch nhưng browser native thường hạn chế
- `query param token` dễ làm nhưng phải cẩn thận vì dễ lộ token

## Ghi nhớ nhanh

- xác thực nên diễn ra ở `handshake`
- browser thường thuận tiện với `cookie` hoặc `query param`
- mobile/backend client thường hợp với `header` hoặc `JWT`
- đừng quên `authorization` sau khi xác thực xong
