# So sánh MoMo, VNPAY, ZaloPay để thiết kế Payment Gateway

File này dùng để thiết kế class cho tính năng thanh toán khi hệ thống cần hỗ trợ nhiều cổng: MoMo, VNPAY, ZaloPay.

Mục tiêu leader:

- Business code không phụ thuộc trực tiếp vào từng provider.
- Mỗi cổng thanh toán được đóng gói bằng một adapter riêng.
- DB lưu trạng thái theo model chung.
- Callback/IPN phải verify chữ ký trước khi cập nhật trạng thái.
- Redirect user không phải nguồn dữ liệu chuẩn để mark `PAID`.

## 1. So sánh tổng quan

| Tiêu chí | MoMo | VNPAY | ZaloPay |
|---|---|---|---|
| Cách tạo giao dịch | Backend gọi API create | Backend tự build payment URL | Backend gọi API create |
| Endpoint tạo thanh toán | `POST /v2/gateway/api/create` | `GET /paymentv2/vpcpay.html?...` | `POST /v2/create` |
| URL thanh toán | Provider trả `payUrl` | Backend tự tạo `paymentUrl` | Provider trả `order_url` |
| User callback | `redirectUrl` | `vnp_ReturnUrl` | `redirecturl` trong `embed_data` |
| Server callback | `ipnUrl` | `IPN URL` | `callback_url` |
| Tạo chữ ký create | HMAC SHA256 | HMAC SHA512 | HMAC SHA256 |
| Key ký create | `secretKey` | `vnp_HashSecret` | `key1` |
| Key verify callback | `secretKey` | `vnp_HashSecret` | `key2` |
| Amount gửi provider | VND trực tiếp | `amount * 100` | VND trực tiếp |
| Query đối soát | API query MoMo nếu cần | QueryDR | `/v2/query` |
| Nguồn cập nhật trạng thái chuẩn | IPN | IPN | Callback |

## 2. Config khác nhau

### 2.1 Config chung nên có trong hệ thống

```yaml
payment:
  default-provider: momo
  return-domain: https://your-domain.com
  callback-domain: https://your-domain.com
  timeout-seconds: 30
```

### 2.2 MoMo config

```yaml
payment:
  momo:
    endpoint: https://test-payment.momo.vn/v2/gateway/api/create
    partner-code: MOMO_TEST_PARTNER_CODE
    access-key: MOMO_TEST_ACCESS_KEY
    secret-key: MOMO_TEST_SECRET_KEY
    request-type: captureWallet
    redirect-url: https://your-domain.com/payment/momo/return
    ipn-url: https://your-domain.com/api/payments/momo/ipn
    lang: vi
```

Class config:

```java
public record MomoProperties(
        String endpoint,
        String partnerCode,
        String accessKey,
        String secretKey,
        String requestType,
        String redirectUrl,
        String ipnUrl,
        String lang
) {
}
```

### 2.3 VNPAY config

```yaml
payment:
  vnpay:
    pay-url: https://sandbox.vnpayment.vn/paymentv2/vpcpay.html
    query-url: https://sandbox.vnpayment.vn/merchant_webapi/api/transaction
    tmn-code: DEMOV210
    hash-secret: VNPAY_SANDBOX_HASH_SECRET
    return-url: https://your-domain.com/payment/vnpay/return
    ipn-url: https://your-domain.com/api/payments/vnpay/ipn
    version: 2.1.0
    command: pay
    curr-code: VND
    locale: vn
    order-type: other
    expire-minutes: 15
```

Class config:

```java
public record VnpayProperties(
        String payUrl,
        String queryUrl,
        String tmnCode,
        String hashSecret,
        String returnUrl,
        String ipnUrl,
        String version,
        String command,
        String currCode,
        String locale,
        String orderType,
        Integer expireMinutes
) {
}
```

### 2.4 ZaloPay config

