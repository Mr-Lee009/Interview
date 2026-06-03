# Payment Gateway Class Design

File này mô tả thiết kế class cho tính năng thanh toán nhiều cổng: MoMo, VNPAY, ZaloPay.

Mục tiêu:

- Business code không phụ thuộc trực tiếp vào từng cổng thanh toán.
- Mỗi gateway có adapter riêng.
- Config có thể lấy từ DB/properties/env.
- Secret/key được quản lý tách khỏi config thường.
- Callback/IPN xử lý idempotent và verify chữ ký trước khi update DB.

## 1. Cấu hình cần thiết cho từng cổng

### 1.1 Config chung

| Field | Dùng để làm gì? | Ghi chú |
|---|---|---|
| `provider` | Xác định cổng thanh toán | `MOMO`, `VNPAY`, `ZALOPAY` |
| `enabled` | Bật/tắt gateway | Lưu DB để vận hành bật/tắt không cần deploy |
| `environment` | Môi trường gateway | `SANDBOX`, `PRODUCTION` |
| `returnUrl` | URL user quay lại website | Không dùng để mark paid |
| `callbackUrl` | URL backend nhận IPN/callback | Dùng cập nhật trạng thái chuẩn |
| `timeoutSeconds` | Timeout khi gọi provider API | Tránh request treo quá lâu |
| `priority` | Ưu tiên chọn gateway | Dùng khi hệ thống tự routing |
| `configJson` | Config phụ theo provider | Ví dụ locale, requestType, expireMinutes |

### 1.2 MoMo config

| Field | Dùng để làm gì? | Nên lưu ở đâu? |
|---|---|---|
| `endpoint` | API tạo thanh toán MoMo | DB/properties |
| `partnerCode` | Mã merchant MoMo | DB hoặc env |
| `accessKey` | Key nằm trong raw signature | Env hoặc DB encrypted |
| `secretKey` | Key ký request và verify IPN | Secret Manager/env |
| `requestType` | Loại request thanh toán | `captureWallet`, `payWithMethod` |
| `redirectUrl` | URL user quay về website | DB/properties |
| `ipnUrl` | URL backend nhận IPN | DB/properties |
| `lang` | Ngôn ngữ checkout | `vi`, `en` |

### 1.3 VNPAY config

| Field | Dùng để làm gì? | Nên lưu ở đâu? |
|---|---|---|
| `payUrl` | Base URL để build payment URL | DB/properties |
| `queryUrl` | API QueryDR/đối soát | DB/properties |
| `tmnCode` | Mã website merchant | DB hoặc env |
| `hashSecret` | Key ký `vnp_SecureHash` | Secret Manager/env |
| `returnUrl` | URL user quay về website | DB/properties |
| `ipnUrl` | URL backend nhận IPN | DB/properties |
| `version` | Version API | Thường `2.1.0` |
| `command` | Command thanh toán | Thường `pay` |
| `currCode` | Loại tiền | `VND` |
| `locale` | Ngôn ngữ checkout | `vn`, `en` |
| `orderType` | Loại đơn hàng | Ví dụ `other` |
| `expireMinutes` | Thời gian hết hạn thanh toán | Ví dụ `15` phút |

### 1.4 ZaloPay config

| Field | Dùng để làm gì? | Nên lưu ở đâu? |
|---|---|---|
| `createEndpoint` | API tạo order ZaloPay | DB/properties |
| `queryEndpoint` | API query order | DB/properties |
| `appId` | App id merchant | DB hoặc env |
| `key1` | Key ký create/query | Secret Manager/env |
| `key2` | Key verify callback | Secret Manager/env |
| `callbackUrl` | URL backend nhận callback | DB/properties |
| `redirectUrl` | URL user quay về website | DB/properties |
| `defaultAppUser` | User fallback khi không có userId | Properties/DB |

## 2. Cấu trúc thư mục gợi ý

