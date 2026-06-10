# Case Study: Kiểm tra giao dịch nghi ngờ bằng Kafka

Tài liệu này mô tả cách ứng dụng Kafka để xây dựng hệ thống phát hiện giao dịch nghi ngờ trong ngân hàng.

Mục tiêu:

- Nhận giao dịch realtime từ hệ thống core banking/payment.
- Đánh giá rủi ro theo rule, velocity, blacklist, device, location.
- Gửi cảnh báo tới Fraud Operation team.
- Có khả năng block/hold giao dịch nghi ngờ.
- Không làm chậm luồng giao dịch chính quá mức.
- Lưu audit trail để điều tra và phục vụ compliance.

## 1. Bài toán

Khi khách hàng thực hiện giao dịch, hệ thống cần kiểm tra:

- Số tiền có bất thường không?
- Tài khoản nhận có nằm trong blacklist không?
- Thiết bị/IP/location có khác thường không?
- Một tài khoản có giao dịch quá nhiều trong thời gian ngắn không?
- Có nhiều giao dịch nhỏ liên tiếp để né ngưỡng không?
- Giao dịch có pattern giống fraud đã biết không?

Ví dụ:

```text
User A thường chuyển 1-2 triệu/ngày.
Đột nhiên trong 2 phút chuyển 10 lần, mỗi lần 49 triệu tới nhiều tài khoản lạ.
Hệ thống phải phát hiện và cảnh báo gần realtime.
```

## 2. Vì sao dùng Kafka?

Kafka phù hợp vì:

- Giao dịch ngân hàng là event stream lớn.
- Nhiều service cần đọc cùng một event:
  - Fraud Detection.
  - Notification.
  - Audit.
  - Data Lake.
  - Reporting.
- Kafka lưu event theo retention nên có thể replay để điều tra.
- Consumer group giúp scale xử lý realtime.
- Partition key giúp giữ thứ tự event theo account/customer.

Không nên dùng Kafka để thay thế transaction database của core banking. Kafka ở đây là lớp event streaming và xử lý bất đồng bộ/realtime.

## 3. Kiến trúc tổng quan

```text
Channel/API/Core Banking
  -> Transaction Service
  -> Kafka topic: transaction.created
  -> Fraud Detection Service
       -> Rule Engine
       -> Velocity Check
       -> Blacklist Check
       -> ML Risk Scoring
  -> Kafka topic: fraud.alert.created
  -> Case Management Service
  -> Notification Service
  -> Audit/Data Lake
```

## 4. Các thành phần trong hệ thống

| Thành phần | Loại | Chức năng |
|---|---|---|
| Mobile/Web/ATM/POS | Channel | Nơi phát sinh giao dịch từ khách hàng |
| API Gateway | Entry point | Nhận request, auth, rate limit, route vào backend |
| Transaction Service | Service nghiệp vụ | Tạo giao dịch, validate cơ bản, ghi DB, publish event |
| Transaction DB | Database | Lưu trạng thái giao dịch chính thức |
| Kafka Cluster | Event streaming | Lưu và phân phối event giao dịch |
| `transaction.created` | Topic | Chứa event giao dịch mới phát sinh |
| Fraud Detection Service | Consumer service | Consume transaction event để đánh giá rủi ro |
| Rule Engine | Component | Áp rule nghiệp vụ: amount threshold, country, merchant, time |
| Velocity Check Service | Component/Service | Kiểm tra tần suất giao dịch theo time window |
| Blacklist Service | Service/Cache | Check account, card, phone, device, IP có trong blacklist không |
| Profile Service | Service/Read model | Lấy lịch sử hành vi bình thường của customer |
| ML Risk Scoring Service | Service | Tính risk score bằng model hoặc heuristic |
| Fraud Decision Service | Component | Tổng hợp kết quả và quyết định ALLOW/HOLD/BLOCK/REVIEW |
| `fraud.alert.created` | Topic | Chứa alert giao dịch nghi ngờ |
| Case Management Service | Service | Tạo case cho đội vận hành kiểm tra |
| Notification Service | Service | Gửi SMS/email/push cho khách hàng hoặc nhân viên |
| Audit Service | Service | Lưu toàn bộ event/payload phục vụ điều tra |
| Data Lake/SIEM | Analytics/Security | Lưu dài hạn, phân tích, dashboard, compliance |
| DLQ topic | Topic lỗi | Lưu message lỗi sau retry để không block consumer chính |
| Monitoring | Observability | Theo dõi lag, throughput, error rate, alert rate |