```yaml
payment:
  zalopay:
    create-endpoint: https://sb-openapi.zalopay.vn/v2/create
    query-endpoint: https://sb-openapi.zalopay.vn/v2/query
    app-id: 2553
    key1: ZALOPAY_SANDBOX_KEY1
    key2: ZALOPAY_SANDBOX_KEY2
    callback-url: https://your-domain.com/api/payments/zalopay/callback
    redirect-url: https://your-domain.com/payment/zalopay/return
    default-app-user: website
```

Class config:

```java
public record ZaloPayProperties(
        String createEndpoint,
        String queryEndpoint,
        Integer appId,
        String key1,
        String key2,
        String callbackUrl,
        String redirectUrl,
        String defaultAppUser
) {
}
```

## 3. Request tạo thanh toán khác nhau

### 3.1 Request chung từ frontend vào backend

Frontend không nên biết chi tiết `partnerCode`, `vnp_TmnCode`, `key1`, `key2`.

```json
{
  "provider": "MOMO",
  "orderId": "ORDER_20260603_0001",
  "userId": "user_1001",
  "amount": 10000,
  "description": "Thanh toan don hang ORDER_20260603_0001",
  "returnUrl": "https://your-domain.com/payment/result"
}
```

DTO gợi ý:

```java
public record CreatePaymentCommand(
        PaymentProvider provider,
        String orderId,
        String userId,
        Long amount,
        String description,
        String returnUrl
) {
}
```

### 3.2 Request sang MoMo

```json
{
  "partnerCode": "MOMO_TEST_PARTNER_CODE",
  "requestType": "captureWallet",
  "ipnUrl": "https://your-domain.com/api/payments/momo/ipn",
  "redirectUrl": "https://your-domain.com/payment/momo/return",
  "orderId": "ORDER_20260603_0001",
  "amount": 10000,
  "orderInfo": "Thanh toan don hang ORDER_20260603_0001",
  "requestId": "REQ_ORDER_20260603_0001",
  "extraData": "",
  "signature": "HMAC_SHA256_SIGNATURE",
  "lang": "vi"
}
```

Raw signature:

```text
accessKey=$accessKey&amount=$amount&extraData=$extraData&ipnUrl=$ipnUrl&orderId=$orderId&orderInfo=$orderInfo&partnerCode=$partnerCode&redirectUrl=$redirectUrl&requestId=$requestId&requestType=$requestType
```

Điểm cần nhớ:

- Backend gọi API create.
- Amount là VND trực tiếp.
- MoMo trả `payUrl`.

### 3.3 Request sang VNPAY

VNPAY không gửi body JSON create. Backend build URL:

```text
https://sandbox.vnpayment.vn/paymentv2/vpcpay.html
  ?vnp_Amount=1000000
  &vnp_Command=pay
  &vnp_CreateDate=20260603120000
  &vnp_CurrCode=VND
  &vnp_IpAddr=127.0.0.1
  &vnp_Locale=vn
  &vnp_OrderInfo=Thanh+toan+don+hang+ORDER_20260603_0001
  &vnp_OrderType=other
  &vnp_ReturnUrl=https%3A%2F%2Fyour-domain.com%2Fpayment%2Fvnpay%2Freturn
  &vnp_TmnCode=DEMOV210
  &vnp_TxnRef=ORDER_20260603_0001
  &vnp_Version=2.1.0
  &vnp_SecureHash=HMAC_SHA512_HASH
```

Raw signature:

```text
Sort tất cả vnp_* params theo tên tăng dần, bỏ vnp_SecureHash/vnp_SecureHashType, nối query string rồi ký HMAC SHA512.
```

Điểm cần nhớ:

- Backend không gọi API create.
- Backend tự tạo `paymentUrl`.
- Amount gửi VNPAY phải là `amount * 100`.

### 3.4 Request sang ZaloPay