```text
payment/
  application/
    PaymentService.java
    PaymentGateway.java
    PaymentGatewayFactory.java
    PaymentProvider.java
    PaymentStatus.java
    CreatePaymentCommand.java
    CreatePaymentResult.java
    PaymentCallbackRequest.java
    PaymentCallbackResult.java
    PaymentQueryResult.java
    PaymentConfigService.java
    PaymentSecretService.java

  domain/
    PaymentTransaction.java
    PaymentTransactionRepository.java
    PaymentGatewayConfig.java
    PaymentGatewayConfigRepository.java

  infrastructure/
    momo/
      MomoPaymentGateway.java
      MomoProperties.java
      MomoSigner.java
      MomoClient.java
      MomoCreatePaymentRequest.java
      MomoCreatePaymentResponse.java
      MomoIpnRequest.java

    vnpay/
      VnpayPaymentGateway.java
      VnpayProperties.java
      VnpaySigner.java
      VnpayUrlBuilder.java
      VnpayIpnRequest.java
      VnpayQueryRequest.java
      VnpayQueryResponse.java

    zalopay/
      ZaloPayPaymentGateway.java
      ZaloPayProperties.java
      ZaloPaySigner.java
      ZaloPayClient.java
      ZaloPayCreateOrderRequest.java
      ZaloPayCreateOrderResponse.java
      ZaloPayCallbackRequest.java

  presentation/
    PaymentController.java
    PaymentCallbackController.java
    PaymentReturnController.java
```

## 3. Application layer

### 3.1 `PaymentProvider`

Class/enum này dùng để định danh gateway.

```java
public enum PaymentProvider {
    MOMO,
    VNPAY,
    ZALOPAY
}
```

### 3.2 `PaymentStatus`

Class/enum này dùng để chuẩn hóa trạng thái payment trong hệ thống.

```java
public enum PaymentStatus {
    PENDING,
    SUCCESS,
    FAILED,
    EXPIRED,
    REVIEW
}
```

Ý nghĩa:

| Status | Dùng khi nào? |
|---|---|
| `PENDING` | Đã tạo payment, chờ user thanh toán hoặc chờ callback |
| `SUCCESS` | Gateway xác nhận thành công và backend verify hợp lệ |
| `FAILED` | Gateway báo thất bại |
| `EXPIRED` | Quá hạn thanh toán |
| `REVIEW` | Có bất thường, cần kiểm tra thủ công |

### 3.3 `CreatePaymentCommand`

Class này là input chung khi business muốn tạo thanh toán.

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

Function/field:

| Field | Dùng để làm gì? |
|---|---|
| `provider` | Chọn gateway cần thanh toán |
| `orderId` | Mã đơn hàng nội bộ |
| `userId` | User đang thanh toán |
| `amount` | Số tiền VND gốc |
| `description` | Mô tả đơn hàng |
| `returnUrl` | URL user quay lại sau thanh toán nếu cần override |

### 3.4 `CreatePaymentResult`

Class này là output chung trả về cho frontend.

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

Field:

| Field | Dùng để làm gì? |
|---|---|
| `provider` | Gateway đã tạo payment |
| `paymentId` | ID payment transaction nội bộ |
| `orderId` | Mã đơn hàng nội bộ |
| `gatewayTxnRef` | Mã giao dịch phía gateway |
| `amount` | Số tiền |
| `paymentUrl` | URL để frontend redirect user |
| `status` | Thường là `PENDING` sau khi tạo |

### 3.5 `PaymentCallbackRequest`

Class này đại diện request callback/IPN raw từ provider.

```java
public record PaymentCallbackRequest(
        PaymentProvider provider,
        Map<String, String> headers,
        Map<String, String> queryParams,
        String body
) {
}
```

Field:

| Field | Dùng để làm gì? |
|---|---|
| `provider` | Xác định callback thuộc gateway nào |
| `headers` | Header raw nếu gateway cần |
| `queryParams` | Query params, đặc biệt cần cho VNPAY IPN |
| `body` | Body raw, đặc biệt cần cho MoMo/ZaloPay |