## 5. Topic Kafka đề xuất

| Topic | Producer | Consumer | Partition key | Mục đích |
|---|---|---|---|---|
| `transaction.created` | Transaction Service | Fraud Detection, Audit, Data Lake | `accountId` hoặc `customerId` | Giao dịch mới phát sinh |
| `transaction.status.changed` | Transaction Service/Fraud Decision | Notification, Audit | `transactionId` | Trạng thái giao dịch thay đổi |
| `fraud.alert.created` | Fraud Detection | Case Management, Notification, Audit | `alertId` hoặc `accountId` | Alert giao dịch nghi ngờ |
| `fraud.decision.created` | Fraud Decision Service | Transaction Service, Audit | `transactionId` | Quyết định ALLOW/HOLD/BLOCK |
| `fraud.retry` | Error Handler | Fraud Detection retry consumer | Theo event gốc | Retry message lỗi tạm thời |
| `fraud.dlq` | Error Handler | Operation/Replay Tool | Theo event gốc | Message lỗi sau retry |

## 6. Event mẫu

### 6.1 TransactionCreatedEvent

```json
{
  "eventId": "evt-20260610-000001",
  "eventType": "TRANSACTION_CREATED",
  "occurredAt": "2026-06-10T10:15:30+07:00",
  "transactionId": "txn-100001",
  "accountId": "acc-9001",
  "customerId": "cus-7001",
  "amount": 49000000,
  "currency": "VND",
  "channel": "MOBILE",
  "fromAccount": "0011009001",
  "toAccount": "0099887766",
  "toBankCode": "BANK_B",
  "deviceId": "device-abc",
  "ipAddress": "203.0.113.10",
  "location": "VN-HCM",
  "merchantId": null,
  "correlationId": "corr-abc-001"
}
```

### 6.2 FraudAlertCreatedEvent

```json
{
  "eventId": "evt-fraud-000001",
  "eventType": "FRAUD_ALERT_CREATED",
  "occurredAt": "2026-06-10T10:15:32+07:00",
  "alertId": "alert-100001",
  "transactionId": "txn-100001",
  "accountId": "acc-9001",
  "customerId": "cus-7001",
  "riskScore": 92,
  "decision": "HOLD",
  "reasons": [
    "HIGH_AMOUNT",
    "NEW_BENEFICIARY",
    "VELOCITY_LIMIT_EXCEEDED"
  ],
  "correlationId": "corr-abc-001"
}
```

## 7. Luồng xử lý realtime

1. Khách hàng tạo giao dịch từ Mobile/Web/ATM.
2. API Gateway route request tới Transaction Service.
3. Transaction Service validate cơ bản và ghi transaction `PENDING` hoặc `PROCESSING`.
4. Transaction Service publish `TransactionCreatedEvent` vào topic `transaction.created`.
5. Fraud Detection Service consume event theo consumer group riêng.
6. Service chạy rule engine, velocity check, blacklist check, profile check, ML scoring.
7. Fraud Decision Service tạo quyết định:
   - `ALLOW`: cho giao dịch đi tiếp.
   - `HOLD`: giữ giao dịch, cần xác minh.
   - `BLOCK`: chặn giao dịch.
   - `REVIEW`: tạo case kiểm tra thủ công.
8. Nếu nghi ngờ, publish `FraudAlertCreatedEvent` vào topic `fraud.alert.created`.
9. Case Management Service tạo case cho Fraud Operation.
10. Notification Service gửi cảnh báo tới khách hàng hoặc nhân viên.
11. Audit Service/Data Lake lưu event phục vụ điều tra.

## 8. Partition key nên chọn gì?

### 8.1 `accountId` hoặc `customerId`

Nên dùng khi cần kiểm tra velocity theo tài khoản/customer.

Ưu điểm:

- Event cùng account vào cùng partition.
- Giữ ordering theo account.
- Dễ tính sliding window theo account.

Nhược điểm:

- Tài khoản có traffic quá lớn có thể gây hot partition.

### 8.2 `transactionId`

Nên dùng cho topic trạng thái theo transaction.

Ưu điểm:

- Phân bố đều hơn.
- Dễ trace theo transaction.

Nhược điểm:

- Không giữ ordering theo account.

