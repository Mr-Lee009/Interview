param(
    [string]$Topic = "mq-benchmark",
    [int]$Messages = 100000,
    [string]$Group = "mq-benchmark-consumer"
)

docker exec mqtest-kafka-1 /opt/kafka/bin/kafka-consumer-perf-test.sh `
  --bootstrap-server kafka-1:9092,kafka-2:9092,kafka-3:9092 `
  --topic $Topic `
  --messages $Messages `
  --group $Group `
  --consumer.config /opt/kafka/config/consumer.properties
