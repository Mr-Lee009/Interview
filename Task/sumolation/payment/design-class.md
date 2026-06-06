# Payment Gateway Design

Tài liệu này rút gọn thiết kế theo hướng:

- Chỉ dùng `1 RestController` duy nhất cho toàn bộ payment
- Tối ưu số class
- Chỉ giữ các thành phần thực sự cần để tái sử dụng
- Tránh tách quá nhiều controller, service hoặc DTO không cần thiết

Phạm vi hỗ trợ:

- Tạo thanh toán
- Nhận callback/IPN từ gateway
- Query trạng thái thanh toán
- Đồng bộ lại trạng thái từ gateway nếu cần

## 0. Cây thư mục gợi ý

```text
payment/
├─ controller/
│  └─ PaymentController.java
├─ service/
│  ├─ PaymentService.java
│  └─ PaymentGatewayResolver.java
├─ gateway/
│  ├─ PaymentGateway.java
│  ├─ MomoPaymentGateway.java
│  ├─ VnpayPaymentGateway.java
│  └─ ZaloPayPaymentGateway.java
├─ util/
│  └─ PaymentGatewayHttpUtil.java
├─ repository/
│  ├─ PaymentTransactionRepository.java
│  └─ PaymentGatewayConfigRepository.java
├─ entity/
│  ├─ PaymentTransactionEntity.java
│  └─ PaymentGatewayConfigEntity.java
├─ dto/
│  ├─ CreatePaymentRequestDTO.java
│  ├─ CreatePaymentResponseDTO.java
│  ├─ PaymentDetailResponseDTO.java
│  ├─ PaymentSyncResponseDTO.java
│  ├─ PaymentGatewayCallbackCommandDTO.java
│  ├─ GatewayCreatePaymentResultDTO.java
│  ├─ GatewayCallbackResultDTO.java
│  └─ GatewayQueryResultDTO.java
└─ enums/
   ├─ PaymentProvider.java
   └─ PaymentStatus.java
```

## 1. Database cần thiết

Chỉ cần 2 bảng chính:

1. `payment_transaction`
2. `payment_gateway_config`

Hai bảng này dùng cho MySQL và có quan hệ logic như sau:

- `payment_gateway_config` là bảng cấu hình của từng cổng thanh toán
- `payment_transaction` là bảng dữ liệu giao dịch thực tế
- Một cấu hình gateway có thể được dùng bởi nhiều giao dịch
- Quan hệ logic là: `payment_gateway_config (1) -> (n) payment_transaction`

Lưu ý:

- Trong bản thiết kế gọn này, quan hệ đang được nối qua cột `provider`
- Tức là `payment_transaction.provider` ánh xạ tới `payment_gateway_config.provider`
- Nếu muốn ràng buộc chặt hơn ở mức database, có thể thêm `gateway_config_id`

## 1.0 Quan hệ giữa các bảng

### Quan hệ logic hiện tại

```text
payment_gateway_config.provider 1 ---- n payment_transaction.provider
```

Ý nghĩa:

1. Một dòng config cho `MOMO` có thể phục vụ nhiều payment transaction của `MOMO`
2. Một dòng config cho `VNPAY` có thể phục vụ nhiều payment transaction của `VNPAY`
3. Một dòng config cho `ZALOPAY` có thể phục vụ nhiều payment transaction của `ZALOPAY`

### Khuyến nghị

Để thiết kế đơn giản:

- dùng `provider` để join logic là đủ

Nếu muốn mạnh hơn về ràng buộc dữ liệu:

- thêm `gateway_config_id` trong `payment_transaction`
- tạo `FOREIGN KEY` sang `payment_gateway_config(id)`

## 1.1 Bảng `payment_transaction`