```json
{
  "app_id": 2553,
  "app_user": "user_1001",
  "app_time": 1780488000000,
  "amount": 10000,
  "app_trans_id": "260603_ORDER_20260603_0001",
  "embed_data": "{\"redirecturl\":\"https://your-domain.com/payment/zalopay/return\"}",
  "item": "[{\"itemid\":\"ORDER_20260603_0001\",\"itemname\":\"Order ORDER_20260603_0001\",\"itemprice\":10000,\"itemquantity\":1}]",
  "description": "Thanh toan don hang ORDER_20260603_0001",
  "callback_url": "https://your-domain.com/api/payments/zalopay/callback",
  "mac": "HMAC_SHA256_MAC"
}
```

Raw signature:

```text
app_id|app_trans_id|app_user|amount|app_time|embed_data|item
```

Điểm cần nhớ:

- Backend gọi `/v2/create`.
- Amount là VND trực tiếp.
- `app_trans_id` nên theo format `yyMMdd_orderId`.
- ZaloPay trả `order_url`.

## 4. Response tạo thanh toán khác nhau

### 4.1 Response chung backend nên trả cho frontend

Dù provider khác nhau, frontend nên nhận một format chung:

```json
{
  "provider": "MOMO",
  "paymentId": "PAY_10001",
  "orderId": "ORDER_20260603_0001",
  "gatewayTxnRef": "ORDER_20260603_0001",
  "amount": 10000,
  "paymentUrl": "https://provider-payment-url",
  "status": "PENDING"
}
```

DTO gợi ý:

```java
public record CreatePaymentResult(
        PaymentProvider provider,
        String paymentId,
        String orderId,
        String gatewayTxnRef,
        Long amount,
        String paymentUrl,
        PaymentStatus status
) {
}
```

### 4.2 MoMo response create

```json
{
  "partnerCode": "MOMO_TEST_PARTNER_CODE",
  "orderId": "ORDER_20260603_0001",
  "requestId": "REQ_ORDER_20260603_0001",
  "amount": 10000,
  "message": "Successful.",
  "resultCode": 0,
  "payUrl": "https://test-payment.momo.vn/v2/gateway/pay?...",
  "deeplink": "momo://app?...",
  "qrCodeUrl": "000201..."
}
```

Mapping:

- `paymentUrl = payUrl`
- `gatewayTxnRef = orderId`
- `success create = resultCode == 0`

### 4.3 VNPAY response create

VNPAY không có response create từ provider.

Backend tự trả:

```json
{
  "provider": "VNPAY",
  "orderId": "ORDER_20260603_0001",
  "gatewayTxnRef": "ORDER_20260603_0001",
  "amount": 10000,
  "paymentUrl": "https://sandbox.vnpayment.vn/paymentv2/vpcpay.html?...",
  "status": "PENDING"
}
```

Mapping:

- `paymentUrl = generated VNPAY URL`
- `gatewayTxnRef = vnp_TxnRef`
- `success create = build URL thành công`

### 4.4 ZaloPay response create

```json
{
  "return_code": 1,
  "return_message": "Giao dịch thành công",
  "sub_return_code": 1,
  "sub_return_message": "Giao dịch thành công",
  "order_url": "https://qcgateway.zalopay.vn/openinapp?order=...",
  "zp_trans_token": "TOKEN_SAMPLE",
  "order_token": "ORDER_TOKEN_SAMPLE"
}
```

Mapping:

- `paymentUrl = order_url`
- `gatewayTxnRef = app_trans_id`
- `success create = return_code == 1`

## 5. Callback/IPN khác nhau

### 5.1 Callback chung nên xử lý thành event nội bộ

```java
public record PaymentCallbackResult(
        PaymentProvider provider,
        String gatewayTxnRef,
        String gatewayTransactionNo,
        Long amount,
        PaymentStatus status,
        boolean validSignature,
        String rawPayload
) {
}
```

### 5.2 MoMo IPN

Đặc điểm:

- Method: `POST`
- Content-Type: `application/json`
- Verify bằng `secretKey`
- Check `partnerCode`, `orderId`, `amount`
- Thành công khi `resultCode == 0`

