# Redis Docker Config: RDB, AOF, và Hybrid

Tài liệu này hướng dẫn cấu hình Redis persistence bằng Docker cho 3 case:

- Chỉ dùng `RDB`.
- Chỉ dùng `AOF`.
- Kết hợp `RDB + AOF`.

Góc nhìn leader: team cần hiểu rõ mục tiêu từng cấu hình, tradeoff, cách chạy, cách kiểm tra file backup, và khi nào nên dùng trong môi trường thật.

## Quy ước chung cho team

- Không lưu dữ liệu Redis bên trong container nếu cần persistence.
- Luôn mount volume ra host hoặc Docker volume.
- Không dùng cấu hình persistence mặc định mà không hiểu rõ RPO/RTO.
- Với production, ưu tiên `AOF everysec + RDB snapshot` nếu Redis lưu dữ liệu quan trọng vừa phải.
- Nếu Redis chỉ là cache có thể rebuild từ database, RDB hoặc thậm chí tắt persistence có thể đủ.

## Cấu trúc thư mục đề xuất

```text
redis-persistence/
  rdb-only/
    docker-compose.yml
    redis.conf
    data/
  aof-only/
    docker-compose.yml
    redis.conf
    data/
  hybrid/
    docker-compose.yml
    redis.conf
    data/
```

Ghi chú:

- `redis.conf`: file cấu hình Redis cho từng case.
- `data/`: thư mục chứa `dump.rdb`, `appendonly.aof`, hoặc thư mục AOF multi-part tùy phiên bản Redis.
- Khi chạy thực tế, `data/` nên được backup hoặc mount vào volume ổn định.

## Case 1: Chỉ dùng RDB

### Khi nào dùng?

- Redis chủ yếu là cache.
- Có thể chấp nhận mất dữ liệu từ lần snapshot cuối.
- Cần file backup nhỏ, dễ copy.
- Muốn Redis ít ghi disk trong quá trình chạy.

### Ưu điểm

- Runtime overhead thấp hơn AOF.
- File `dump.rdb` thường nhỏ.
- Restore nhanh.
- Phù hợp backup định kỳ.

### Nhược điểm

- Có thể mất dữ liệu nếu crash trước lần snapshot tiếp theo.
- `BGSAVE` cần `fork`, có thể tốn RAM tạm thời với dataset lớn.
- Không phù hợp nếu dữ liệu không được phép mất.

### `rdb-only/docker-compose.yml`

```yaml
services:
  redis-rdb:
    image: redis:7.2
    container_name: redis-rdb-only
    restart: unless-stopped

    # Dùng redis.conf riêng để team kiểm soát rõ persistence.
    command: ["redis-server", "/usr/local/etc/redis/redis.conf"]

    ports:
      - "6379:6379"

    volumes:
      # Mount config vào container ở chế độ read-only.
      - ./redis.conf:/usr/local/etc/redis/redis.conf:ro

      # Mount data để dump.rdb không mất khi container bị xóa.
      - ./data:/data
```

### `rdb-only/redis.conf`

```conf
# Redis lắng nghe mọi interface trong container.
# Nếu chạy production, cần bảo vệ bằng network/firewall/security group.
bind 0.0.0.0

# Port mặc định.
port 6379

# Không bật protected-mode khi chạy trong Docker network riêng.
# Nếu expose public internet thì tuyệt đối không dùng cấu hình này.
protected-mode no

# Thư mục Redis ghi file persistence.
# Docker compose đã mount ./data vào /data.
dir /data

# Tên file snapshot RDB.
dbfilename dump.rdb

# Chỉ dùng RDB, nên tắt AOF.
appendonly no

# Tạo snapshot nếu trong 900 giây có ít nhất 1 thay đổi.
# Phù hợp dữ liệu ít thay đổi nhưng vẫn muốn backup định kỳ.
save 900 1

# Tạo snapshot nếu trong 300 giây có ít nhất 10 thay đổi.
# Đây là rule cân bằng cho workload vừa.
save 300 10

# Tạo snapshot nếu trong 60 giây có ít nhất 10000 thay đổi.
# Bảo vệ trường hợp workload ghi tăng mạnh.
save 60 10000

# Nếu Redis không ghi được RDB, dừng nhận write để tránh team tưởng dữ liệu vẫn được backup.
stop-writes-on-bgsave-error yes

# Nén RDB để giảm dung lượng file.
# Đổi lại tốn thêm CPU khi save/load.
rdbcompression yes

# Checksum giúp phát hiện file RDB lỗi.
# Nên bật trong production.
rdbchecksum yes
```

### Cách chạy

```bash
cd rdb-only
docker compose up -d
```

### Cách kiểm tra

```bash
docker exec -it redis-rdb-only redis-cli SET user:1 "Alice"
docker exec -it redis-rdb-only redis-cli BGSAVE
ls -lah data
```

Kỳ vọng:

- Thấy file `data/dump.rdb`.
- Restart container vẫn load lại dữ liệu từ RDB.