```sql
CREATE TABLE payment_transaction (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    payment_code VARCHAR(64) NOT NULL,
    order_id VARCHAR(64) NOT NULL,
    provider VARCHAR(20) NOT NULL,
    gateway_txn_ref VARCHAR(100) DEFAULT NULL,
    gateway_transaction_no VARCHAR(100) DEFAULT NULL,
    amount BIGINT NOT NULL,
    currency VARCHAR(10) NOT NULL DEFAULT 'VND',
    status VARCHAR(20) NOT NULL,
    payment_url TEXT DEFAULT NULL,
    request_payload JSON DEFAULT NULL,
    response_payload JSON DEFAULT NULL,
    callback_payload JSON DEFAULT NULL,
    fail_reason VARCHAR(255) DEFAULT NULL,
    paid_at DATETIME DEFAULT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_payment_code (payment_code),
    KEY idx_payment_order_id (order_id),
    KEY idx_payment_provider_ref (provider, gateway_txn_ref),
    KEY idx_payment_status (status)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci;
```

### Bản có khóa ngoại chặt hơn

Nếu muốn ràng buộc DB mạnh hơn, có thể dùng thêm `gateway_config_id`:

```sql
CREATE TABLE payment_transaction (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    gateway_config_id BIGINT UNSIGNED NOT NULL,
    payment_code VARCHAR(64) NOT NULL,
    order_id VARCHAR(64) NOT NULL,
    provider VARCHAR(20) NOT NULL,
    gateway_txn_ref VARCHAR(100) DEFAULT NULL,
    gateway_transaction_no VARCHAR(100) DEFAULT NULL,
    amount BIGINT NOT NULL,
    currency VARCHAR(10) NOT NULL DEFAULT 'VND',
    status VARCHAR(20) NOT NULL,
    payment_url TEXT DEFAULT NULL,
    request_payload JSON DEFAULT NULL,
    response_payload JSON DEFAULT NULL,
    callback_payload JSON DEFAULT NULL,
    fail_reason VARCHAR(255) DEFAULT NULL,
    paid_at DATETIME NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_payment_code (payment_code),
    KEY idx_payment_order_id (order_id),
    KEY idx_payment_provider_ref (provider, gateway_txn_ref),
    KEY idx_payment_status (status),
    KEY idx_payment_gateway_config_id (gateway_config_id),
    CONSTRAINT fk_payment_tx_gateway_config
        FOREIGN KEY (gateway_config_id)
        REFERENCES payment_gateway_config(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci;
```

Giải thích ngắn:

| Trường | Ý nghĩa |
|---|---|
| `id` | ID nội bộ |
| `payment_code` | Mã payment duy nhất của hệ thống |
| `order_id` | Mã đơn hàng nghiệp vụ |
| `provider` | Cổng thanh toán: `MOMO`, `VNPAY`, `ZALOPAY` |
| `gateway_txn_ref` | Mã tham chiếu gửi sang gateway |
| `gateway_transaction_no` | Mã giao dịch thật phía gateway trả về |
| `amount` | Số tiền cần thanh toán |
| `currency` | Loại tiền |
| `status` | `PENDING`, `SUCCESS`, `FAILED`, `EXPIRED`, `REVIEW` |
| `payment_url` | Link redirect user sang cổng thanh toán |
| `request_payload` | Raw request gửi gateway để debug |
| `response_payload` | Raw response create payment |
| `callback_payload` | Raw callback/IPN |
| `fail_reason` | Lý do lỗi nếu có |
| `paid_at` | Thời điểm thanh toán thành công |
| `created_at` | Thời điểm tạo |
| `updated_at` | Thời điểm cập nhật cuối |

## 1.2 Bảng `payment_gateway_config`

