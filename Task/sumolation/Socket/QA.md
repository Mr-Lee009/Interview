# Câu hỏi về WebSocket

## 1. WebSocket là gì?

- WebSocket là giao thức giúp `client` và `server` giữ một kết nối mở lâu dài.
- Sau khi kết nối thành công, hai bên có thể gửi dữ liệu cho nhau bất kỳ lúc nào.
- Nó rất phù hợp cho các bài toán `realtime`.

Ví dụ:

- Ứng dụng chat
- Thông báo realtime
- Dashboard giá chứng khoán

## 2. WebSocket khác gì so với HTTP request/response truyền thống?

- `HTTP` thường là:
  client gửi request, server trả response, xong thì kết thúc.
- `WebSocket` là:
  tạo kết nối một lần, sau đó dùng lại để gửi nhiều message hai chiều.
- WebSocket giảm việc phải gọi request lặp đi lặp lại.

Ví dụ:

- HTTP polling: cứ 5 giây client gọi API lấy tin nhắn mới
- WebSocket: server có tin nhắn mới thì đẩy ngay xuống client

## 3. Vì sao WebSocket được gọi là giao tiếp `full-duplex`?

- `Full-duplex` nghĩa là cả `client` và `server` đều có thể gửi dữ liệu cho nhau cùng lúc.
- Không cần chờ bên kia gửi trước rồi mới được trả lời.

Ví dụ:

- Trong chat:
  client A gửi tin nhắn lên server
- Cùng lúc đó:
  server vẫn có thể đẩy notification mới xuống client B

## 4. `WebSocket handshake` là gì và vì sao nó bắt đầu từ HTTP?

- `Handshake` là bước bắt tay ban đầu để nâng cấp từ kết nối HTTP sang WebSocket.
- Nó bắt đầu từ HTTP vì WebSocket tận dụng hạ tầng web sẵn có như:
  - domain
  - port
  - proxy
  - header
- Sau khi server chấp nhận `upgrade`, kết nối chuyển sang chế độ WebSocket.

Ví dụ:

- Client gửi request có header `Upgrade: websocket`
- Server trả về `101 Switching Protocols`

## 5. Sự khác nhau giữa `ws://` và `wss://` là gì?

- `ws://` là WebSocket không mã hóa
- `wss://` là WebSocket có mã hóa TLS/SSL, tương tự `https://`
- Khi chạy production, thường nên dùng `wss://`

Ví dụ:

- Dev local: `ws://localhost:8080/chat`
- Production: `wss://example.com/chat`

## 6. Khi nào nên dùng `WebSocket`, khi nào chỉ cần `polling` hoặc `long polling`?

- Dùng `WebSocket` khi:
  - cần realtime
  - update liên tục
  - hai chiều
- Dùng `polling` khi:
  - hệ thống đơn giản
  - dữ liệu thay đổi ít
  - không cần realtime mạnh
- Dùng `long polling` khi:
  - muốn gần realtime hơn polling
  - nhưng chưa muốn dùng WebSocket

Ví dụ:

- Chat: nên dùng WebSocket
- Trang báo cáo 5 phút refresh một lần: polling là đủ

## 7. Làm sao xác thực người dùng khi thiết lập kết nối WebSocket?

- Thường xác thực ngay lúc `handshake`
- Có thể truyền:
  - `JWT token`
  - session cookie
  - access token trong header hoặc query param
- Server sẽ kiểm tra token trước khi cho phép mở kết nối

Ví dụ:

- Client mở kết nối với token
- Server đọc token, xác thực user
- Nếu token sai thì từ chối kết nối

## 8. Nếu hệ thống có nhiều instance server, làm sao broadcast message qua WebSocket cho đúng tất cả client?

- Vì client có thể đang kết nối vào nhiều node khác nhau, một node không thể tự biết toàn bộ client ở node khác.
- Cần thêm một tầng đồng bộ message như:
  - Redis Pub/Sub
  - Kafka
  - RabbitMQ
- Một node nhận event thì publish ra broker, các node khác cùng nhận rồi push xuống client của mình.

Ví dụ:

- User A kết nối vào server 1
- User B kết nối vào server 2
- Server 1 nhận tin nhắn mới, publish qua Redis
- Server 2 cũng nhận được và đẩy xuống user B

## 9. `ping/pong` hoặc `heartbeat` trong WebSocket dùng để làm gì?

- Dùng để kiểm tra kết nối còn sống hay không
- Giúp phát hiện connection bị treo, mất mạng hoặc chết ngầm
- Nếu không có heartbeat, server có thể tưởng client vẫn online dù thực tế đã rớt mạng

Ví dụ:

- Mỗi 30 giây server gửi `ping`
- Nếu client không trả `pong` sau một thời gian, server đóng kết nối

## 10. Nếu client bị mất mạng rồi kết nối lại, hệ thống WebSocket nên xử lý reconnect và đồng bộ message như thế nào?

- Client nên có cơ chế `auto reconnect`
- Server không nên chỉ dựa vào WebSocket để giữ toàn bộ state quan trọng
- Nên lưu message hoặc event quan trọng ở DB / cache / message store
- Khi reconnect:
  - client gửi `lastMessageId` hoặc `lastSeenTimestamp`
  - server trả lại phần message còn thiếu

Ví dụ:

- Client đang chat thì mất mạng 10 giây
- Sau khi kết nối lại, client gửi `lastMessageId = 150`
- Server trả lại các tin từ `151` trở đi

## Ghi nhớ nhanh

- WebSocket phù hợp cho `realtime`
- Nó giữ kết nối lâu dài giữa client và server
- Nó là `full-duplex`
- Production thường dùng `wss://`
- Khi scale nhiều node, thường cần thêm `Redis`, `Kafka` hoặc message broker