```bash
docker restart redis-rdb-only
docker exec -it redis-rdb-only redis-cli GET user:1
```

## Case 2: Chỉ dùng AOF

### Khi nào dùng?

- Cần giảm rủi ro mất dữ liệu so với RDB.
- Redis lưu dữ liệu runtime quan trọng hơn cache thông thường.
- Chấp nhận file lớn hơn và restore có thể chậm hơn.

### Ưu điểm

- An toàn dữ liệu tốt hơn RDB.
- Với `appendfsync everysec`, thường chỉ mất tối đa khoảng 1 giây dữ liệu khi crash.
- Có thể replay command để khôi phục state.

### Nhược điểm

- Ghi disk thường xuyên hơn.
- File AOF có thể lớn dần.
- Restore chậm hơn RDB nếu AOF lớn.
- Cần quản lý AOF rewrite.

### `aof-only/docker-compose.yml`

```yaml
services:
  redis-aof:
    image: redis:7.2
    container_name: redis-aof-only
    restart: unless-stopped
    command: ["redis-server", "/usr/local/etc/redis/redis.conf"]

    ports:
      - "6380:6379"

    volumes:
      - ./redis.conf:/usr/local/etc/redis/redis.conf:ro
      - ./data:/data
```

Ghi chú:

- Host port dùng `6380` để có thể chạy song song với case RDB.
- Trong container Redis vẫn chạy port `6379`.

### `aof-only/redis.conf`

```conf
bind 0.0.0.0
port 6379
protected-mode no
dir /data

# Chỉ dùng AOF, nên tắt RDB snapshot tự động.
# Dòng save rỗng nghĩa là disable RDB schedule.
save ""

# Bật AOF persistence.
appendonly yes

# Tên file AOF base.
# Redis 7 có thể tạo thêm thư mục appendonlydir và file manifest.
appendfilename "appendonly.aof"

# Chính sách fsync khuyến nghị cho production phổ biến.
# Cân bằng giữa performance và data safety.
appendfsync everysec

# Không fsync trong lúc AOF rewrite để giảm latency spike.
# Tradeoff: nếu crash đúng lúc rewrite, có thể tăng rủi ro mất một phần dữ liệu gần nhất.
no-appendfsync-on-rewrite no

# Tự động rewrite khi AOF tăng 100% so với lần rewrite trước.
auto-aof-rewrite-percentage 100

# Chỉ rewrite khi AOF đạt ít nhất 64MB để tránh rewrite quá thường xuyên.
auto-aof-rewrite-min-size 64mb

# Nếu AOF cuối file bị lỗi do crash, Redis cố truncate phần lỗi để khởi động.
# Nên bật để tăng khả năng recover.
aof-load-truncated yes

# Redis sẽ cố đồng bộ AOF rewrite an toàn hơn.
aof-use-rdb-preamble yes
```

### Cách chạy

```bash
cd aof-only
docker compose up -d
```

### Cách kiểm tra

```bash
docker exec -it redis-aof-only redis-cli SET order:1001 "created"
docker exec -it redis-aof-only redis-cli INCR order_count
ls -lah data
```

Kỳ vọng:

- Redis 7 thường tạo `data/appendonlydir/`.
- Có thể thấy file AOF manifest/base/incremental trong thư mục đó.

Kiểm tra restore:

```bash
docker restart redis-aof-only
docker exec -it redis-aof-only redis-cli GET order:1001
docker exec -it redis-aof-only redis-cli GET order_count
```

### Khi nào dùng `appendfsync always`?

- Chỉ dùng khi dữ liệu rất quan trọng và workload ghi thấp.
- Cần benchmark trước khi áp dụng.

```conf
appendfsync always
```

### Khi nào dùng `appendfsync no`?

- Khi ưu tiên throughput hơn durability.
- Không khuyến nghị cho dữ liệu quan trọng.

```conf
appendfsync no
```

## Case 3: Kết hợp RDB + AOF

### Khi nào dùng?

- Đây là cấu hình khuyến nghị cho đa số production nếu Redis có dữ liệu cần giữ.
- Cần snapshot định kỳ và command log gần realtime.
- Muốn giảm data loss nhưng vẫn có file snapshot để backup.

### Ưu điểm

- AOF giảm rủi ro mất dữ liệu gần thời điểm crash.
- RDB hữu ích cho backup định kỳ và disaster recovery.
- Khi AOF bật, Redis ưu tiên load AOF vì thường mới hơn RDB.
- Có thể copy RDB ra remote storage để backup dài hạn.

### Nhược điểm

- Tốn disk hơn.
- Cần monitor cả `BGSAVE`, `AOF fsync`, và `AOF rewrite`.
- Vận hành phức tạp hơn hai case đơn lẻ.

### `hybrid/docker-compose.yml`

```yaml
services:
  redis-hybrid:
    image: redis:7.2
    container_name: redis-hybrid
    restart: unless-stopped
    command: ["redis-server", "/usr/local/etc/redis/redis.conf"]

    ports:
      - "6381:6379"

    volumes:
      - ./redis.conf:/usr/local/etc/redis/redis.conf:ro
      - ./data:/data
```

