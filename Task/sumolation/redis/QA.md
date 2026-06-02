# Redis Persistence QA: RDB và AOF

File này trả lời các câu hỏi phỏng vấn về hai cơ chế backup/persistence chính của Redis: `RDB` và `AOF`.

## I. Nhóm câu hỏi về RDB

### 1. Cơ chế RDB tạo snapshot dữ liệu tại các thời điểm cụ thể như thế nào?

- `RDB` là cơ chế tạo snapshot toàn bộ dữ liệu Redis tại một thời điểm.
- Redis có thể tạo RDB bằng:
  - Cấu hình tự động trong `redis.conf`, ví dụ `save 900 1`, `save 300 10`, `save 60 10000`.
  - Lệnh thủ công `BGSAVE`.
  - Lệnh `SAVE`, nhưng ít dùng trong production vì block Redis server.
- Khi chạy `BGSAVE`:
  - Redis process cha gọi `fork()` tạo child process.
  - Child process ghi dữ liệu snapshot ra file tạm.
  - Khi ghi xong, file tạm được rename thành `dump.rdb`.
  - Process cha vẫn tiếp tục nhận request.
- Redis dùng cơ chế `copy-on-write`:
  - Tại thời điểm fork, child nhìn thấy dữ liệu như snapshot.
  - Nếu process cha thay đổi dữ liệu sau fork, OS chỉ copy phần memory page bị thay đổi.

**Ưu điểm**

- File snapshot gọn.
- Tạo backup định kỳ dễ hiểu.
- Restore nhanh vì chỉ load một file snapshot.
- Phù hợp để copy file backup sang server/storage khác.

**Nhược điểm**

- Có thể mất dữ liệu từ lần snapshot cuối đến lúc crash.
- Khi fork với dataset lớn có thể tốn RAM tạm thời.
- Nếu disk chậm, quá trình snapshot có thể gây ảnh hưởng hiệu năng.

**Ví dụ thực tế**

- Hệ thống cache sản phẩm:
  - Redis lưu danh sách sản phẩm hot.
  - Mỗi 5 phút tạo RDB snapshot.
  - Nếu Redis crash, có thể chấp nhận mất vài phút cache vì dữ liệu gốc vẫn nằm trong database.

**Hướng xử lý**

- Dùng `BGSAVE`, hạn chế dùng `SAVE` trong production.
- Theo dõi RAM để tránh fork gây thiếu bộ nhớ.
- Lưu `dump.rdb` ra disk nhanh.
- Copy snapshot ra storage khác nếu cần backup dài hạn.

### 2. Ưu điểm về performance và tốc độ phục hồi của RDB so với cơ chế khác là gì?

- RDB ít ghi disk liên tục hơn AOF.
- Redis chỉ ghi snapshot theo mốc cấu hình, không append từng command.
- File RDB thường nhỏ hơn AOF vì nó lưu state cuối cùng, không lưu toàn bộ lịch sử command.
- Khi restore, Redis chỉ đọc snapshot và dựng lại dữ liệu.

**Ưu điểm**

- Ít overhead runtime hơn AOF.
- Restore nhanh hơn AOF trong nhiều trường hợp.
- Backup file dễ di chuyển, dễ nén, dễ lưu trữ.
- Tốt cho disaster recovery định kỳ.

**Nhược điểm**

- Độ an toàn dữ liệu thấp hơn AOF nếu yêu cầu không mất dữ liệu.
- Snapshot dataset lớn có thể tạo spike CPU/RAM/disk I/O.

**Ví dụ thực tế**

- Redis dùng làm cache session tạm:
  - Mỗi 10 phút snapshot một lần.
  - Khi restart, Redis load `dump.rdb` rất nhanh.
  - Một số session mới có thể mất, nhưng user có thể login lại.

**Hướng xử lý**

- Nếu cần restore nhanh và chấp nhận mất ít dữ liệu, chọn RDB.
- Nếu dữ liệu quan trọng hơn performance, bật thêm AOF.

### 3. Tại sao RDB tiềm ẩn nguy cơ mất dữ liệu nếu hệ thống gặp sự cố đột ngột?

- RDB chỉ lưu dữ liệu tại thời điểm snapshot.
- Các thay đổi sau snapshot chưa được ghi vào `dump.rdb`.
- Nếu Redis crash trước lần snapshot tiếp theo, các thay đổi đó mất.

**Ví dụ**

- Cấu hình:
  - `save 300 10`: nếu trong 5 phút có ít nhất 10 thay đổi thì tạo snapshot.
- Timeline:
  - 10:00 tạo `dump.rdb`.
  - 10:01 đến 10:04 có 1.000 lệnh ghi mới.
  - 10:04 Redis crash.
  - Khi restart, Redis chỉ restore dữ liệu đến 10:00.
  - 1.000 thay đổi sau 10:00 có thể mất.