### 3.6 `PaymentCallbackResult`

Class này là kết quả sau khi adapter parse và verify callback.

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

Field:

| Field | Dùng để làm gì? |
|---|---|
| `gatewayTxnRef` | Tìm payment transaction trong DB |
| `gatewayTransactionNo` | Mã giao dịch thật provider trả về |
| `amount` | Đối chiếu với DB |
| `status` | Trạng thái chuẩn hóa |
| `validSignature` | Cho biết chữ ký có hợp lệ không |
| `rawPayload` | Lưu audit/debug |

### 3.7 `PaymentGateway`

Interface chính cho mọi gateway adapter.

```java
public interface PaymentGateway {

    PaymentProvider provider();

    CreatePaymentResult createPayment(CreatePaymentCommand command);

    PaymentCallbackResult handleCallback(PaymentCallbackRequest request);

    PaymentQueryResult queryPayment(String gatewayTxnRef);
}
```

Function:

| Function | Dùng để làm gì? |
|---|---|
| `provider()` | Trả về gateway mà adapter hỗ trợ |
| `createPayment()` | Tạo payment và trả URL redirect |
| `handleCallback()` | Parse, verify, map callback/IPN về result chung |
| `queryPayment()` | Hỏi lại trạng thái giao dịch từ provider |

### 3.8 `PaymentGatewayFactory`

Class này chọn adapter theo provider.

```java
public class PaymentGatewayFactory {

    private final Map<PaymentProvider, PaymentGateway> gateways;

    public PaymentGateway get(PaymentProvider provider) {
        PaymentGateway gateway = gateways.get(provider);
        if (gateway == null) {
            throw new IllegalArgumentException("Unsupported payment provider: " + provider);
        }
        return gateway;
    }
}
```

Function:

| Function | Dùng để làm gì? |
|---|---|
| `get(provider)` | Lấy adapter tương ứng MoMo/VNPAY/ZaloPay |

### 3.9 `PaymentService`

Class orchestration chính của tính năng payment.

Nhiệm vụ:

- Validate order.
- Tạo payment transaction `PENDING`.
- Gọi gateway adapter.
- Lưu request/response.
- Xử lý callback idempotent.
- Update trạng thái DB.

Function gợi ý:

```java
public class PaymentService {

    public CreatePaymentResult createPayment(CreatePaymentCommand command) {
        // 1. Validate order tồn tại và amount đúng.
        // 2. Tạo payment_transaction PENDING.
        // 3. Lấy adapter bằng PaymentGatewayFactory.
        // 4. Gọi adapter.createPayment(command).
        // 5. Lưu gatewayTxnRef/paymentUrl/raw response.
        // 6. Trả paymentUrl cho frontend.
    }

    public void confirmCallback(PaymentCallbackRequest request) {
        // 1. Lấy adapter theo provider.
        // 2. Gọi adapter.handleCallback(request).
        // 3. Nếu signature sai, mark REVIEW.
        // 4. Tìm payment_transaction bằng provider + gatewayTxnRef.
        // 5. Check amount.
        // 6. Update SUCCESS/FAILED.
        // 7. Đảm bảo idempotent nếu callback gọi lại.
    }

    public PaymentQueryResult queryPayment(PaymentProvider provider, String gatewayTxnRef) {
        // 1. Lấy adapter theo provider.
        // 2. Gọi API query provider.
        // 3. Map response về PaymentQueryResult.
        // 4. Dùng cho đối soát payment PENDING lâu.
    }
}
```

## 4. Domain layer

### 4.1 `PaymentTransaction`

Entity lưu giao dịch thanh toán.

Field chính:

| Field | Dùng để làm gì? |
|---|---|
| `id` | ID nội bộ |
| `provider` | Gateway thanh toán |
| `orderId` | Đơn hàng nội bộ |
| `gatewayTxnRef` | Mã giao dịch phía gateway |
| `gatewayTransactionNo` | Mã giao dịch provider trả sau khi thanh toán |
| `amount` | Số tiền gốc |
| `currency` | Loại tiền |
| `status` | Trạng thái payment |
| `paymentUrl` | URL redirect user |
| `requestPayload` | Raw request |
| `responsePayload` | Raw response |
| `callbackPayload` | Raw callback/IPN |
| `createdAt` | Thời điểm tạo |
| `updatedAt` | Thời điểm update |
| `paidAt` | Thời điểm paid |

### 4.2 `PaymentTransactionRepository`

Repository thao tác bảng `payment_transaction`.

Function:

| Function | Dùng để làm gì? |
|---|---|
| `createPending()` | Tạo payment status `PENDING` |
| `attachGatewayInfo()` | Lưu `gatewayTxnRef`, `paymentUrl`, raw response |
| `findByProviderAndGatewayTxnRef()` | Tìm payment khi nhận callback/IPN |
| `markSuccess()` | Cập nhật `SUCCESS` |
| `markFailed()` | Cập nhật `FAILED` |
| `markReview()` | Cập nhật `REVIEW` khi signature sai/lệch amount |
| `findPendingTooLong()` | Lấy danh sách payment cần query đối soát |

### 4.3 `PaymentGatewayConfig`

Entity lưu config runtime của gateway.

Field:

| Field | Dùng để làm gì? |
|---|---|
| `provider` | Gateway |
| `environment` | Sandbox/production |
| `enabled` | Bật/tắt gateway |
| `endpointBaseUrl` | Endpoint provider |
| `returnUrl` | User redirect URL |
| `callbackUrl` | Backend callback/IPN URL |
| `publicMerchantId` | Merchant id không phải secret |
| `secretRef` | Tham chiếu tới secret manager/env |
| `timeoutSeconds` | Timeout provider call |
| `priority` | Ưu tiên routing |
| `configJson` | Config phụ |

### 4.4 `PaymentGatewayConfigRepository`

Repository thao tác config gateway.

Function:

| Function | Dùng để làm gì? |
|---|---|
| `findEnabledByProvider()` | Lấy config đang bật cho provider |
| `findAllEnabled()` | Lấy tất cả gateway đang bật |
| `save()` | Lưu config runtime |
| `disable()` | Tắt gateway |
| `updatePriority()` | Đổi ưu tiên routing |

## 5. Config/secret service

### 5.1 `PaymentConfigService`

Class này đọc config runtime từ DB/properties.

Function:

| Function | Dùng để làm gì? |
|---|---|
| `getRuntimeConfig(provider)` | Lấy endpoint, callbackUrl, returnUrl, timeout |
| `isEnabled(provider)` | Kiểm tra gateway có bật không |
| `reload()` | Reload config cache nếu có admin thay đổi |

### 5.2 `PaymentSecretService`

Class này lấy secret từ env/Secret Manager hoặc DB encrypted.

Function:

| Function | Dùng để làm gì? |
|---|---|
| `getSigningKey(provider)` | Lấy key ký create/query |
| `getCallbackVerifyKey(provider)` | Lấy key verify callback/IPN |
| `decryptIfNeeded()` | Decrypt secret nếu lưu DB encrypted |
| `rotateKey()` | Hỗ trợ rotate key nếu có |

Mapping key:

| Gateway | Signing key | Callback verify key |
|---|---|---|
| MoMo | `secretKey` | `secretKey` |
| VNPAY | `vnp_HashSecret` | `vnp_HashSecret` |
| ZaloPay | `key1` | `key2` |

## 6. MoMo adapter

### 6.1 `MomoPaymentGateway`

Adapter tích hợp MoMo.

Function:

| Function | Dùng để làm gì? |
|---|---|
| `provider()` | Trả `MOMO` |
| `createPayment(command)` | Build request MoMo, ký signature, gọi API create, map `payUrl` |
| `handleCallback(request)` | Parse IPN JSON, verify signature, map `resultCode` sang status |
| `queryPayment(gatewayTxnRef)` | Query trạng thái MoMo nếu cần đối soát |