```sql
CREATE TABLE payment_gateway_config (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    provider VARCHAR(20) NOT NULL,
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    environment VARCHAR(20) NOT NULL,
    merchant_code VARCHAR(100) DEFAULT NULL,
    access_key VARCHAR(255) DEFAULT NULL,
    secret_key VARCHAR(255) DEFAULT NULL,
    public_key TEXT DEFAULT NULL,
    checksum_key VARCHAR(255) DEFAULT NULL,
    callback_key VARCHAR(255) DEFAULT NULL,
    endpoint_base_url VARCHAR(255) NOT NULL,
    create_api_path VARCHAR(255) DEFAULT NULL,
    query_api_path VARCHAR(255) DEFAULT NULL,
    return_url VARCHAR(255) NOT NULL,
    callback_url VARCHAR(255) NOT NULL,
    secret_ref VARCHAR(255) NOT NULL,
    timeout_seconds INT NOT NULL DEFAULT 15,
    priority INT NOT NULL DEFAULT 100,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_payment_gateway_provider (provider),
    KEY idx_payment_gateway_enabled_priority (enabled, priority)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci;
```

Giải thích ngắn:

| Trường | Ý nghĩa |
|---|---|
| `provider` | Tên gateway |
| `enabled` | Bật/tắt gateway |
| `environment` | `SANDBOX` hoặc `PRODUCTION` |
| `merchant_code` | Mã merchant chính như `partnerCode`, `vnp_TmnCode`, `app_id` |
| `access_key` | Dùng cho các gateway có access key riêng như `MoMo` |
| `secret_key` | Secret chính để ký request như `MoMo secretKey` |
| `public_key` | Dùng khi gateway yêu cầu RSA public key như `MoMo` |
| `checksum_key` | Secret dùng tạo/verify checksum như `VNPAY vnp_HashSecret`, `ZaloPay key1` |
| `callback_key` | Secret riêng để verify callback nếu gateway tách riêng như `ZaloPay key2` |
| `endpoint_base_url` | Base URL gọi gateway |
| `create_api_path` | API tạo payment |
| `query_api_path` | API query/đối soát |
| `return_url` | URL user quay về frontend |
| `callback_url` | URL gateway callback server-to-server |
| `secret_ref` | Tham chiếu tới secret ngoài DB |
| `timeout_seconds` | Timeout khi gọi gateway |
| `priority` | Thứ tự ưu tiên nếu cần routing |

## 1.3 Các secret/key cần có cho từng cổng thanh toán

Phần này tổng hợp bộ credential cần có khi tích hợp thực tế.  
Lưu ý:

- Không lưu plaintext secret trực tiếp trong code
- Nếu hệ thống đã cho phép lưu cấu hình từ DB, nên map vào cột rõ ràng thay vì nhét `JSON`
- Các giá trị dưới đây là `tên trường cấu hình cần có`, không phải secret thật

| Gateway | Tên credential | Vai trò | Link tài liệu |
|---|---|---|---|
| `MoMo` | `partnerCode` | Mã định danh merchant | https://developers.momo.vn/v3/docs/payment/onboarding/integration-process/ |
| `MoMo` | `accessKey` | Access key tham gia chuỗi ký request | https://developers.momo.vn/v3/docs/payment/onboarding/integration-process/ |
| `MoMo` | `secretKey` | Secret dùng tạo `signature` | https://developers.momo.vn/v3/docs/payment/onboarding/integration-process/ |
| `MoMo` | `publicKey` | Public key dùng cho các flow RSA được MoMo hỗ trợ | https://developers.momo.vn/v3/docs/payment/onboarding/integration-process/ |
| `VNPAY` | `vnp_TmnCode` | Mã website/merchant trên hệ thống VNPAY | https://sandbox.vnpayment.vn/apis/docs/gioi-thieu/ |
| `VNPAY` | `vnp_HashSecret` | Secret dùng tạo và kiểm tra `vnp_SecureHash` | https://sandbox.vnpayment.vn/apis/docs/gioi-thieu/ |
| `ZaloPay` | `app_id` | Mã ứng dụng merchant | https://docs.zalopay.vn/docs/developer-tools/knowledge-base/basic-definition |
| `ZaloPay` | `key1` | Key dùng khi gửi request sang ZaloPay | https://docs.zalopay.vn/docs/developer-tools/security/secure-data-transmission/ |
| `ZaloPay` | `key2` | Key dùng khi verify callback hoặc redirect | https://docs.zalopay.vn/docs/developer-tools/security/secure-data-transmission/ |

