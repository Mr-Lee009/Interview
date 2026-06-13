param(
    [string]$Topic = "mq-benchmark",
    [int]$Partitions = 6,
    [int]$ReplicationFactor = 3
)

docker exec mqtest-kafka-1 /opt/kafka/bin/kafka-topics.sh `
  --bootstrap-server kafka-1:9092,kafka-2:9092,kafka-3:9092 `
  --create `
  --if-not-exists `
  --topic $Topic `
  --partitions $Partitions `
  --replication-factor $ReplicationFactor `
  --config max.message.bytes=10485760

docker exec mqtest-kafka-1 /opt/kafka/bin/kafka-topics.sh `
  --bootstrap-server kafka-1:9092,kafka-2:9092,kafka-3:9092 `
  --describe `
  --topic $Topic