### 6.2 `MomoSigner`

Class tạo và verify chữ ký MoMo.

Function:

| Function | Dùng để làm gì? |
|---|---|
| `signCreateRequest()` | Tạo signature cho API create |
| `verifyIpn()` | Verify signature IPN |
| `hmacSha256()` | Hàm ký HMAC SHA256 dùng chung |

### 6.3 `MomoClient`

Class gọi HTTP tới MoMo.

Function:

| Function | Dùng để làm gì? |
|---|---|
| `createPayment(request)` | Gọi `POST /v2/gateway/api/create` |
| `queryPayment(request)` | Gọi API query nếu cần |

### 6.4 DTO MoMo

| Class | Dùng để làm gì? |
|---|---|
| `MomoCreatePaymentRequest` | Body gửi sang MoMo create |
| `MomoCreatePaymentResponse` | Response MoMo trả về, lấy `payUrl` |
| `MomoIpnRequest` | Body IPN MoMo gửi về backend |

## 7. VNPAY adapter

### 7.1 `VnpayPaymentGateway`

Adapter tích hợp VNPAY.

Function:

| Function | Dùng để làm gì? |
|---|---|
| `provider()` | Trả `VNPAY` |
| `createPayment(command)` | Build params, ký `vnp_SecureHash`, trả generated payment URL |
| `handleCallback(request)` | Parse IPN query params, verify secure hash, map response code sang status |
| `queryPayment(gatewayTxnRef)` | Gọi QueryDR để đối soát |

### 7.2 `VnpaySigner`

Class tạo và verify chữ ký VNPAY.

Function:

| Function | Dùng để làm gì? |
|---|---|
| `buildHashData(params)` | Sort params và build raw data |
| `signHmacSha512(hashData)` | Ký `vnp_SecureHash` |
| `verifySecureHash(params)` | Verify IPN/ReturnUrl |

### 7.3 `VnpayUrlBuilder`

Class build payment URL.

Function:

| Function | Dùng để làm gì? |
|---|---|
| `buildPaymentUrl(command)` | Tạo full URL `paymentv2/vpcpay.html?...` |
| `buildParams(command)` | Tạo map `vnp_*` params |
| `encodeParams(params)` | Encode query string |

### 7.4 DTO VNPAY

| Class | Dùng để làm gì? |
|---|---|
| `VnpayIpnRequest` | Query params VNPAY IPN |
| `VnpayQueryRequest` | Request QueryDR |
| `VnpayQueryResponse` | Response QueryDR |

## 8. ZaloPay adapter

### 8.1 `ZaloPayPaymentGateway`

Adapter tích hợp ZaloPay.

Function:

| Function | Dùng để làm gì? |
|---|---|
| `provider()` | Trả `ZALOPAY` |
| `createPayment(command)` | Build create order, ký mac bằng `key1`, gọi `/v2/create`, map `order_url` |
| `handleCallback(request)` | Parse callback body, verify mac bằng `key2`, map status |
| `queryPayment(gatewayTxnRef)` | Gọi `/v2/query` để đối soát |

### 8.2 `ZaloPaySigner`

Class tạo và verify mac ZaloPay.

Function:

| Function | Dùng để làm gì? |
|---|---|
| `signCreateOrder()` | Ký request create bằng `key1` |
| `verifyCallback()` | Verify callback bằng `key2` |
| `signQuery()` | Ký query bằng `key1` |
| `hmacSha256()` | Hàm ký HMAC SHA256 dùng chung |

### 8.3 `ZaloPayClient`

Class gọi HTTP tới ZaloPay.

Function:

| Function | Dùng để làm gì? |
|---|---|
| `createOrder(request)` | Gọi `POST /v2/create` |
| `queryOrder(request)` | Gọi `POST /v2/query` |

### 8.4 DTO ZaloPay

