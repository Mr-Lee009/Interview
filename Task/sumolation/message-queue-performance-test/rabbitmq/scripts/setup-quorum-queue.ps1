param(
    [string]$Queue = "mq-benchmark"
)

docker exec mqtest-rabbitmq-1 rabbitmqctl await_startup

# Policy áp dụng cho queue benchmark: tạo quorum queue có replication giữa các node.
docker exec mqtest-rabbitmq-1 rabbitmqctl set_policy benchmark-quorum "^$Queue$" `
  '{"queue-type":"quorum"}' `
  --apply-to queues

# Tạo queue bằng rabbitmqadmin có sẵn trong management image.
docker exec mqtest-rabbitmq-1 rabbitmqadmin `
  --username=admin `
  --password=admin123 `
  declare queue `
  name=$Queue `
  durable=true `
  arguments='{"x-queue-type":"quorum"}'

docker exec mqtest-rabbitmq-1 rabbitmqctl list_queues name type durable messages