### Map vào `payment_gateway_config`

| Gateway | merchant_code | access_key | secret_key | public_key | checksum_key | callback_key |
|---|---|---|---|---|---|---|
| `MoMo` | `partnerCode` | `accessKey` | `secretKey` | `publicKey` | `NULL` | `NULL` |
| `VNPAY` | `vnp_TmnCode` | `NULL` | `NULL` | `NULL` | `vnp_HashSecret` | `NULL` |
| `ZaloPay` | `app_id` | `NULL` | `NULL` | `NULL` | `key1` | `key2` |

### Ghi chú theo từng gateway

#### MoMo

- Theo tài liệu onboarding của MoMo, bộ credential tích hợp gồm:
  - `partnerCode`
  - `accessKey`
  - `secretKey`
  - `publicKey`
- Trong đó `secretKey` là secret quan trọng nhất để tạo `signature`
- `publicKey` chỉ cần khi đi theo flow có mã hóa RSA, không phải API nào cũng dùng

Nguồn:

- https://developers.momo.vn/v3/docs/payment/onboarding/integration-process/
- https://developers.momo.vn/v3/docs/payment/api/other/postman/

#### VNPAY

- Theo tài liệu cổng thanh toán VNPAY, merchant cần:
  - `vnp_TmnCode`
  - `vnp_HashSecret`
- `vnp_HashSecret` là secret chính để tạo và kiểm tra `vnp_SecureHash`
- VNPAY không tách thêm `accessKey` hay `publicKey` như MoMo

Nguồn:

- https://sandbox.vnpayment.vn/apis/docs/gioi-thieu/
- https://sandbox.vnpayment.vn/apis/docs/thanh-toan-pay/pay.html
- https://sandbox.vnpayment.vn/apis/docs/chuyen-doi-thuat-toan/changeTypeHash.html

#### ZaloPay

- Theo tài liệu bảo mật của ZaloPay, merchant được cấp:
  - `app_id`
  - `key1`
  - `key2`
- Trong đó:
  - `key1` dùng khi gửi request sang ZaloPay
  - `key2` dùng khi nhận callback hoặc redirect từ ZaloPay

Nguồn:

- https://docs.zalopay.vn/docs/developer-tools/knowledge-base/basic-definition
- https://docs.zalopay.vn/docs/developer-tools/security/secure-data-transmission/
- https://docs.zalopay.vn/docs/developer-tools/knowledge-base/callback

## 1.4 Cách join dữ liệu giữa 2 bảng

### Join theo `provider`

Đây là cách đơn giản, phù hợp với thiết kế hiện tại:

```sql
SELECT
    pt.id,
    pt.payment_code,
    pt.order_id,
    pt.provider,
    pt.amount,
    pt.status,
    pgc.endpoint_base_url,
    pgc.callback_url,
    pgc.timeout_seconds
FROM payment_transaction pt
JOIN payment_gateway_config pgc
    ON pt.provider = pgc.provider
WHERE pt.payment_code = 'PAY_20260604_001';
```

### Join theo `gateway_config_id`

Nếu dùng bản có khóa ngoại:

```sql
SELECT
    pt.id,
    pt.payment_code,
    pt.order_id,
    pt.provider,
    pt.amount,
    pt.status,
    pgc.endpoint_base_url,
    pgc.callback_url,
    pgc.timeout_seconds
FROM payment_transaction pt
JOIN payment_gateway_config pgc
    ON pt.gateway_config_id = pgc.id
WHERE pt.payment_code = 'PAY_20260604_001';
```

## 1.5 Kết luận về quan hệ bảng