Field chính:

```text
partnerCode
orderId
requestId
amount
transId
resultCode
message
signature
```

Response backend nên trả:

```text
HTTP 204 No Content
```

### 5.3 VNPAY IPN

Đặc điểm:

- Thường là `GET` query params
- Verify `vnp_SecureHash` bằng `vnp_HashSecret`
- Check `vnp_TmnCode`, `vnp_TxnRef`, `vnp_Amount`
- Thành công khi `vnp_ResponseCode=00` và `vnp_TransactionStatus=00`

Field chính:

```text
vnp_TmnCode
vnp_TxnRef
vnp_Amount
vnp_ResponseCode
vnp_TransactionStatus
vnp_TransactionNo
vnp_SecureHash
```

Response backend:

```json
{
  "RspCode": "00",
  "Message": "Confirm Success"
}
```

### 5.4 ZaloPay callback

Đặc điểm:

- Method: `POST`
- Content-Type: `application/json`
- Body gồm `data`, `mac`, `type`
- Verify callback bằng `key2`, không dùng `key1`
- Parse JSON trong `data`
- Thành công khi `status == 1`

Field chính trong `data`:

```text
app_id
app_trans_id
amount
zp_trans_id
status
server_time
```

Response backend:

```json
{
  "return_code": 1,
  "return_message": "success"
}
```

## 6. Query/đối soát khác nhau

| Gateway | Khi nào query | Endpoint | Key ký |
|---|---|---|---|
| MoMo | IPN chưa tới, payment pending lâu | API query theo docs MoMo | `secretKey` |
| VNPAY | ReturnUrl có nhưng IPN chưa tới, pending lâu | QueryDR | `vnp_HashSecret` |
| ZaloPay | Callback miss, pending lâu | `/v2/query` | `key1` |

Rule:

- Query chỉ là cơ chế kiểm tra lại.
- Không dùng query thay hoàn toàn callback/IPN trong flow bình thường.
- Nên có scheduled job query các payment `PENDING` quá lâu.

## 7. Model database chung

```sql
create table payment_transaction (
    id bigint primary key,
    provider varchar(30) not null,
    order_id varchar(100) not null,
    gateway_txn_ref varchar(120) not null,
    gateway_transaction_no varchar(120),
    amount bigint not null,
    currency varchar(10) not null,
    status varchar(30) not null,
    payment_url text,
    request_payload text,
    response_payload text,
    callback_payload text,
    created_at timestamp not null,
    updated_at timestamp not null,
    paid_at timestamp,
    unique (provider, gateway_txn_ref)
);
```

Enum gợi ý:

```java
public enum PaymentProvider {
    MOMO,
    VNPAY,
    ZALOPAY
}

public enum PaymentStatus {
    PENDING,
    SUCCESS,
    FAILED,
    EXPIRED,
    REVIEW
}
```

Mapping `gateway_txn_ref`:

| Gateway | gateway_txn_ref |
|---|---|
| MoMo | `orderId` |
| VNPAY | `vnp_TxnRef` |
| ZaloPay | `app_trans_id` |

Mapping `gateway_transaction_no`:

| Gateway | gateway_transaction_no |
|---|---|
| MoMo | `transId` |
| VNPAY | `vnp_TransactionNo` |
| ZaloPay | `zp_trans_id` |

## 8. Class design gợi ý

### 8.1 Interface chính

```java
public interface PaymentGateway {

    PaymentProvider provider();

    CreatePaymentResult createPayment(CreatePaymentCommand command);

    PaymentCallbackResult handleCallback(PaymentCallbackRequest request);

    PaymentQueryResult queryPayment(String gatewayTxnRef);
}
```

### 8.2 Adapter theo provider

