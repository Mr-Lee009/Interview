# 10 câu hỏi phỏng vấn hay về Microservice

Tài liệu này dùng để ôn phỏng vấn Java Backend / Senior Backend. Mỗi câu có ý chính cần trả lời, ví dụ thực tế và hướng xử lý khi gặp trong dự án.

## 1. Microservice là gì? Khi nào nên dùng Microservice?

- **Microservice** là kiến trúc chia hệ thống thành nhiều service nhỏ, mỗi service phụ trách một nghiệp vụ rõ ràng và có thể phát triển, deploy, scale độc lập.
- Mỗi service thường có:
  - Codebase riêng.
  - Database hoặc schema dữ liệu riêng.
  - API riêng để giao tiếp với service khác.
  - Pipeline deploy riêng.
- Nên dùng Microservice khi:
  - Hệ thống lớn, nhiều domain nghiệp vụ.
  - Nhiều team cùng phát triển song song.
  - Một số module cần scale riêng, ví dụ `payment`, `order`, `notification`.
  - Cần release độc lập, không muốn deploy cả hệ thống chỉ vì sửa một chức năng nhỏ.
- Không nên dùng Microservice khi:
  - Dự án còn nhỏ, nghiệp vụ chưa rõ.
  - Team ít người, chưa có kinh nghiệm vận hành distributed system.
  - Chưa có monitoring, logging, CI/CD, container hoặc cloud infrastructure.
- Ví dụ thực tế:
  - Website bán hàng ban đầu có thể dùng **Modular Monolith**.
  - Khi lượng đơn hàng lớn, có thể tách thành `Order Service`, `Payment Service`, `Inventory Service`, `Shipping Service`.

## 2. Monolith và Microservice khác nhau như thế nào?

| Tiêu chí | Monolith | Microservice |
|---|---|---|
| Cấu trúc | Một ứng dụng lớn | Nhiều service nhỏ |
| Deploy | Deploy toàn bộ app | Deploy từng service |
| Scale | Scale cả hệ thống | Scale riêng từng service |
| Database | Thường dùng chung DB | Mỗi service nên sở hữu dữ liệu riêng |
| Độ phức tạp vận hành | Thấp hơn | Cao hơn |
| Giao tiếp nội bộ | Gọi hàm trực tiếp | Gọi qua HTTP, gRPC, Kafka, RabbitMQ |
| Phù hợp | Dự án nhỏ/vừa, team nhỏ | Dự án lớn, nhiều team, traffic cao |

- Ưu điểm Monolith:
  - Dễ phát triển lúc đầu.
  - Dễ debug.
  - Transaction trong một DB đơn giản hơn.
- Nhược điểm Monolith:
  - Codebase lớn dễ rối.
  - Deploy chậm.
  - Khó scale riêng một module.
- Ưu điểm Microservice:
  - Tách trách nhiệm rõ.
  - Team làm việc độc lập hơn.
  - Scale theo từng nghiệp vụ.
- Nhược điểm Microservice:
  - Khó debug do request đi qua nhiều service.
  - Phát sinh vấn đề network, retry, timeout, transaction phân tán.
  - Cần observability tốt.

## 3. Thiết kế ranh giới service dựa vào đâu?

- Không nên tách service theo bảng database hoặc theo layer kỹ thuật như `controller`, `service`, `repository`.
- Nên tách theo **Business Capability**: năng lực nghiệp vụ độc lập.
- Có thể dùng **Domain-Driven Design / DDD**:
  - **Domain**: miền nghiệp vụ chính.
  - **Bounded Context**: phạm vi nghiệp vụ có ngôn ngữ và dữ liệu riêng.
  - **Aggregate**: cụm dữ liệu cần đảm bảo nhất quán cùng nhau.
- Ví dụ hệ thống gọi món:
  - `Restaurant Service`: quản lý nhà hàng, menu.
  - `Order Service`: tạo đơn, trạng thái đơn.
  - `Payment Service`: thanh toán.
  - `Delivery Service`: giao hàng.
  - `Notification Service`: gửi email/SMS/push.
- Dấu hiệu tách service hợp lý:
  - Service có nghiệp vụ rõ ràng.
  - Ít phụ thuộc dữ liệu trực tiếp vào service khác.
  - Có thể deploy riêng.
  - Có thể scale riêng.
- Dấu hiệu tách sai:
  - Service nào cũng gọi chéo nhau liên tục.
  - Một request đơn giản phải đi qua quá nhiều service.
  - Nhiều service cùng ghi vào một bảng DB.

## 4. Giao tiếp giữa các service nên dùng REST, gRPC hay Message Queue?