**Ưu điểm của cách này**

- Không phải ghi disk liên tục.
- Redis giữ performance tốt hơn.

**Nhược điểm**

- Không phù hợp nếu dữ liệu không được phép mất.
- Rủi ro càng lớn nếu khoảng cách snapshot càng dài.

**Hướng xử lý**

- Rút ngắn tần suất snapshot nếu chấp nhận tăng overhead.
- Bật thêm AOF với `appendfsync everysec`.
- Với dữ liệu rất quan trọng, không nên chỉ dựa vào Redis persistence, cần database chính hoặc event log riêng.

### 4. Khi nào RDB là phương án backup tối ưu hơn?

- Khi Redis chủ yếu dùng làm cache.
- Khi có thể chấp nhận mất một phần dữ liệu gần nhất.
- Khi cần restore nhanh.
- Khi cần file backup gọn để lưu trữ định kỳ.
- Khi muốn giảm overhead ghi disk liên tục.

**Ví dụ phù hợp**

- Cache danh mục sản phẩm.
- Cache config hệ thống có thể load lại.
- Leaderboard game có thể chấp nhận mất vài phút điểm mới.
- Redis dùng cho dữ liệu tạm, dữ liệu gốc nằm ở database khác.

**Không phù hợp**

- Lưu giao dịch tài chính.
- Lưu order chưa đồng bộ database.
- Lưu dữ liệu không thể tạo lại.

**Hướng xử lý**

- Dùng RDB cho backup định kỳ.
- Nếu data quan trọng, bật thêm AOF.
- Nếu Redis chỉ là cache, có thể tắt persistence hoặc chỉ bật RDB tùy yêu cầu restore.

## II. Nhóm câu hỏi về AOF

### 1. AOF ghi lại các write operations như thế nào để đảm bảo an toàn dữ liệu?

- `AOF` ghi lại các lệnh làm thay đổi dữ liệu, ví dụ `SET`, `HSET`, `INCR`, `DEL`.
- Redis append command vào AOF buffer.
- Sau đó Redis flush/fsync buffer xuống file `appendonly.aof` theo cấu hình.
- Khi Redis restart, Redis replay lại command trong AOF để dựng lại dữ liệu.

**Ưu điểm**

- An toàn dữ liệu hơn RDB.
- Có thể mất rất ít dữ liệu nếu dùng `appendfsync everysec`.
- File AOF là log command nên dễ hiểu hơn snapshot nhị phân.

**Nhược điểm**

- File thường lớn hơn RDB.
- Restore có thể chậm hơn vì phải replay command.
- Ghi disk thường xuyên hơn, có thể ảnh hưởng performance.

**Ví dụ thực tế**

- Redis lưu queue công việc tạm:
  - Worker push job vào Redis.
  - Nếu Redis crash, AOF giúp replay lại các lệnh push gần nhất.
  - Giảm khả năng mất job.

**Hướng xử lý**

- Production thường dùng `appendonly yes`.
- Cấu hình phổ biến: `appendfsync everysec`.
- Theo dõi disk latency và kích thước AOF.

### 2. Các chính sách fsync trong AOF ảnh hưởng thế nào đến performance và độ an toàn?

#### `appendfsync always`

- Redis fsync xuống disk sau mỗi lệnh ghi.

**Ưu điểm**

- An toàn dữ liệu cao nhất.
- Gần như không mất command đã xác nhận nếu disk hoạt động đúng.

**Nhược điểm**

- Chậm nhất.
- Disk I/O cao.
- Có thể làm latency tăng mạnh.

**Phù hợp**

- Dữ liệu cực kỳ quan trọng.
- Traffic ghi thấp.

#### `appendfsync everysec`

- Redis fsync khoảng mỗi giây một lần.

**Ưu điểm**

- Cân bằng tốt giữa an toàn và hiệu năng.
- Thường chỉ mất tối đa khoảng 1 giây dữ liệu nếu crash.
- Là lựa chọn phổ biến trong production.

**Nhược điểm**

- Vẫn có thể mất dữ liệu trong khoảng 1 giây cuối.
- Nếu disk chậm, vẫn có thể ảnh hưởng latency.

**Phù hợp**

- Phần lớn hệ thống backend cần Redis persistence.

#### `appendfsync no`

- Redis không chủ động fsync, để OS quyết định flush xuống disk.

**Ưu điểm**

- Nhanh nhất trong ba chế độ AOF.
- Ít overhead nhất.

**Nhược điểm**

- Rủi ro mất dữ liệu cao hơn.
- Phụ thuộc vào OS và disk cache.

**Phù hợp**

- Dữ liệu ít quan trọng.
- Muốn AOF nhưng ưu tiên performance.

**Hướng xử lý**