```text
payment/
  application/
    PaymentService.java
    PaymentGateway.java
    PaymentGatewayFactory.java
    CreatePaymentCommand.java
    CreatePaymentResult.java
    PaymentCallbackRequest.java
    PaymentCallbackResult.java
    PaymentQueryResult.java
  infrastructure/
    momo/
      MomoPaymentGateway.java
      MomoProperties.java
      MomoSigner.java
      MomoDtos.java
    vnpay/
      VnpayPaymentGateway.java
      VnpayProperties.java
      VnpaySigner.java
      VnpayDtos.java
    zalopay/
      ZaloPayPaymentGateway.java
      ZaloPayProperties.java
      ZaloPaySigner.java
      ZaloPayDtos.java
```

### 8.3 PaymentService orchestration

```java
public class PaymentService {

    private final PaymentGatewayFactory gatewayFactory;
    private final PaymentTransactionRepository transactionRepository;

    public CreatePaymentResult createPayment(CreatePaymentCommand command) {
        PaymentGateway gateway = gatewayFactory.get(command.provider());

        PaymentTransaction tx = transactionRepository.createPending(
                command.provider(),
                command.orderId(),
                command.amount()
        );

        CreatePaymentResult result = gateway.createPayment(command);

        transactionRepository.attachGatewayInfo(
                tx.id(),
                result.gatewayTxnRef(),
                result.paymentUrl()
        );

        return result;
    }

    public void confirmCallback(PaymentCallbackResult callback) {
        if (!callback.validSignature()) {
            transactionRepository.markReview(callback.gatewayTxnRef(), "INVALID_SIGNATURE");
            return;
        }

        PaymentTransaction tx = transactionRepository.findByProviderAndGatewayTxnRef(
                callback.provider(),
                callback.gatewayTxnRef()
        );

        if (!tx.amount().equals(callback.amount())) {
            transactionRepository.markReview(tx.id(), "AMOUNT_MISMATCH");
            return;
        }

        transactionRepository.updateStatus(
                tx.id(),
                callback.status(),
                callback.gatewayTransactionNo(),
                callback.rawPayload()
        );
    }
}
```

## 9. Các bước chung khi tạo thanh toán

### Step chung

1. Frontend gửi `provider`, `orderId`, `amount`.
2. Backend validate order có tồn tại và chưa thanh toán.
3. Backend tạo `payment_transaction` status `PENDING`.
4. Backend gọi adapter theo provider.
5. Adapter tạo request/signature/payment URL.
6. Backend lưu `gateway_txn_ref`, `payment_url`, request/response raw.
7. Backend trả `paymentUrl` cho frontend.
8. Frontend redirect user.
9. Provider gọi callback/IPN.
10. Backend verify signature.
11. Backend đối chiếu amount/order/provider với DB.
12. Backend cập nhật `SUCCESS/FAILED/REVIEW`.
13. Frontend đọc trạng thái từ backend, không tự mark paid.

### Khác biệt từng provider trong bước create

| Step | MoMo | VNPAY | ZaloPay |
|---|---|---|---|
| Tạo gateway ref | `orderId` hoặc `requestId` | `vnp_TxnRef` | `app_trans_id` |
| Build payload | JSON body | Query params | JSON/form body |
| Ký | HMAC SHA256 raw string | HMAC SHA512 sorted query | HMAC SHA256 raw string |
| Gọi provider | Có | Không | Có |
| URL trả frontend | `payUrl` | Generated URL | `order_url` |

## 10. Checklist thiết kế class

- Không để controller gọi trực tiếp MoMo/VNPAY/ZaloPay client.
- Không để frontend biết secret/key/provider config.
- Có interface `PaymentGateway`.
- Có adapter riêng cho từng provider.
- Có signer riêng cho từng provider.
- Có DTO raw request/response riêng cho từng provider.
- Có DTO chung trả frontend.
- Có bảng `payment_transaction` chung.
- Callback/IPN phải idempotent.
- Verify signature trước khi parse/update sâu.
- Check amount trong DB trước khi mark `SUCCESS`.
- Lưu raw payload để debug/đối soát.
- Có job query payment `PENDING` lâu.
- Có status `REVIEW` cho case lệch tiền, invalid signature, duplicate callback bất thường.

