param(
    [string]$Queue = "mq-benchmark",
    [int]$Producers = 3,
    [int]$Consumers = 3,
    [int]$Size = 10240,
    [int]$Time = 300
)

docker run --rm `
  --network rabbitmq-benchmark-net `
  pivotalrabbitmq/perf-test:latest `
  --uri amqp://admin:admin123@rabbitmq-1:5672/%2f `
  --queue $Queue `
  --queue-args x-queue-type=quorum `
  --producers $Producers `
  --consumers $Consumers `
  --size $Size `
  --time $Time `
  --auto-delete false `
  --confirm 1 `
  --qos 100