Khuyến nghị thực tế:

1. Nếu đang làm bản đơn giản hoặc interview design:
   dùng quan hệ logic qua `provider`
2. Nếu chuẩn bị triển khai production:
   nên thêm `gateway_config_id` và `FOREIGN KEY`

Trade-off:

1. Join theo `provider`:
   đơn giản, ít cột hơn, dễ trình bày
2. Join theo `gateway_config_id`:
   chặt dữ liệu hơn, đúng quan hệ DB hơn

## 2. API và class chính

## 2.1 `PaymentController`

```java
// Controller duy nhất của module payment.
// Nhận request từ frontend và callback/IPN từ gateway.
// Không chứa business logic, chỉ map request/response và gọi PaymentService.
@RestController
@RequestMapping("/api/payments")
public class PaymentController {

    // Tạo giao dịch thanh toán mới và trả về paymentUrl cho frontend redirect.
    @PostMapping
    public CreatePaymentResponseDTO createPayment(@RequestBody CreatePaymentRequestDTO request) {
        return null;
    }

    // Nhận callback/IPN dạng POST từ các gateway như MoMo, ZaloPay.
    @PostMapping("/callback/{provider}")
    public Object postCallback(
            @PathVariable String provider,
            @RequestHeader Map<String, String> headers,
            @RequestBody(required = false) String body,
            HttpServletRequest request
    ) {
        return null;
    }

    // Nhận callback/IPN dạng GET từ các gateway như VNPAY.
    @GetMapping("/callback/{provider}")
    public Object getCallback(
            @PathVariable String provider,
            @RequestHeader Map<String, String> headers,
            @RequestParam Map<String, String> queryParams
    ) {
        return null;
    }

    // Lấy trạng thái payment hiện tại từ DB để frontend hiển thị.
    @GetMapping("/{paymentCode}")
    public PaymentDetailResponseDTO getPayment(@PathVariable String paymentCode) {
        return null;
    }

    // Chủ động gọi lại gateway để đồng bộ trạng thái payment khi cần.
    @PostMapping("/{paymentCode}/sync")
    public PaymentSyncResponseDTO syncPayment(@PathVariable String paymentCode) {
        return null;
    }
}
```

### API cần có

```text
POST /api/payments
POST /api/payments/callback/{provider}
GET  /api/payments/callback/{provider}
GET  /api/payments/{paymentCode}
POST /api/payments/{paymentCode}/sync
```

## 2.2 `PaymentService`

```java
// Service chính điều phối toàn bộ nghiệp vụ payment.
// Tự đọc config gateway, chọn adapter, tạo payment, xử lý callback và sync trạng thái.
public class PaymentService {

    // Tạo payment mới, lưu transaction PENDING và trả về paymentUrl cho frontend.
    public CreatePaymentResponseDTO createPayment(CreatePaymentRequestDTO request) {
        return null;
    }

    // Nhận dữ liệu callback raw từ controller, verify qua adapter và cập nhật trạng thái DB.
    public void handleCallback(
            String provider,
            Map<String, String> headers,
            Map<String, String> queryParams,
            String body
    ) {
    }

    // Lấy thông tin payment hiện tại từ DB để frontend hiển thị.
    public PaymentDetailResponseDTO getPayment(String paymentCode) {
        return null;
    }

    // Chủ động gọi query sang gateway để đồng bộ lại trạng thái payment.
    public PaymentSyncResponseDTO syncPayment(String paymentCode) {
        return null;
    }
}
```

## 2.3 `PaymentGatewayResolver`

```java
// Resolver dùng để chọn đúng gateway adapter theo provider.
// Giúp PaymentService không cần if-else lớn cho MOMO, VNPAY, ZALOPAY.
public class PaymentGatewayResolver {

    private final Map<PaymentProvider, PaymentGateway> gateways;

    // Trả về adapter phù hợp với provider đầu vào.
    public PaymentGateway get(PaymentProvider provider) {
        return gateways.get(provider);
    }
}
```