### 8.3 Gợi ý

| Topic | Partition key |
|---|---|
| `transaction.created` | `accountId` hoặc `customerId` |
| `fraud.alert.created` | `accountId` hoặc `alertId` |
| `fraud.decision.created` | `transactionId` |
| `transaction.status.changed` | `transactionId` |

## 9. Consumer group đề xuất

| Consumer group | Subscribe topic | Chức năng |
|---|---|---|
| `fraud-detection-group` | `transaction.created` | Phân tích giao dịch nghi ngờ |
| `audit-group` | `transaction.created`, `fraud.alert.created` | Lưu audit trail |
| `data-lake-group` | Tất cả event cần phân tích | Đẩy dữ liệu sang data lake |
| `notification-group` | `fraud.alert.created`, `transaction.status.changed` | Gửi thông báo |
| `case-management-group` | `fraud.alert.created` | Tạo case xử lý thủ công |

## 10. Rule phát hiện nghi ngờ

| Rule | Mô tả | Ví dụ |
|---|---|---|
| High amount | Giao dịch vượt ngưỡng | Chuyển khoản > 50 triệu |
| Velocity | Quá nhiều giao dịch trong window ngắn | 10 giao dịch trong 2 phút |
| New beneficiary | Người nhận mới chưa từng giao dịch | Lần đầu chuyển tới tài khoản lạ |
| Blacklist | Người nhận/device/IP nằm trong blacklist | Account nhận bị report |
| Geo anomaly | Location bất thường | 5 phút trước ở Hà Nội, giờ login ở nước ngoài |
| Device anomaly | Thiết bị lạ | Device mới + amount lớn |
| Split transaction | Chia nhỏ giao dịch để né ngưỡng | 5 lần 49 triệu |
| Night transaction | Giao dịch giờ bất thường | 2 giờ sáng, amount lớn |

## 11. Delivery guarantee

Với fraud detection, thường chọn:

```text
At least once + idempotent consumer
```

Lý do:

- Không muốn mất event giao dịch.
- Chấp nhận duplicate nếu xử lý idempotent.
- Exactly once end-to-end với DB/service ngoài Kafka phức tạp hơn.

Yêu cầu:

- `eventId` unique.
- Lưu processed event để chống xử lý trùng.
- `alertId` có thể deterministic theo `transactionId + ruleVersion`.
- DB có unique constraint để không tạo duplicate case.

## 12. Retry và DLQ

### 12.1 Retry

Retry cho lỗi tạm thời:

- Timeout gọi Profile Service.
- Blacklist Service tạm unavailable.
- DB deadlock.

Không retry vô hạn trong consumer chính vì có thể block partition.

### 12.2 DLQ

Đẩy vào DLQ khi:

- Message sai schema.
- Thiếu field bắt buộc.
- Retry nhiều lần vẫn fail.
- Không parse được payload.

DLQ event nên chứa:

- Message gốc.
- Error reason.
- Consumer name.
- Retry count.
- Timestamp.
- Correlation id.

## 13. Monitoring cần có

| Metric | Ý nghĩa |
|---|---|
| Consumer lag | Fraud Detection có đang xử lý kịp realtime không |
| Throughput | Số transaction event/giây |
| Error rate | Tỉ lệ xử lý lỗi |
| DLQ count | Message lỗi cần điều tra |
| Alert rate | Số fraud alert/giây |
| Hold/Block rate | Tỉ lệ giao dịch bị giữ/chặn |
| Rule hit rate | Rule nào match nhiều |
| Processing latency | Thời gian từ transaction.created tới fraud.decision |
| Broker health | Broker, partition, ISR, disk |

## 14. Service chi tiết

### 14.1 Transaction Service

Chức năng:

- Nhận yêu cầu giao dịch.
- Validate tài khoản/số dư/hạn mức cơ bản.
- Ghi transaction vào DB.
- Publish event `transaction.created`.
- Nhận decision từ Fraud Decision nếu cần hold/block.

### 14.2 Fraud Detection Service

Chức năng:

- Consume `transaction.created`.
- Tính risk score.
- Chạy rule engine.
- Gọi các service phụ như blacklist/profile/ML.
- Publish `fraud.alert.created` hoặc `fraud.decision.created`.

### 14.3 Rule Engine

Chức năng:

- Quản lý rule phát hiện nghi ngờ.
- Version rule.
- Cho phép bật/tắt rule.
- Trả ra danh sách reason code.

Ví dụ reason:

```text
HIGH_AMOUNT
NEW_BENEFICIARY
VELOCITY_LIMIT_EXCEEDED
BLACKLISTED_RECEIVER
```

### 14.4 Velocity Check Service

Chức năng:

- Tính số giao dịch trong time window.
- Có thể dùng Redis/Kafka Streams/state store.
- Phát hiện transaction burst.

Ví dụ:

```text
count(accountId, 2 minutes) > 10
sum(accountId, 5 minutes) > 200_000_000
```

### 14.5 Blacklist Service

Chức năng:

- Check tài khoản nhận.
- Check device id.
- Check phone/email.
- Check IP.
- Check merchant.

Nên cache blacklist trong Redis/local cache để latency thấp.

### 14.6 Profile Service

Chức năng:

- Lưu hành vi bình thường của customer.
- Ví dụ:
  - Amount trung bình.
  - Thiết bị thường dùng.
  - Location thường dùng.
  - Người nhận thường giao dịch.

### 14.7 ML Risk Scoring Service

Chức năng:

- Tính risk score bằng model.
- Input là transaction + profile + device + velocity features.
- Output score 0-100.

Không nên để ML scoring là điểm lỗi duy nhất. Nếu service ML down, hệ thống cần fallback rule-based.

### 14.8 Case Management Service

Chức năng:

- Tạo case khi giao dịch nghi ngờ.
- Assign case cho nhân viên.
- Lưu trạng thái điều tra.
- Cho phép approve/reject.

### 14.9 Notification Service

Chức năng:

- Gửi SMS/push/email.
- Thông báo khách hàng xác nhận giao dịch.
- Thông báo Fraud Operation khi có case nghiêm trọng.

### 14.10 Audit Service

Chức năng:

- Lưu toàn bộ event quan trọng.
- Phục vụ điều tra, compliance, tracing.
- Đẩy dữ liệu sang data lake/SIEM.

## 15. Thiết kế trạng thái decision

| Decision | Ý nghĩa | Hành động |
|---|---|---|
| `ALLOW` | Rủi ro thấp | Cho giao dịch đi tiếp |
| `HOLD` | Nghi ngờ, cần xác minh | Giữ giao dịch, gửi OTP/case |
| `BLOCK` | Rủi ro cao | Chặn giao dịch |
| `REVIEW` | Không đủ dữ liệu hoặc lỗi kiểm tra | Tạo case thủ công |

## 16. Lưu ý production

- Không để fraud detection làm chậm core transaction nếu không bắt buộc synchronous.
- Với giao dịch giá trị cao, có thể cần check fraud synchronous trước khi release tiền.
- Event phải có `eventId`, `transactionId`, `correlationId`.
- Consumer phải idempotent.
- DLQ phải có quy trình xử lý/replay.
- Rule engine cần version để audit tại thời điểm quyết định.
- Alert quá nhiều sẽ gây alert fatigue, cần tuning threshold.
- Monitoring consumer lag là bắt buộc.
- Dữ liệu nhạy cảm cần masking/encryption.

## 17. Câu hỏi phỏng vấn từ case này

### Vì sao dùng Kafka cho fraud detection?

- Vì giao dịch là event stream realtime.
- Nhiều service cần consume cùng event.
- Kafka scale tốt và cho phép replay.
- Consumer group giúp xử lý song song.

### Partition key nên chọn gì?

Nếu cần ordering/velocity theo tài khoản, chọn `accountId` hoặc `customerId`.

Nếu cần phân phối đều theo transaction, chọn `transactionId`.

### Làm sao tránh tạo duplicate alert?

- Dùng `eventId` hoặc `transactionId + ruleVersion` làm idempotency key.
- DB unique constraint trên `alertId`.
- Consumer commit offset sau khi xử lý thành công.

### Nếu Fraud Detection bị lag thì sao?

- Scale consumer nhưng không vượt quá số partition.
- Tăng partition nếu cần.
- Tối ưu rule/DB/API downstream.
- Dùng cache cho blacklist/profile.
- Theo dõi consumer lag và processing latency.

### Nếu message lỗi schema thì xử lý thế nào?

- Không retry vô hạn.
- Đẩy DLQ.
- Alert team vận hành.
- Có tool replay sau khi fix data/code.

