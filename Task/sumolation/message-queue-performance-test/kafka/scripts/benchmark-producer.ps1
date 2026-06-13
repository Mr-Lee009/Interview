param(
    [string]$Topic = "mq-benchmark",
    [int]$Records = 100000,
    [int]$RecordSize = 10240,
    [int]$Throughput = -1
)

docker exec mqtest-kafka-1 /opt/kafka/bin/kafka-producer-perf-test.sh `
  --topic $Topic `
  --num-records $Records `
  --record-size $RecordSize `
  --throughput $Throughput `
  --producer-props `
    bootstrap.servers=kafka-1:9092,kafka-2:9092,kafka-3:9092 `
    acks=all `
    linger.ms=10 `
    batch.size=65536 `
    compression.type=lz4 `
    max.request.size=10485760
