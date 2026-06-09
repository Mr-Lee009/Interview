# Câu 10. Nếu client bị mất mạng rồi kết nối lại, hệ thống WebSocket nên xử lý reconnect và đồng bộ message như thế nào?

## 1. Ý chính

Khi dùng WebSocket, một kết nối có thể bị mất vì:

- mất mạng
- đổi mạng từ wifi sang 4G
- tab browser bị reload
- server restart
- proxy hoặc load balancer cắt kết nối

Nếu chỉ đơn giản là mở lại WebSocket:

- client kết nối lại được
- nhưng rất dễ bị mất các message phát sinh trong lúc offline

Vì vậy, reconnect chỉ là một nửa bài toán.

Nửa còn lại là:

- làm sao đồng bộ lại các message bị lỡ

## 2. Vấn đề thực tế là gì?

Giả sử:

- client đang nhận message đến `messageId = 150`
- sau đó mất mạng 10 giây
- trong 10 giây đó hệ thống phát sinh thêm:
  - `151`
  - `152`
  - `153`

Nếu client reconnect mà không báo mình đã nhận tới đâu:

- server không biết cần gửi bù từ message nào
- client có thể bị mất 3 message trên

## 3. Cách làm đúng về mặt ý tưởng

Thường sẽ có 4 bước:

1. client tự động reconnect
2. client gửi mốc cuối cùng đã nhận
3. server tìm các message còn thiếu
4. server replay lại phần còn thiếu

Đây là ý tưởng cốt lõi:

- reconnect để mở lại kết nối
- replay để khôi phục dữ liệu đã lỡ

## 4. Client nên làm gì?

### 4.1 Tự động reconnect

Client nên có cơ chế:

- reconnect sau khi socket đóng
- retry theo khoảng chờ tăng dần

Ví dụ:

- lần 1 chờ `1s`
- lần 2 chờ `2s`
- lần 3 chờ `5s`

Không nên reconnect quá dồn dập vì:

- dễ làm quá tải server
- dễ tạo vòng lặp lỗi vô hạn

### 4.2 Lưu mốc cuối cùng đã nhận

Client nên lưu:

- `lastMessageId`
- hoặc `lastSeenTimestamp`
- hoặc `lastEventSequence`

Khuyến nghị thực tế:

- ưu tiên `messageId` tăng dần
- vì dễ so sánh và replay hơn timestamp

Ví dụ:

- client đã nhận tới `messageId = 150`
- lưu con số này trong memory hoặc local storage tùy bài toán

## 5. Server nên làm gì?

### 5.1 Không chỉ phụ thuộc vào kết nối WebSocket

Server không nên nghĩ rằng:

- client đang online thì chắc chắn không mất message

Vì:

- message có thể được tạo ra khi client vừa rớt mạng
- client có thể reconnect vào node khác

### 5.2 Lưu message hoặc event quan trọng

Nếu message có giá trị nghiệp vụ, nên lưu ở:

- database
- cache có retention
- message store

Ví dụ:

- chat message
- notification quan trọng
- trạng thái workflow

Không nhất thiết phải lưu với:

- typing event
- online status ngắn hạn
- animation realtime tạm thời

## 6. Luồng reconnect chuẩn

Ví dụ với chat:

1. client đang nhận tới `messageId = 150`
2. client mất mạng
3. server vẫn tiếp tục tạo message `151`, `152`, `153`
4. client reconnect
5. client gửi:
   - `roomId = room-a`
   - `lastMessageId = 150`
6. server query:
   - tất cả message có `id > 150`
7. server trả lại `151`, `152`, `153`
8. sau đó kết nối WebSocket quay về realtime bình thường

## 7. Có những cách đồng bộ nào?

### Cách 1: Đồng bộ theo `lastMessageId`

Đây là cách dễ hiểu và phổ biến nhất.

Client gửi:

- `lastMessageId = 150`

Server trả:

- mọi message có `id > 150`

Ưu điểm:

- rõ ràng
- đơn giản
- dễ debug

Nhược điểm:

- cần message có id tăng dần đáng tin cậy

### Cách 2: Đồng bộ theo `timestamp`

Client gửi:

- `lastSeenTimestamp`

Server tìm:

- các message sinh sau mốc thời gian đó

Ưu điểm:

- dễ dùng trong một số hệ thống event

Nhược điểm:

- dễ gặp vấn đề về độ chính xác thời gian
- có thể khó xử lý hơn nếu nhiều event cùng timestamp

### Cách 3: Đồng bộ theo `sequence`

Mỗi room hoặc mỗi stream có một sequence tăng dần:

- `seq = 101`
- `seq = 102`
- `seq = 103`

Client gửi sequence cuối cùng đã nhận.

Ưu điểm:

- phù hợp realtime stream hoặc event bus

Nhược điểm:

- cần thiết kế sequence rõ ràng

## 8. Có cần REST API để sync lại không?

Thực tế có 2 hướng:

### Hướng 1: Sync luôn qua WebSocket

Sau khi reconnect:

- client gửi command kiểu `SYNC_MISSED_MESSAGES`
- server trả lại message còn thiếu qua WebSocket

Ưu điểm:

- một kênh duy nhất

Nhược điểm:

- logic trong WebSocket phình ra

### Hướng 2: Reconnect WebSocket, còn sync lại qua REST API

Luồng:

1. client mở lại WebSocket
2. client gọi REST API:
   - `/messages?afterId=150`
3. lấy các message thiếu
4. sau đó tiếp tục realtime qua WebSocket

Ưu điểm:

- rõ ràng
- dễ debug
- dễ cache, paging, retry

Nhược điểm:

- có thêm một flow REST

Trong thực tế, rất nhiều hệ thống chọn hướng này vì dễ vận hành hơn.

## 9. Những rủi ro cần lưu ý

### Duplicate message

Có thể xảy ra:

- client reconnect
- vừa nhận replay
- vừa nhận thêm realtime event trùng

Cần xử lý:

- deduplicate theo `messageId`

### Out-of-order message

Có thể xảy ra nếu:

- replay và realtime đến không đúng thứ tự

Cần:

- sort theo `messageId` hoặc `sequence`

### Reconnect storm

Nếu server vừa restart:

- hàng nghìn client cùng reconnect một lúc

Cần:

- exponential backoff
- jitter
- limit tốc độ reconnect

### Message retention

Nếu lưu message quá ngắn:

- client reconnect muộn có thể không còn dữ liệu để sync

Khi đó cần:

- chính sách retention rõ ràng
- hoặc fallback gọi lịch sử từ DB

## 10. Ví dụ thực tế dễ hiểu

### Ví dụ chat

- user đang chat ở room A
- nhận tới `messageId = 150`
- mất mạng 15 giây
- trong lúc đó room có thêm 5 tin mới
- reconnect xong client gửi `lastMessageId = 150`
- server trả lại 5 tin chưa nhận

### Ví dụ notification

- user đang mở dashboard
- bị mất mạng ngắn
- reconnect xong gửi `lastSeenTimestamp`
- server gửi lại các notification quan trọng còn thiếu

## 11. Khi nào không cần sync lại?

Không phải event nào cũng cần replay.

Ví dụ thường không cần:

- typing indicator
- online/offline status tức thời
- animation tạm thời

Vì nếu lỡ các event này:

- không gây sai nghiệp vụ lớn

## 12. Kết luận ngắn

- reconnect chỉ giúp mở lại kết nối
- muốn đúng nghiệp vụ thì phải có thêm cơ chế replay message bị lỡ
- client nên gửi:
  - `lastMessageId`
  - hoặc `lastSeenTimestamp`
- server nên:
  - lưu message quan trọng
  - trả lại phần còn thiếu
  - chống duplicate và sai thứ tự

## Ghi nhớ nhanh

- `auto reconnect` là chưa đủ
- cần thêm `sync missed messages`
- nên dùng `messageId` hoặc `sequence`
- event quan trọng phải có nơi lưu lại
- replay và realtime phải có cơ chế chống trùng
