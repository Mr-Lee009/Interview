# Kafka benchmark

## Thành phần

- `kafka-1`, `kafka-2`, `kafka-3`: Kafka broker chạy KRaft mode.
- `kafka-ui`: giao diện xem topic, partition, consumer group.
- Topic test mặc định: `mq-benchmark`.

## Chạy hệ thống

```powershell
docker compose up -d
```

Mở Kafka UI:

```text
http://localhost:8085
```

## Tạo topic

```powershell
.\scripts\create-topic.ps1
```

## Test producer

```powershell
.\scripts\benchmark-producer.ps1
```

## Test consumer

```powershell
.\scripts\benchmark-consumer.ps1
```

## Thử message size khác

```powershell
.\scripts\benchmark-producer.ps1 -RecordSize 1024
.\scripts\benchmark-producer.ps1 -RecordSize 10240
.\scripts\benchmark-producer.ps1 -RecordSize 102400
.\scripts\benchmark-producer.ps1 -RecordSize 1048576
```

## Cấu hình message lớn

Docker compose đang cấu hình broker cho phép message khoảng 10 MB:

- `KAFKA_MESSAGE_MAX_BYTES=10485760`
- `KAFKA_REPLICA_FETCH_MAX_BYTES=10485760`

Khi test message lớn, producer script cũng truyền:

- `max.request.size=10485760`
- `batch.size=65536`
- `compression.type=lz4`

Production không nên gửi message quá lớn qua Kafka. Với file lớn, lưu file ở object storage rồi gửi reference qua Kafka.