### `hybrid/redis.conf`

```conf
bind 0.0.0.0
port 6379
protected-mode no
dir /data

# RDB snapshot file.
dbfilename dump.rdb

# Bật RDB để có snapshot định kỳ.
# Rule nên điều chỉnh theo RPO/RTO và workload thực tế.
save 900 1
save 300 10
save 60 10000

# Nếu snapshot lỗi, dừng write để tránh hiểu nhầm dữ liệu vẫn đang được backup đầy đủ.
stop-writes-on-bgsave-error yes

# Nén và checksum RDB.
rdbcompression yes
rdbchecksum yes

# Bật AOF để giảm data loss gần thời điểm crash.
appendonly yes
appendfilename "appendonly.aof"

# Khuyến nghị production phổ biến.
appendfsync everysec

# Giữ no để fsync vẫn diễn ra trong rewrite.
# Nếu latency rewrite quá cao, team có thể cân nhắc yes sau khi benchmark.
no-appendfsync-on-rewrite no

# Tự động rewrite AOF để tránh file tăng vô hạn.
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb

# Cho phép Redis xử lý AOF bị truncate ở cuối do crash.
aof-load-truncated yes

# Dùng RDB preamble trong AOF rewrite để load nhanh hơn.
# Đây là lựa chọn tốt cho Redis version mới.
aof-use-rdb-preamble yes
```

### Cách chạy

```bash
cd hybrid
docker compose up -d
```

### Cách kiểm tra

```bash
docker exec -it redis-hybrid redis-cli SET cart:42 "pending"
docker exec -it redis-hybrid redis-cli BGSAVE
ls -lah data
```

Kỳ vọng:

- Có `dump.rdb`.
- Có AOF files hoặc `appendonlydir` tùy Redis version.

Restart và kiểm tra:

```bash
docker restart redis-hybrid
docker exec -it redis-hybrid redis-cli GET cart:42
```

## So sánh nhanh để chọn cấu hình

| Case | Nên dùng khi | Ưu điểm | Nhược điểm |
|---|---|---|---|
| Chỉ RDB | Cache, dữ liệu có thể tạo lại | Ít overhead, restore nhanh, file nhỏ | Có thể mất dữ liệu sau snapshot cuối |
| Chỉ AOF | Cần ít mất dữ liệu hơn RDB | Durability tốt hơn, replay command | File lớn, restore chậm hơn, ghi disk nhiều |
| RDB + AOF | Production phổ biến | Cân bằng backup và durability | Cần monitor nhiều hơn, tốn disk hơn |

## Khuyến nghị leader cho team

- Dev/local:
  - Dùng RDB hoặc hybrid để team hiểu persistence.
  - Không cần tối ưu quá sâu.
- Staging:
  - Dùng cấu hình giống production.
  - Test restart, restore, disk full, AOF rewrite.
- Production cache thông thường:
  - RDB là đủ nếu cache có thể rebuild.
  - Có thể bật hybrid nếu session/cart cần giữ.
- Production có dữ liệu quan trọng vừa phải:
  - Dùng hybrid.
  - `appendfsync everysec`.
  - Backup RDB/AOF ra storage ngoài.
- Dữ liệu cực kỳ quan trọng:
  - Không để Redis là source of truth duy nhất.
  - Ghi database/event log bền vững trước.
  - Redis chỉ làm cache, queue phụ, hoặc state tạm.

## Checklist vận hành

- Có mount `/data` ra host hoặc volume ổn định.
- Có monitor:
  - Redis memory.
  - Disk usage.
  - Disk latency.
  - `rdb_bgsave_in_progress`.
  - `rdb_last_bgsave_status`.
  - `aof_enabled`.
  - `aof_rewrite_in_progress`.
  - `aof_last_bgrewrite_status`.
- Có cảnh báo khi disk gần đầy.
- Có test restore định kỳ.
- Có backup file persistence ra ngoài máy Redis.
- Có runbook xử lý:
  - Redis restart không lên.
  - AOF corrupt.
  - RDB save fail.
  - Disk full.
  - Replica lag hoặc failover.

## Lệnh kiểm tra trạng thái persistence

```bash
docker exec -it redis-hybrid redis-cli INFO persistence
```

Các field nên chú ý:

- `rdb_last_bgsave_status`
- `rdb_last_save_time`
- `rdb_bgsave_in_progress`
- `aof_enabled`
- `aof_rewrite_in_progress`
- `aof_last_bgrewrite_status`
- `aof_last_write_status`

## Ghi chú bảo mật

- Các ví dụ trên dùng `protected-mode no` để đơn giản khi chạy Docker local.
- Không expose Redis trực tiếp ra internet.
- Production nên:
  - Đặt Redis trong private network.
  - Dùng firewall/security group.
  - Bật authentication nếu cần.
  - Không publish port Redis ra public.
