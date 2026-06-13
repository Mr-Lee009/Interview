# RabbitMQ benchmark

## Thành phần

- `rabbitmq-1`, `rabbitmq-2`, `rabbitmq-3`: RabbitMQ node chạy management plugin.
- Cluster dùng static discovery qua `rabbitmq.conf`.
- Queue benchmark nên dùng Quorum Queue để có replication.

## Chạy hệ thống

```powershell
docker compose up -d
```

Mở RabbitMQ Management UI:

```text
http://localhost:15672
User: admin
Password: admin123
```

## Tạo quorum queue và policy

```powershell
.\scripts\setup-quorum-queue.ps1
```

## Chạy benchmark

```powershell
.\scripts\benchmark-perftest.ps1
```

## Thử message size khác

```powershell
.\scripts\benchmark-perftest.ps1 -Size 1024
.\scripts\benchmark-perftest.ps1 -Size 10240
.\scripts\benchmark-perftest.ps1 -Size 102400
.\scripts\benchmark-perftest.ps1 -Size 1048576
```

## Cấu hình message lớn

`config/rabbitmq.conf` đang đặt:

```text
max_message_size = 67108864
```

Tức là 64 MB/message cho môi trường test. RabbitMQ 4.x mặc định 16 MB và max 512 MB, nhưng production không nên đẩy message quá lớn qua queue.