## 11. Nên lưu config payment ở DB hay properties?

### 11.1 Kết luận leader

Không nên chọn cực đoan “tất cả trong DB” hoặc “tất cả trong properties”.

Phương án ổn và an toàn hơn:

- Secret/key thật không lưu trực tiếp trong DB plaintext.
- Secret/key thật không commit vào `application.yml`.
- Secret nên lấy từ environment variable, Kubernetes Secret, Docker Secret, Vault, AWS Secrets Manager hoặc hệ thống secret manager tương đương.
- DB chỉ nên lưu config vận hành không quá nhạy cảm hoặc config cần thay đổi runtime.
- `application.yml` chỉ nên lưu default config, endpoint sandbox/dev, hoặc placeholder đọc từ env.

Rule ngắn:

```text
Secret nằm trong Secret Manager/env.
Config public/runtime nằm trong DB.
Default config nằm trong properties.
```

### 11.2 Phân loại config

| Loại thông tin | Ví dụ | Nên lưu ở đâu | Lý do |
|---|---|---|---|
| Secret ký request/callback | MoMo `secretKey`, VNPAY `vnp_HashSecret`, ZaloPay `key1`, `key2` | Secret Manager/env | Đây là credential nhạy cảm nhất, lộ là có thể giả mạo callback/signature |
| Access credential ít nhạy hơn nhưng vẫn private | MoMo `accessKey`, `partnerCode`, VNPAY `tmnCode`, ZaloPay `appId` | Env hoặc DB encrypted | Không nguy hiểm như secret nhưng vẫn không nên public bừa bãi |
| Endpoint provider | MoMo endpoint, VNPAY pay-url, ZaloPay create-endpoint | Properties hoặc DB | Có thể đổi theo môi trường, không phải secret |
| Callback/return URL | `redirectUrl`, `ipnUrl`, `returnUrl`, `callbackUrl` | Properties hoặc DB | Không phải secret, nhưng cần đúng theo môi trường |
| Feature flag | Bật/tắt MoMo/VNPAY/ZaloPay | DB | Team vận hành có thể bật/tắt không cần deploy |
| Routing rule | Đơn hàng nào dùng gateway nào | DB | Đây là nghiệp vụ/runtime config |
| Fee/rate/cost | Phí gateway, ưu tiên cổng | DB | Có thể thay đổi theo hợp đồng hoặc chiến dịch |
| Timeout/retry | timeout seconds, retry count | Properties hoặc DB | Nếu cần đổi runtime thì DB, nếu ít đổi thì properties |
| Sandbox test config | endpoint sandbox, app id test | Properties dev | Dễ setup local, không dùng cho production |

### 11.3 Không nên làm

- Không commit `secretKey`, `vnp_HashSecret`, `key1`, `key2` vào Git.
- Không lưu secret plaintext trong bảng `payment_gateway_config`.
- Không trả config provider xuống frontend.
- Không để admin UI hiển thị secret đầy đủ.
- Không dùng chung key production cho local/dev.
- Không đổi secret runtime nếu chưa có kế hoạch reload cache và rollback.

### 11.4 Thiết kế DB config gợi ý

Nếu hệ thống cần bật/tắt gateway, routing, hoặc config theo merchant/tenant, có thể tạo bảng:

```sql
create table payment_gateway_config (
    id bigint primary key,
    provider varchar(30) not null,
    environment varchar(20) not null,
    enabled boolean not null,
    display_name varchar(100) not null,
    endpoint_base_url varchar(500),
    return_url varchar(500),
    callback_url varchar(500),
    public_merchant_id varchar(120),
    secret_ref varchar(300),
    timeout_seconds int not null,
    priority int not null,
    config_json text,
    created_at timestamp not null,
    updated_at timestamp not null,
    unique (provider, environment)
);
```

Ý nghĩa:

- `provider`: `MOMO`, `VNPAY`, `ZALOPAY`.
- `environment`: `SANDBOX`, `PRODUCTION`.
- `enabled`: bật/tắt gateway.
- `public_merchant_id`: lưu `partnerCode`, `tmnCode`, `appId` nếu team chấp nhận lưu DB.
- `secret_ref`: key/path trỏ tới Secret Manager, không phải secret thật.
- `config_json`: field linh hoạt cho config ít dùng.

Ví dụ `secret_ref`:

```text
secret/payment/momo/production
secret/payment/vnpay/production
secret/payment/zalopay/production
```

### 11.5 Nếu chưa có Secret Manager thì làm sao?

Giai đoạn đầu có thể dùng environment variables:

```yaml
payment:
  momo:
    secret-key: ${MOMO_SECRET_KEY}
  vnpay:
    hash-secret: ${VNPAY_HASH_SECRET}
  zalopay:
    key1: ${ZALOPAY_KEY1}
    key2: ${ZALOPAY_KEY2}
```

Deploy bằng Docker/Kubernetes:

```text
MOMO_SECRET_KEY=...
VNPAY_HASH_SECRET=...
ZALOPAY_KEY1=...
ZALOPAY_KEY2=...
```

Đây là phương án đơn giản, an toàn hơn commit vào file properties, và dễ nâng cấp lên Secret Manager sau.

### 11.6 Class đọc config gợi ý

Tách config thành 2 lớp:

```text
GatewayRuntimeConfig
  - lấy từ DB
  - enabled, endpoint, callbackUrl, returnUrl, priority, timeout

GatewaySecret
  - lấy từ env/secret manager
  - secretKey/hashSecret/key1/key2
```

Ví dụ:

```java
public record GatewayRuntimeConfig(
        PaymentProvider provider,
        boolean enabled,
        String endpointBaseUrl,
        String returnUrl,
        String callbackUrl,
        String publicMerchantId,
        int timeoutSeconds,
        int priority
) {
}

public record GatewaySecret(
        PaymentProvider provider,
        String signingKey,
        String callbackVerifyKey
) {
}
```

Mapping theo provider:

| Gateway | `signingKey` | `callbackVerifyKey` |
|---|---|---|
| MoMo | `secretKey` | `secretKey` |
| VNPAY | `vnp_HashSecret` | `vnp_HashSecret` |
| ZaloPay | `key1` | `key2` |

### 11.7 Khi nào nên dùng DB config?

Dùng DB config khi:

- Có nhiều merchant/tenant.
- Cần bật/tắt gateway không cần deploy.
- Cần routing động: ví dụ đơn nhỏ dùng MoMo, đơn ngân hàng dùng VNPAY.
- Cần thay callback URL theo domain/tenant.
- Cần admin page quản lý payment gateway.

Chưa cần DB config khi:

- Chỉ có một merchant.
- Chỉ có một môi trường deploy đơn giản.
- Team chưa có yêu cầu bật/tắt runtime.
- Config ít thay đổi và deploy lại không phải vấn đề.

### 11.8 Khuyến nghị thực tế cho project Spring Boot

Giai đoạn 1:

- Lưu endpoint/callback/default config trong `application.yml`.
- Lưu secret bằng environment variables.
- Không tạo bảng config nếu chưa cần runtime update.

Giai đoạn 2:

- Tạo bảng `payment_gateway_config` để quản lý enabled/routing/priority.
- Vẫn giữ secret ở Secret Manager/env.
- Cache config DB trong app, có TTL hoặc endpoint reload nội bộ.

Giai đoạn 3:

- Dùng Secret Manager chính thức.
- Có audit log khi đổi config.
- Có approval flow khi đổi gateway production.

## 12. Quy tắc quan trọng nhất

```text
ReturnUrl/redirectUrl/redirecturl chỉ phục vụ trải nghiệm user.
IPN/callback server-to-server sau verify signature mới là nguồn cập nhật payment status chuẩn.
```
