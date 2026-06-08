# Redis Master/Replica RDB bằng Docker Compose

## 1. Có thể tách command Redis ra file khác không?

Có. Nên tách.

Thay vì viết toàn bộ option trong `docker-compose.yml`:

```yaml
command:
  ["redis-server", "--requirepass", "...", "--save", "900", "1"]
```

Ta tách ra file config:

```text
config/
  redis-master.conf
  redis-replica.conf
```

Sau đó compose chỉ cần:

```yaml
command: ["redis-server", "/etc/redis/redis.conf"]
```

Lợi ích:

- `docker-compose.yml` gọn hơn.
- Config Redis dễ đọc hơn.
- Có thể comment từng dòng cấu hình bằng tiếng Việt.
- Dễ copy config sang server khác.
- Dễ versioning và review thay đổi.

## 2. Cấu trúc thư mục

```text
redis-config-master-slave/
  docker-compose.yml
  README.md
  index.html
  config/
    redis-master.conf
    redis-replica.conf
  data/
    master/
    replica-1/
    replica-2/
```

`data/` sẽ được Docker tạo khi chạy compose.

## 3. Chạy hệ thống

```bash
docker compose up -d
```

## 4. Kiểm tra replication

```bash
docker exec -it redis-master redis-cli -a redis_password INFO replication
docker exec -it redis-replica-1 redis-cli -a redis_password INFO replication
docker exec -it redis-replica-2 redis-cli -a redis_password INFO replication
```

Master nên thấy:

```text
role:master
connected_slaves:2
```

Replica nên thấy:

```text
role:slave
master_host:redis-master
master_link_status:up
```

## 5. Test ghi dữ liệu

Ghi vào master:

```bash
docker exec -it redis-master redis-cli -a redis_password SET user:1 "Alice"
```

Đọc từ replica:

```bash
docker exec -it redis-replica-1 redis-cli -a redis_password GET user:1
```

## 6. Tạo RDB snapshot thủ công

```bash
docker exec -it redis-master redis-cli -a redis_password BGSAVE
```

File RDB sẽ nằm ở:

```text
data/master/dump.rdb
```

## 7. Lưu ý production

- Không để password plaintext trong file config.
- Nên dùng Docker Secret, Kubernetes Secret hoặc Vault.
- Nếu cần failover tự động, cần thêm Redis Sentinel hoặc Redis Cluster.
- RDB có thể mất dữ liệu từ lần snapshot cuối tới lúc crash.
- Nếu cần durability cao hơn, cân nhắc bật thêm AOF hoặc dùng hybrid persistence.