- Mặc định khuyến nghị production: `appendfsync everysec`.
- Nếu latency tăng, kiểm tra disk I/O, AOF rewrite, fsync delay.
- Không dùng `always` nếu workload ghi lớn mà chưa benchmark.

### 3. File AOF tăng rất lớn theo thời gian, Redis xử lý bằng Log Rewriting như thế nào?

- AOF lưu lịch sử command nên file có thể lớn dần.
- Redis dùng `AOF rewrite` để tạo file AOF mới gọn hơn.
- Rewrite không cần giữ toàn bộ lịch sử command.
- Redis chỉ ghi các command tối thiểu để tái tạo state hiện tại.

**Ví dụ**

- Lịch sử AOF cũ:
  - `INCR count`
  - `INCR count`
  - `INCR count`
  - `INCR count`
- Sau rewrite có thể thành:
  - `SET count 4`

**Cơ chế**

- Redis chạy `BGREWRITEAOF`.
- Fork child process tạo file AOF mới.
- Trong lúc rewrite, Redis vẫn nhận lệnh mới.
- Các lệnh mới được ghi vào buffer riêng.
- Khi rewrite xong, Redis nối phần command mới vào file mới rồi replace file cũ.

**Ưu điểm**

- Giảm kích thước AOF.
- Tăng tốc restore.
- Tránh disk bị đầy vì file log quá lớn.

**Nhược điểm**

- Rewrite cần CPU, RAM và disk I/O.
- Fork với dataset lớn có thể gây áp lực memory.
- Nếu disk yếu, rewrite có thể ảnh hưởng latency.

**Hướng xử lý**

- Cấu hình tự động:
  - `auto-aof-rewrite-percentage 100`
  - `auto-aof-rewrite-min-size 64mb`
- Theo dõi kích thước AOF.
- Đảm bảo disk còn đủ dung lượng cho file rewrite tạm.
- Chạy Redis trên disk nhanh nếu workload ghi nhiều.

### 4. So sánh thời gian khôi phục dữ liệu của AOF với RDB khi gặp sự cố

- RDB thường restore nhanh hơn vì load snapshot trực tiếp.
- AOF thường restore chậm hơn vì phải replay command.
- Nếu AOF đã rewrite gần đây, tốc độ restore sẽ tốt hơn.
- Nếu AOF rất lớn, restart Redis có thể mất nhiều thời gian.

**RDB**

- Ưu điểm:
  - Restore nhanh.
  - File nhỏ hơn.
- Nhược điểm:
  - Có thể mất dữ liệu sau snapshot cuối.

**AOF**

- Ưu điểm:
  - Dữ liệu đầy đủ hơn.
  - Ít mất dữ liệu hơn.
- Nhược điểm:
  - Restore chậm hơn.
  - File lớn hơn.

**Ví dụ thực tế**

- Redis cache 5GB:
  - RDB restore có thể nhanh vì chỉ load snapshot.
  - AOF nếu chứa hàng triệu command cũ sẽ replay lâu hơn.
- Redis queue quan trọng:
  - AOF đáng dùng hơn dù restore chậm, vì mất job là rủi ro lớn.

**Hướng xử lý**

- Bật AOF rewrite tự động.
- Kiểm tra thời gian restart trong môi trường staging.
- Nếu cần restart nhanh, kết hợp RDB preloading hoặc dùng AOF rewrite thường xuyên.

## III. Chiến lược kết hợp và thực tế production

### 1. Tại sao kết hợp RDB và AOF được xem là best practice trong production?

- RDB mạnh về snapshot và restore nhanh.
- AOF mạnh về giảm mất dữ liệu.
- Kết hợp cả hai giúp cân bằng:
  - RDB dùng cho backup định kỳ.
  - AOF dùng để replay các thay đổi gần nhất.

**Ưu điểm**

- An toàn hơn chỉ dùng RDB.
- Restore tốt hơn nếu AOF còn hợp lệ.
- Có snapshot để backup offline.
- Có command log để giảm data loss.

**Nhược điểm**

- Tốn thêm disk.
- Tăng cấu hình vận hành.
- Cần monitor cả RDB save và AOF rewrite/fsync.

**Ví dụ thực tế**

- Redis lưu session và cart:
  - RDB snapshot mỗi 5 hoặc 10 phút.
  - AOF `everysec`.
  - Nếu crash, mất tối đa khoảng 1 giây dữ liệu AOF thay vì mất vài phút như chỉ dùng RDB.

**Hướng xử lý**

- Production phổ biến:
  - `appendonly yes`
  - `appendfsync everysec`
  - Bật RDB snapshot theo nhu cầu.
- Backup file RDB/AOF ra storage ngoài máy chủ Redis.

### 2. Khi dùng Hybrid RDB + AOF, Redis ưu tiên dùng file nào khi khởi động lại?