- **REST**: giao tiếp HTTP phổ biến, dễ debug, phù hợp public API hoặc request/response đơn giản.
- **gRPC**: giao tiếp hiệu năng cao, schema rõ bằng Protocol Buffers, phù hợp internal service cần tốc độ.
- **Message Queue / Event Streaming**: Kafka, RabbitMQ, Redis Stream; phù hợp xử lý bất đồng bộ.

| Trường hợp | Nên dùng |
|---|---|
| Frontend gọi backend | REST |
| Service cần gọi đồng bộ và cần kết quả ngay | REST hoặc gRPC |
| Xử lý đơn hàng, gửi email, cập nhật báo cáo | Kafka/RabbitMQ |
| Event có volume lớn, cần replay | Kafka |
| Task queue, xử lý job, routing linh hoạt | RabbitMQ |

- Ví dụ:
  - `Order Service` gọi `Payment Service` để tạo thanh toán: có thể dùng REST.
  - Sau khi thanh toán thành công, phát event `PaymentSucceeded`: dùng Kafka để `Order`, `Notification`, `Shipping` cùng xử lý.
- Hướng xử lý tốt:
  - Không lạm dụng gọi đồng bộ.
  - Các tác vụ không cần trả kết quả ngay nên đưa qua event.
  - Luôn có timeout, retry và idempotency.

## 5. Vì sao Microservice thường dùng Database per Service?

- **Database per Service** nghĩa là mỗi service sở hữu dữ liệu của nó, service khác không được truy cập trực tiếp DB đó.
- Lý do:
  - Giữ ownership rõ ràng.
  - Tránh coupling giữa các service.
  - Cho phép mỗi service chọn database phù hợp.
  - Deploy thay đổi schema ít ảnh hưởng service khác.
- Ví dụ:
  - `Order Service` sở hữu bảng `orders`, `order_items`.
  - `Payment Service` sở hữu bảng `payments`, `payment_transactions`.
  - `Inventory Service` sở hữu bảng `stocks`, `stock_movements`.
- Không nên:
  - `Payment Service` query trực tiếp bảng `orders`.
  - Nhiều service cùng update một bảng.
- Cách lấy dữ liệu service khác:
  - Gọi API.
  - Subscribe event.
  - Tạo read model riêng.
  - Dùng **CQRS**: tách mô hình ghi và mô hình đọc nếu cần tối ưu truy vấn.

## 6. Xử lý transaction phân tán trong Microservice như thế nào?

- Trong Monolith, transaction thường nằm trong một database nên có thể dùng ACID transaction.
- Trong Microservice, một nghiệp vụ có thể đi qua nhiều service và nhiều database, nên không nên phụ thuộc vào transaction DB truyền thống.
- Cách xử lý phổ biến:
  - **Saga Pattern**: chia transaction lớn thành nhiều bước nhỏ.
  - **Compensating Action**: hành động bù trừ khi một bước thất bại.
  - **Outbox Pattern**: ghi dữ liệu và event vào cùng DB transaction, sau đó publish event ra Kafka/RabbitMQ.
- Ví dụ đặt hàng:
  - `Order Service`: tạo order `PENDING`.
  - `Inventory Service`: giữ hàng.
  - `Payment Service`: thanh toán.
  - Nếu thanh toán fail, `Inventory Service` phải trả lại hàng.
- Có 2 kiểu Saga:
  - **Choreography**: các service tự lắng nghe event và phản ứng.
  - **Orchestration**: có một service điều phối luồng xử lý.
- Hướng trả lời phỏng vấn:
  - Không trả lời rằng dùng transaction xuyên nhiều DB là đủ.
  - Nên nói rõ: chấp nhận **Eventual Consistency**, nghĩa là dữ liệu nhất quán sau một khoảng thời gian ngắn.

## 7. API Gateway và Service Discovery dùng để làm gì?

- **API Gateway** là cổng vào chung của hệ thống.
- API Gateway thường xử lý:
  - Routing request đến service phù hợp.
  - Authentication / Authorization.
  - Rate limiting.
  - Logging.
  - Request/response transformation.
  - Versioning API.
- **Service Discovery** là cơ chế để các service tìm được địa chỉ của nhau.
- Vì trong Microservice, instance có thể scale up/down liên tục, IP không cố định.
- Công cụ thường gặp:
  - Spring Cloud Gateway.
  - Netflix Eureka.
  - Consul.
  - Kubernetes Service DNS.
- Ví dụ:
  - Client gọi `/api/orders`.
  - API Gateway route sang `Order Service`.
  - `Order Service` gọi `Payment Service` thông qua service name thay vì hard-code IP.