## 3. Gateway

## 3.1 `PaymentGateway`

```java
// Interface chung cho tất cả gateway adapter.
// Định nghĩa contract chuẩn để create payment, handle callback và query trạng thái.
public interface PaymentGateway {

    // Trả về provider mà adapter này hỗ trợ.
    PaymentProvider provider();

    // Gọi create payment sang gateway và trả về dữ liệu chuẩn hóa cho hệ thống.
    GatewayCreatePaymentResultDTO createPayment(
            CreatePaymentRequestDTO request,
            PaymentGatewayConfigEntity config
    );

    // Parse callback/IPN, verify chữ ký và chuẩn hóa kết quả callback.
    GatewayCallbackResultDTO handleCallback(
            PaymentGatewayCallbackCommandDTO command,
            PaymentGatewayConfigEntity config
    );

    // Gọi query trạng thái sang gateway để đồng bộ hoặc đối soát.
    GatewayQueryResultDTO queryPayment(
            PaymentTransactionEntity transaction,
            PaymentGatewayConfigEntity config
    );
}
```

## 3.2 Adapter cần có

1. `MomoPaymentGateway`
2. `VnpayPaymentGateway`
3. `ZaloPayPaymentGateway`

Mỗi adapter tự xử lý:

1. Build request
2. Sign request
3. Gọi API provider qua util dùng chung
4. Parse callback
5. Verify signature
6. Query trạng thái

## 4. Util

## 4.1 `PaymentGatewayHttpUtil`

```java
// Util dùng chung để gọi HTTP sang các cổng thanh toán.
// Chỉ xử lý phần kỹ thuật như gửi request, set timeout, nhận raw response và xử lý lỗi HTTP.
// Không chứa business logic payment, không sign request, không verify callback.
public class PaymentGatewayHttpUtil {

    // Gọi HTTP POST JSON tới gateway.
    public RawGatewayHttpResponse postJson(
            String url,
            Map<String, String> headers,
            String jsonBody,
            int timeoutSeconds
    ) {
        return null;
    }

    // Gọi HTTP POST form tới gateway.
    public RawGatewayHttpResponse postForm(
            String url,
            Map<String, String> headers,
            Map<String, String> formData,
            int timeoutSeconds
    ) {
        return null;
    }

    // Gọi HTTP GET tới gateway.
    public RawGatewayHttpResponse get(
            String url,
            Map<String, String> headers,
            Map<String, String> queryParams,
            int timeoutSeconds
    ) {
        return null;
    }
}
```

## 5. Repository

## 5.1 `PaymentTransactionRepository`

```java
// Repository thao tác với bảng payment_transaction.
// Dùng để lưu payment mới, tìm payment và cập nhật trạng thái thanh toán.
public interface PaymentTransactionRepository {

    // Tìm payment theo mã payment nội bộ của hệ thống.
    Optional<PaymentTransactionEntity> findByPaymentCode(String paymentCode);

    // Tìm payment theo provider và mã tham chiếu gateway để xử lý callback.
    Optional<PaymentTransactionEntity> findByProviderAndGatewayTxnRef(
            PaymentProvider provider,
            String gatewayTxnRef
    );
}
```

## 5.2 `PaymentGatewayConfigRepository`

```java
// Repository thao tác với bảng payment_gateway_config.
// Dùng để đọc cấu hình runtime của từng cổng thanh toán.
public interface PaymentGatewayConfigRepository {

    // Lấy cấu hình theo đúng provider.
    Optional<PaymentGatewayConfigEntity> findByProvider(PaymentProvider provider);

    // Lấy danh sách gateway đang bật theo thứ tự ưu tiên.
    List<PaymentGatewayConfigEntity> findByEnabledTrueOrderByPriorityAsc();
}
```

## 6. DTO