- Khi bật AOF, Redis ưu tiên load từ AOF.
- Lý do:
  - AOF thường chứa dữ liệu mới hơn RDB.
  - AOF giúp giảm mất dữ liệu gần thời điểm crash.
- Nếu AOF không tồn tại hoặc bị tắt, Redis load từ RDB.

**Lưu ý phiên bản mới**

- Redis các phiên bản mới có thể dùng AOF dạng multi-part:
  - Base file có thể là RDB preamble.
  - Incremental file chứa command AOF.
- Nhưng về ý tưởng vận hành, khi AOF bật thì Redis ưu tiên cơ chế AOF để khôi phục dữ liệu mới nhất.

**Ưu điểm**

- Giảm data loss khi restart.
- Tận dụng log command mới nhất.

**Nhược điểm**

- Nếu AOF bị corrupt, Redis cần xử lý sửa file hoặc fallback.

**Hướng xử lý**

- Dùng công cụ `redis-check-aof` nếu AOF lỗi.
- Backup cả RDB và AOF.
- Monitor log Redis khi restart để biết Redis load từ file nào.

### 3. Ngoài RDB và AOF, tại sao Replication quan trọng cho High Availability?

- RDB và AOF giúp khôi phục dữ liệu sau restart hoặc crash.
- Replication giúp có bản sao Redis đang chạy ở node khác.
- Nếu master lỗi, replica có thể được promote thành master.
- Replication giảm downtime, còn persistence giảm data loss.

**Ưu điểm**

- Tăng tính sẵn sàng.
- Có thể đọc từ replica nếu hệ thống cho phép.
- Hỗ trợ failover với Sentinel hoặc Redis Cluster.
- Giảm thời gian phục hồi khi master chết.

**Nhược điểm**

- Replication là bất đồng bộ trong đa số trường hợp, vẫn có thể mất một phần dữ liệu mới nhất.
- Cần quản lý failover, split-brain, network partition.
- Tốn thêm tài nguyên server.

**Ví dụ thực tế**

- Hệ thống ecommerce dùng Redis cart:
  - Master nhận ghi cart.
  - Replica nhận dữ liệu replicate.
  - Sentinel giám sát master.
  - Nếu master down, Sentinel promote replica.

**Hướng xử lý**

- Dùng Redis Sentinel nếu cần HA cho Redis standalone.
- Dùng Redis Cluster nếu cần scale và sharding.
- Không xem replication là backup thay thế RDB/AOF.
- Vẫn cần backup file persistence ra storage ngoài.

### 4. Các yếu tố cần xem xét khi chọn backup frequency để cân bằng hiệu năng và rủi ro mất dữ liệu

- Mức độ quan trọng của dữ liệu.
- RPO: chấp nhận mất tối đa bao nhiêu dữ liệu.
- RTO: cần khôi phục nhanh trong bao lâu.
- Workload đọc/ghi.
- Kích thước dataset.
- RAM còn trống khi Redis fork.
- Tốc độ disk.
- Tần suất AOF rewrite.
- Redis có phải cache hay source of truth không.

**Nếu dữ liệu ít quan trọng**

- Có thể dùng RDB thưa hơn.
- Có thể không bật AOF.
- Ví dụ:
  - Cache danh mục sản phẩm.
  - Cache search result.

**Nếu dữ liệu quan trọng vừa phải**

- Dùng RDB + AOF `everysec`.
- Snapshot theo chu kỳ hợp lý.
- Ví dụ:
  - Session.
  - Cart.
  - Rate limit state.

**Nếu dữ liệu rất quan trọng**

- Không nên chỉ dựa vào Redis.
- Ghi dữ liệu chính vào database/event log bền vững.
- Redis chỉ nên là cache hoặc state phụ.
- Ví dụ:
  - Thanh toán.
  - Order.
  - Số dư ví.

**Hướng xử lý đề xuất**

- Với đa số production:
  - Bật AOF `everysec`.
  - Bật RDB snapshot để có backup định kỳ.
  - Theo dõi latency, disk I/O, memory, fork time.
  - Test restore định kỳ, không chỉ test backup.
- Với hệ thống lớn:
  - Kết hợp Redis replication.
  - Backup ra object storage.
  - Có runbook xử lý AOF corrupt, RDB lỗi, disk full, failover.

## Kết luận nhanh để trả lời phỏng vấn

- `RDB`:
  - Nhanh, file gọn, restore tốt.
  - Có thể mất dữ liệu sau snapshot cuối.
- `AOF`:
  - An toàn dữ liệu hơn, replay command khi restart.
  - File lớn hơn, restore có thể chậm hơn.
- `RDB + AOF`:
  - Phù hợp production hơn nếu Redis lưu dữ liệu quan trọng vừa phải.
  - Cần monitor disk, memory, rewrite và thời gian restore.
- `Replication`:
  - Dùng cho high availability.
  - Không thay thế backup/persistence.