## 8. Làm sao tránh lỗi dây chuyền khi một service bị chậm hoặc chết?

- Lỗi dây chuyền gọi là **Cascading Failure**: một service chậm làm các service khác chờ, dẫn đến cả hệ thống bị nghẽn.
- Cần các kỹ thuật sau:
  - **Timeout**: không chờ vô hạn.
  - **Retry**: thử lại khi lỗi tạm thời.
  - **Circuit Breaker**: tạm ngắt gọi service đang lỗi để bảo vệ hệ thống.
  - **Bulkhead**: chia tài nguyên, tránh một luồng lỗi chiếm hết thread/connection.
  - **Fallback**: trả dữ liệu mặc định hoặc phản hồi giảm cấp.
  - **Rate Limiting**: giới hạn request.
- Ví dụ:
  - `Product Service` gọi `Review Service` để lấy đánh giá sản phẩm.
  - Nếu `Review Service` chậm, không nên làm trang sản phẩm chết.
  - Có thể fallback: hiển thị sản phẩm nhưng ẩn phần review.
- Với Spring Boot:
  - Có thể dùng Resilience4j cho timeout, retry, circuit breaker.

## 9. Observability trong Microservice gồm những gì?

- **Observability** là khả năng quan sát hệ thống để biết chuyện gì đang xảy ra bên trong.
- Ba phần quan trọng:
  - **Logging**: log chi tiết theo request.
  - **Metrics**: số liệu như request count, latency, error rate, CPU, memory.
  - **Tracing**: theo dõi một request đi qua nhiều service.
- Cần có:
  - **Correlation ID / Trace ID**: mã theo dõi request xuyên suốt hệ thống.
  - Dashboard theo dõi latency, error rate, throughput.
  - Alert khi lỗi vượt ngưỡng.
- Công cụ thường gặp:
  - ELK / EFK: Elasticsearch, Logstash/Fluentd, Kibana.
  - Prometheus + Grafana.
  - OpenTelemetry.
  - Jaeger / Zipkin.
- Ví dụ:
  - User báo thanh toán lỗi.
  - Dựa vào `traceId`, kiểm tra request từ `API Gateway` -> `Order Service` -> `Payment Service` -> `MoMo/VNPay/ZaloPay`.

## 10. Những lỗi thực tế hay gặp trong Microservice và cách xử lý?

| Vấn đề | Nguyên nhân | Hướng xử lý |
|---|---|---|
| Duplicate Message | Consumer retry hoặc broker gửi lại message | Thiết kế idempotency, lưu `eventId` đã xử lý |
| Message Loss | Commit offset sai, publish event không an toàn | Dùng ack đúng, Outbox Pattern, DLQ |
| Consumer Lag | Consumer xử lý chậm hơn tốc độ message vào | Scale consumer, tăng partition, tối ưu xử lý |
| Hot Partition | Quá nhiều message vào một partition | Chọn partition key tốt hơn |
| Cascading Failure | Service chậm kéo theo service khác | Timeout, circuit breaker, bulkhead |
| Data Inconsistency | Eventual consistency chưa hoàn tất | Saga, retry, reconciliation job |
| API Version Conflict | Client/service dùng version khác nhau | Versioning API, backward compatibility |
| Rebalance Storm | Consumer group thay đổi liên tục | Tối ưu heartbeat, session timeout, scale hợp lý |
| Shared Database Coupling | Nhiều service phụ thuộc chung DB | Database per service, public API/event |
| Debug khó | Request đi qua nhiều service | Tracing, correlationId, centralized logging |

- Ví dụ thực tế:
  - `PaymentSucceeded` bị gửi lại 2 lần.
  - Nếu `Order Service` không idempotent, đơn hàng có thể bị cập nhật hoặc gửi thông báo nhiều lần.
  - Cách xử lý:
    - Mỗi event có `eventId`.
    - Lưu bảng `processed_events`.
    - Nếu event đã xử lý thì bỏ qua.

## Gợi ý trả lời phỏng vấn Senior

- Không chỉ nói Microservice là "chia nhỏ service".
- Nên nhấn mạnh trade-off:
  - Dễ scale và deploy độc lập hơn.
  - Nhưng vận hành khó hơn Monolith.
  - Phải xử lý network failure, consistency, observability, retry, idempotency.
- Câu trả lời tốt thường có cấu trúc:
  - Bối cảnh bài toán.
  - Vì sao chọn Microservice hoặc không chọn.
  - Thiết kế service boundary.
  - Cách giao tiếp.
  - Cách đảm bảo dữ liệu.
  - Cách vận hành và debug production.