## 6.1 `CreatePaymentRequestDTO`

```java
// DTO input khi frontend yêu cầu tạo payment mới.
// Chứa thông tin tối thiểu để backend tạo giao dịch thanh toán.
public record CreatePaymentRequestDTO(
        // Mã đơn hàng nội bộ.
        String orderId,

        // Cổng thanh toán được chọn.
        PaymentProvider provider,

        // Số tiền cần thanh toán.
        Long amount,

        // Mô tả đơn hàng hoặc nội dung thanh toán.
        String description,

        // URL frontend nhận kết quả redirect sau thanh toán.
        String returnUrl
) {
}
```

## 6.2 `CreatePaymentResponseDTO`

```java
// DTO output khi tạo payment thành công.
// Trả về paymentUrl để frontend redirect người dùng sang gateway.
public record CreatePaymentResponseDTO(
        // Mã payment nội bộ.
        String paymentCode,

        // Mã đơn hàng nội bộ.
        String orderId,

        // Provider đã chọn.
        PaymentProvider provider,

        // Trạng thái ban đầu, thường là PENDING.
        PaymentStatus status,

        // Số tiền thanh toán.
        Long amount,

        // URL để frontend redirect sang cổng thanh toán.
        String paymentUrl
) {
}
```

## 6.3 `PaymentDetailResponseDTO`

```java
// DTO trả về thông tin chi tiết payment hiện tại.
// Dùng cho frontend poll trạng thái hoặc hiển thị kết quả thanh toán.
public record PaymentDetailResponseDTO(
        // Mã payment nội bộ.
        String paymentCode,

        // Mã đơn hàng nội bộ.
        String orderId,

        // Provider xử lý giao dịch.
        PaymentProvider provider,

        // Trạng thái hiện tại của payment.
        PaymentStatus status,

        // Số tiền của giao dịch.
        Long amount,

        // Mã giao dịch thật phía gateway nếu đã có.
        String gatewayTransactionNo
) {
}
```

## 6.4 `PaymentSyncResponseDTO`

```java
// DTO trả về sau khi backend chủ động sync trạng thái từ gateway.
public record PaymentSyncResponseDTO(
        // Mã payment nội bộ.
        String paymentCode,

        // Trạng thái mới nhất sau sync.
        PaymentStatus status,

        // Đánh dấu thao tác sync có thực sự chạy hay không.
        boolean synced
) {
}
```

## 6.5 `PaymentGatewayCallbackCommandDTO`

```java
// DTO nội bộ gom toàn bộ dữ liệu callback raw từ gateway.
// Adapter sẽ tự parse lại theo format riêng của từng provider.
public record PaymentGatewayCallbackCommandDTO(
        // Provider gửi callback.
        PaymentProvider provider,

        // Header raw của request callback.
        Map<String, String> headers,

        // Query params raw, hữu ích với VNPAY.
        Map<String, String> queryParams,

        // Body raw, hữu ích với MoMo hoặc ZaloPay.
        String body
) {
}
```

## 6.6 `GatewayCreatePaymentResultDTO`

```java
// DTO nội bộ là kết quả trả về từ gateway adapter sau khi tạo payment.
public record GatewayCreatePaymentResultDTO(
        // Mã tham chiếu gửi sang gateway.
        String gatewayTxnRef,

        // URL redirect sang gateway.
        String paymentUrl,

        // Raw response để debug hoặc lưu audit.
        String rawResponse
) {
}
```

## 6.7 `GatewayCallbackResultDTO`

```java
// DTO nội bộ là kết quả chuẩn hóa sau khi parse callback/IPN từ gateway.
public record GatewayCallbackResultDTO(
        // Mã tham chiếu đã gửi sang gateway.
        String gatewayTxnRef,

        // Mã giao dịch thật do gateway trả về.
        String gatewayTransactionNo,

        // Số tiền trong callback để đối chiếu với DB.
        Long amount,

        // Trạng thái đã chuẩn hóa về enum chung của hệ thống.
        PaymentStatus status,

        // Đánh dấu callback có chữ ký hợp lệ hay không.
        boolean validSignature,

        // Raw payload callback để debug hoặc audit.
        String rawPayload,

        // Lý do lỗi nếu callback không hợp lệ.
        String failReason
) {
}
```