| Class | Dùng để làm gì? |
|---|---|
| `ZaloPayCreateOrderRequest` | Body create order |
| `ZaloPayCreateOrderResponse` | Response create, lấy `order_url` |
| `ZaloPayCallbackRequest` | Body callback gồm `data`, `mac`, `type` |

## 9. Presentation layer

### 9.1 `PaymentController`

Controller cho frontend tạo thanh toán.

Endpoint:

```text
POST /api/payments/create
```

Function:

| Function | Dùng để làm gì? |
|---|---|
| `create()` | Nhận request từ frontend, gọi `PaymentService.createPayment()` |

### 9.2 `PaymentCallbackController`

Controller nhận callback/IPN từ gateway.

Endpoint gợi ý:

```text
POST /api/payments/momo/ipn
GET  /api/payments/vnpay/ipn
POST /api/payments/zalopay/callback
```

Function:

| Function | Dùng để làm gì? |
|---|---|
| `momoIpn()` | Nhận MoMo IPN, wrap thành `PaymentCallbackRequest` |
| `vnpayIpn()` | Nhận VNPAY query params, wrap thành `PaymentCallbackRequest` |
| `zaloPayCallback()` | Nhận ZaloPay callback body, wrap thành `PaymentCallbackRequest` |

### 9.3 `PaymentReturnController`

Controller xử lý user quay về website.

Endpoint:

```text
GET /payment/{provider}/return
```

Function:

| Function | Dùng để làm gì? |
|---|---|
| `returnPage()` | Hiển thị kết quả tạm thời cho user |
| `getPaymentStatus()` | Frontend poll trạng thái payment từ DB |

Lưu ý:

- Không mark `SUCCESS` trong return controller.
- Return controller chỉ phục vụ trải nghiệm user.

## 10. Flow triển khai từng bước

### 10.1 Tạo payment

```text
1. Frontend gọi POST /api/payments/create.
2. PaymentController map request thành CreatePaymentCommand.
3. PaymentService validate order và amount.
4. PaymentService tạo PaymentTransaction PENDING.
5. PaymentGatewayFactory lấy adapter theo provider.
6. Adapter build request/signature/payment URL.
7. Adapter trả CreatePaymentResult.
8. PaymentService lưu gatewayTxnRef/paymentUrl/raw payload.
9. Backend trả paymentUrl cho frontend.
10. Frontend redirect user sang paymentUrl.
```

### 10.2 Nhận callback/IPN

```text
1. Provider gọi endpoint callback/IPN.
2. PaymentCallbackController wrap raw request thành PaymentCallbackRequest.
3. PaymentService lấy adapter theo provider.
4. Adapter parse payload và verify signature.
5. Adapter trả PaymentCallbackResult.
6. PaymentService tìm PaymentTransaction bằng provider + gatewayTxnRef.
7. PaymentService check amount.
8. PaymentService update SUCCESS/FAILED/REVIEW.
9. Controller trả response đúng contract provider.
```

### 10.3 Query đối soát

```text
1. Scheduled job tìm payment PENDING quá lâu.
2. PaymentService gọi queryPayment(provider, gatewayTxnRef).
3. Adapter gọi API query của provider.
4. Adapter map response về PaymentQueryResult.
5. PaymentService update status nếu kết quả đã rõ.
6. Nếu vẫn chưa rõ, giữ PENDING hoặc chuyển REVIEW theo rule.
```

## 11. Checklist trước khi code

- Có bảng `payment_transaction`.
- Có bảng `payment_gateway_config` nếu dùng config DB.
- Secret không commit vào Git.
- Có `PaymentGateway` interface.
- Có adapter riêng cho MoMo/VNPAY/ZaloPay.
- Có signer riêng cho từng gateway.
- Có DTO chung và DTO riêng.
- Callback/IPN verify chữ ký trước khi update DB.
- Callback/IPN xử lý idempotent.
- Return URL không mark paid.
- Có query job cho payment pending lâu.
- Có raw payload để debug/đối soát.
- Có test case invalid signature, amount mismatch, duplicate callback.

