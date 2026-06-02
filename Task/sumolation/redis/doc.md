# Redis Interview Notes

Tài liệu này dùng để ôn phỏng vấn Redis trong bối cảnh backend/Java. Thư mục `redis` hiện có `demo.html` để minh họa trực quan và file `doc.md` này để ghi lại kiến thức cần nhớ.

## Redis dùng để làm gì?

Redis là in-memory data store thường được dùng cho:

- Cache dữ liệu đọc nhiều.
- Lưu session hoặc token ngắn hạn.
- Counter, rate limit, leaderboard.
- Queue nhẹ, pub/sub hoặc stream.
- Distributed lock trong hệ thống nhiều instance.
- Lưu dữ liệu tạm với TTL.

Điểm cần nhấn mạnh khi đi phỏng vấn: Redis rất nhanh vì dữ liệu nằm trong RAM và command được thiết kế đơn giản, nhưng vẫn cần hiểu persistence, memory limit, eviction policy và consistency khi dùng làm cache.

## Khái niệm nên nắm

- `String`: lưu value đơn giản, counter, JSON string hoặc token.
- `Hash`: lưu object dạng field-value.
- `List`: queue đơn giản hoặc danh sách có thứ tự chèn.
- `Set`: tập không trùng, kiểm tra membership.
- `Sorted Set`: ranking, leaderboard, score-based query.
- `Bitmap`: tracking trạng thái nhị phân như điểm danh/ngày active.
- `HyperLogLog`: ước lượng số phần tử duy nhất.
- `Stream`: message log có consumer group.
- `TTL`: thời gian sống của key.
- `Eviction policy`: cách Redis xóa key khi đầy bộ nhớ.
- `Persistence`: RDB, AOF hoặc kết hợp cả hai.

## Câu hỏi phỏng vấn hay gặp

1. Redis khác database thường ở điểm nào?
2. Vì sao Redis nhanh?
3. Khi nào nên dùng Redis làm cache?
4. TTL là gì và vì sao cần TTL?
5. Cache penetration, cache breakdown và cache avalanche khác nhau thế nào?
6. Redis persistence gồm những loại nào?
7. RDB và AOF khác nhau ra sao?
8. Redis eviction policy là gì?
9. Distributed lock bằng Redis cần chú ý gì?
10. Pub/Sub và Stream khác nhau thế nào?

## Trả lời ngắn theo hướng phỏng vấn

### Vì sao Redis nhanh?

Redis chủ yếu làm việc trong RAM, command đơn giản, data structure tối ưu và mô hình xử lý command truyền thống thường là single-thread cho phần thực thi lệnh chính. Vì vậy Redis tránh được nhiều chi phí I/O disk như database thông thường.

### Cache penetration là gì?

Cache penetration xảy ra khi request truy vấn dữ liệu không tồn tại, cache không có, database cũng không có. Nếu bị gọi nhiều lần, request sẽ xuyên qua cache và gây tải lên database.

Cách xử lý:

- Cache cả kết quả rỗng trong thời gian ngắn.
- Dùng Bloom Filter để chặn key chắc chắn không tồn tại.
- Validate input để tránh key rác.

### Cache breakdown là gì?

Cache breakdown xảy ra khi một hot key hết hạn, nhiều request đồng thời cùng đi xuống database để lấy lại dữ liệu.

Cách xử lý:

- Dùng mutex/distributed lock khi rebuild cache.
- Gia hạn TTL chủ động cho hot key.
- Dùng stale cache trong thời gian ngắn.

### Cache avalanche là gì?

Cache avalanche xảy ra khi nhiều key hết hạn cùng lúc hoặc Redis bị lỗi, làm lượng lớn request dồn xuống database.

Cách xử lý:

- Random TTL để tránh hết hạn đồng loạt.
- Dùng Redis cluster/replica để tăng độ sẵn sàng.
- Có circuit breaker hoặc fallback.
- Warm up cache trước khi mở traffic lớn.

## Distributed lock bằng Redis

Một lock Redis cơ bản thường dùng:

```text
SET lock_key request_id NX PX 30000
```

Ý nghĩa:

- `NX`: chỉ set nếu key chưa tồn tại.
- `PX`: TTL tính bằng millisecond.
- `request_id`: định danh owner của lock để tránh xóa nhầm lock của request khác.

Khi unlock, nên kiểm tra value có đúng `request_id` rồi mới xóa key. Thao tác kiểm tra và xóa nên chạy atomically bằng Lua script.

## RDB và AOF

- `RDB`: snapshot dữ liệu tại một thời điểm. File nhỏ, restore nhanh, nhưng có thể mất dữ liệu từ lần snapshot gần nhất.
- `AOF`: ghi lại command thay đổi dữ liệu. Ít mất dữ liệu hơn tùy cấu hình append/fsync, nhưng file có thể lớn hơn và cần rewrite.

Trong thực tế có thể bật cả RDB và AOF tùy yêu cầu khôi phục, hiệu năng và mức chấp nhận mất dữ liệu.

## Ghi chú demo

- `QA.md` là file hỏi đáp chi tiết về RDB, AOF, chiến lược kết hợp, ưu nhược điểm, ví dụ thực tế và hướng xử lý.
- `docker-config.md` là tài liệu cấu hình Redis Docker cho 3 case: chỉ `RDB`, chỉ `AOF`, và kết hợp `RDB + AOF`.
- `demo.html` là file mô phỏng trực quan cho chủ đề Redis.
- `rdb-aof-backup.html` là file mô phỏng riêng quá trình backup/persistence của `RDB` và `AOF`.
- Nếu mở rộng demo, nên thêm phần thể hiện flow `client -> cache -> database`, TTL, cache miss/cache hit và invalidation.
- Nếu thêm câu hỏi mới, ghi vào file này để `menu.md` vẫn giữ vai trò mục lục, còn kiến thức chi tiết nằm trong `doc.md`.