## 6.8 `GatewayQueryResultDTO`

```java
// DTO nội bộ là kết quả query trạng thái từ gateway.
public record GatewayQueryResultDTO(
        // Mã tham chiếu đã gửi sang gateway.
        String gatewayTxnRef,

        // Mã giao dịch thật phía gateway.
        String gatewayTransactionNo,

        // Trạng thái đã chuẩn hóa về enum chung.
        PaymentStatus status,

        // Raw response query từ gateway.
        String rawResponse
) {
}
```

## 7. Entity

## 7.1 `PaymentTransactionEntity`

```java
// Entity ánh xạ bảng payment_transaction.
// Lưu trạng thái giao dịch thanh toán nội bộ, mã gateway, amount, payload và thời gian xử lý.
public class PaymentTransactionEntity {
}
```

## 7.2 `PaymentGatewayConfigEntity`

```java
// Entity ánh xạ bảng payment_gateway_config.
// Lưu cấu hình runtime của gateway như endpoint, callbackUrl, timeout, secretRef.
public class PaymentGatewayConfigEntity {
}
```

## 8. Enum

## 8.1 `PaymentProvider`

```java
// Enum định danh các cổng thanh toán mà hệ thống đang hỗ trợ.
public enum PaymentProvider {
    MOMO,
    VNPAY,
    ZALOPAY
}
```

## 8.2 `PaymentStatus`

```java
// Enum chuẩn hóa trạng thái payment trong toàn hệ thống.
public enum PaymentStatus {
    PENDING,
    SUCCESS,
    FAILED,
    EXPIRED,
    REVIEW
}
```

## 9. Số class tối thiểu nên giữ

Nếu muốn gọn nhưng vẫn đúng kiến trúc, chỉ nên giữ:

### Controller

1. `PaymentController`

### Service

2. `PaymentService`
3. `PaymentGatewayResolver`

### Gateway

4. `PaymentGateway`
5. `MomoPaymentGateway`
6. `VnpayPaymentGateway`
7. `ZaloPayPaymentGateway`

### Util

8. `PaymentGatewayHttpUtil`

### Repository

9. `PaymentTransactionRepository`
10. `PaymentGatewayConfigRepository`

### Entity

11. `PaymentTransactionEntity`
12. `PaymentGatewayConfigEntity`

### DTO

13. `CreatePaymentRequestDTO`
14. `CreatePaymentResponseDTO`
15. `PaymentDetailResponseDTO`
16. `PaymentSyncResponseDTO`
17. `PaymentGatewayCallbackCommandDTO`
18. `GatewayCreatePaymentResultDTO`
19. `GatewayCallbackResultDTO`
20. `GatewayQueryResultDTO`

### Enum

21. `PaymentProvider`
22. `PaymentStatus`

Không cần tách:

- nhiều controller
- nhiều service nhỏ không tái sử dụng
- DTO riêng cho từng endpoint nếu nội dung gần giống nhau

## 10. Gợi ý triển khai ngắn

Flow gọn nhất:

1. Frontend gọi `POST /api/payments`
2. `PaymentService` tạo `PENDING`
3. `PaymentGatewayResolver` chọn gateway
4. Gateway adapter tạo payment URL
5. User thanh toán ở cổng
6. Gateway callback vào `/api/payments/callback/{provider}`
7. `PaymentService` verify và update DB
8. Frontend gọi `GET /api/payments/{paymentCode}` để lấy kết quả

Thiết kế này đủ gọn, dễ maintain, và không bị tách class quá mức.
