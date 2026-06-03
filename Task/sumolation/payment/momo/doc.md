# Tích hợp thanh toán MoMo cho Spring Boot

Tài liệu này hướng dẫn chọn phương án tích hợp MoMo cho website và cấu hình cơ bản cho ứng dụng Spring Boot.

Nguồn tham khảo chính:

- MoMo Developers - Thanh Toán Thông Thường: https://developers.momo.vn/v3/vi/docs/payment/api/wallet/onetime/
- MoMo Developers - Collection Link: https://developers.momo.vn/v3/vi/docs/payment/api/collection-link/
- MoMo Developers - Payment Notification/IPN: https://developers.momo.vn/v3/docs/payment/api/result-handling/notification/

## 1. Nên chọn phương án nào?

### Khuyến nghị cho website bán hàng phổ thông

- Nếu website của bạn chỉ cần khách thanh toán bằng ví MoMo:
  - Chọn `Thanh Toán Thông Thường`.
  - API chính: `POST /v2/gateway/api/create`.
  - `requestType = captureWallet`.
  - Backend Spring Boot tạo payment request, MoMo trả về `payUrl`, frontend redirect user sang `payUrl`.

- Nếu website cần nhiều phương thức thanh toán hơn:
  - Ví MoMo.
  - ATM/NAPAS.
  - Visa/Master/JCB.
  - Link thanh toán gửi qua SMS/Zalo/email.
  - Chọn `Collection Link`.
  - API vẫn là `POST /v2/gateway/api/create`, nhưng `requestType = payWithMethod`.

### Bảng chọn nhanh

| Nhu cầu | Nên chọn | Lý do |
|---|---|---|
| Website checkout đơn giản, thanh toán bằng ví MoMo | `captureWallet` | Dễ tích hợp, đúng flow checkout phổ biến |
| Muốn redirect khách sang trang MoMo để thanh toán | `captureWallet` | MoMo trả `payUrl`, frontend chỉ redirect |
| Muốn hỗ trợ ATM/thẻ quốc tế/link thanh toán | `payWithMethod` / Collection Link | Hỗ trợ nhiều phương thức hơn |
| Muốn tự hiển thị QR trên website | `captureWallet` nhưng cần quyền/field QR phù hợp | MoMo có trả `qrCodeUrl`, nhưng production có thể cần xin quyền |
| Hệ thống cần thanh toán có xác nhận/capture sau | Cần trao đổi thêm với MoMo | Không nên tự giả định flow nếu tiền thật |

### Kết luận leader

- Với website Spring Boot mới tích hợp lần đầu:
  - Bắt đầu bằng `captureWallet`.
  - Thiết kế code theo interface `PaymentGateway` để sau này thay bằng `payWithMethod`, VNPAY, ZaloPay, Stripe... không phải đập lại nghiệp vụ.
  - Không cập nhật order là `PAID` chỉ dựa vào `redirectUrl`.
  - Trạng thái thanh toán chuẩn phải dựa vào `ipnUrl` và xác minh chữ ký.

## 2. Luồng xử lý chuẩn

```text
User
  -> Website frontend
  -> Spring Boot backend: POST /api/payments/momo/create
  -> Backend tạo order/payment PENDING trong DB
  -> Backend gọi MoMo /v2/gateway/api/create
  -> MoMo trả payUrl
  -> Frontend redirect user sang payUrl
  -> User thanh toán trên MoMo
  -> MoMo redirect user về redirectUrl
  -> MoMo gọi server-to-server vào ipnUrl
  -> Backend verify signature IPN
  -> Backend check partnerCode/orderId/amount với DB
  -> Backend cập nhật payment SUCCESS/FAILED
```

## 3. Những field quan trọng của MoMo

Theo tài liệu MoMo, request tạo thanh toán dùng `POST /v2/gateway/api/create`.

Các field chính:

- `partnerCode`: mã đối tác MoMo.
- `accessKey`: key dùng trong raw signature.
- `secretKey`: key bí mật dùng tạo HMAC SHA256.
- `requestId`: định danh duy nhất cho mỗi request, dùng cho idempotency.
- `orderId`: mã đơn hàng phía merchant.
- `amount`: số tiền, đơn vị VND, kiểu `Long`.
- `orderInfo`: mô tả đơn hàng.
- `redirectUrl`: URL MoMo redirect user về website sau thanh toán.
- `ipnUrl`: URL backend nhận kết quả thanh toán server-to-server.
- `requestType`: `captureWallet` hoặc `payWithMethod`.
- `extraData`: chuỗi base64, có thể để rỗng `""`.
- `signature`: chữ ký HMAC SHA256.

Lưu ý từ tài liệu MoMo:

- Với `captureWallet`, amount tối thiểu là `1.000 VND`, tối đa `50.000.000 VND`.
- MoMo khuyến nghị timeout nhỏ nhất khi gọi API create nên là `30s`.
- IPN là `POST application/json`.
- Khi nhận IPN, backend cần trả HTTP `204 No Content`.
- Backend cần phản hồi IPN trong giới hạn `15s`.
- Cần validate chữ ký IPN và đối chiếu `partnerCode`, `orderId`, `amount` với database.

## 4. Cấu hình Spring Boot

### 4.1 `application.yml`

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

Production cần đổi:

- `endpoint` sang production endpoint do MoMo cấp.
- `partner-code`, `access-key`, `secret-key` sang thông tin production.
- `redirect-url` và `ipn-url` sang domain thật có HTTPS.

Không commit secret thật lên Git.

## 5. Dependency gợi ý

Nếu dùng Spring Boot 3:

```xml
<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>

    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-validation</artifactId>
    </dependency>

    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-data-jpa</artifactId>
    </dependency>
</dependencies>
```

Nếu không dùng JPA, vẫn nên lưu payment transaction vào database bằng JDBC/MyBatis hoặc persistence layer tương ứng.

## 6. Mapping config

```java
import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "payment.momo")
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

Enable configuration properties:

```java
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Configuration
@EnableConfigurationProperties(MomoProperties.class)
public class PaymentConfig {
}
```

## 7. DTO tạo payment

```java
import java.util.Map;

public record MomoCreatePaymentRequest(
        String partnerCode,
        String requestId,
        Long amount,
        String orderId,
        String orderInfo,
        String redirectUrl,
        String ipnUrl,
        String requestType,
        String extraData,
        String lang,
        String signature
) {
    public Map<String, Object> toMap() {
        return Map.of(
                "partnerCode", partnerCode,
                "requestId", requestId,
                "amount", amount,
                "orderId", orderId,
                "orderInfo", orderInfo,
                "redirectUrl", redirectUrl,
                "ipnUrl", ipnUrl,
                "requestType", requestType,
                "extraData", extraData,
                "lang", lang,
                "signature", signature
        );
    }
}
```

```java
public record MomoCreatePaymentResponse(
        String partnerCode,
        String orderId,
        String requestId,
        Long amount,
        Long responseTime,
        String message,
        Integer resultCode,
        String payUrl,
        String deeplink,
        String qrCodeUrl
) {
}
```

## 8. Tạo chữ ký HMAC SHA256

MoMo yêu cầu raw signature cho `captureWallet` theo format:

```text
accessKey=$accessKey&amount=$amount&extraData=$extraData
&ipnUrl=$ipnUrl&orderId=$orderId&orderInfo=$orderInfo
&partnerCode=$partnerCode&redirectUrl=$redirectUrl
&requestId=$requestId&requestType=$requestType
```

Code Java:

```java
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;

public final class HmacSha256 {

    private HmacSha256() {
    }

    public static String sign(String rawData, String secretKey) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            SecretKeySpec keySpec = new SecretKeySpec(
                    secretKey.getBytes(StandardCharsets.UTF_8),
                    "HmacSHA256"
            );
            mac.init(keySpec);
            byte[] hash = mac.doFinal(rawData.getBytes(StandardCharsets.UTF_8));
            return toHex(hash);
        } catch (Exception ex) {
            throw new IllegalStateException("Cannot create HMAC SHA256 signature", ex);
        }
    }

    private static String toHex(byte[] bytes) {
        StringBuilder result = new StringBuilder(bytes.length * 2);
        for (byte b : bytes) {
            result.append(String.format("%02x", b));
        }
        return result.toString();
    }
}
```

Builder raw signature:

```java
public final class MomoSignatureBuilder {

    private MomoSignatureBuilder() {
    }

    public static String createPaymentRawSignature(
            String accessKey,
            Long amount,
            String extraData,
            String ipnUrl,
            String orderId,
            String orderInfo,
            String partnerCode,
            String redirectUrl,
            String requestId,
            String requestType
    ) {
        return "accessKey=" + accessKey
                + "&amount=" + amount
                + "&extraData=" + extraData
                + "&ipnUrl=" + ipnUrl
                + "&orderId=" + orderId
                + "&orderInfo=" + orderInfo
                + "&partnerCode=" + partnerCode
                + "&redirectUrl=" + redirectUrl
                + "&requestId=" + requestId
                + "&requestType=" + requestType;
    }
}
```

## 9. Service gọi MoMo

Ví dụ dùng `RestClient` của Spring Boot 3:

```java
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

import java.util.UUID;

@Service
public class MomoPaymentService {

    private final MomoProperties properties;
    private final RestClient restClient;

    public MomoPaymentService(MomoProperties properties, RestClient.Builder builder) {
        this.properties = properties;
        this.restClient = builder.build();
    }

    public MomoCreatePaymentResponse createPayment(String orderId, long amount, String orderInfo) {
        String requestId = UUID.randomUUID().toString();
        String extraData = "";

        String rawSignature = MomoSignatureBuilder.createPaymentRawSignature(
                properties.accessKey(),
                amount,
                extraData,
                properties.ipnUrl(),
                orderId,
                orderInfo,
                properties.partnerCode(),
                properties.redirectUrl(),
                requestId,
                properties.requestType()
        );

        String signature = HmacSha256.sign(rawSignature, properties.secretKey());

        MomoCreatePaymentRequest request = new MomoCreatePaymentRequest(
                properties.partnerCode(),
                requestId,
                amount,
                orderId,
                orderInfo,
                properties.redirectUrl(),
                properties.ipnUrl(),
                properties.requestType(),
                extraData,
                properties.lang(),
                signature
        );

        return restClient.post()
                .uri(properties.endpoint())
                .contentType(MediaType.APPLICATION_JSON)
                .body(request.toMap())
                .retrieve()
                .body(MomoCreatePaymentResponse.class);
    }
}
```

## 10. Controller tạo payment

```java
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/payments/momo")
public class MomoPaymentController {

    private final MomoPaymentService momoPaymentService;

    public MomoPaymentController(MomoPaymentService momoPaymentService) {
        this.momoPaymentService = momoPaymentService;
    }

    @PostMapping("/create")
    public ResponseEntity<MomoCreatePaymentResponse> create(@RequestBody CreateMomoPaymentCommand command) {
        // Leader note:
        // 1. Không tin amount từ frontend.
        // 2. Lấy order từ DB, tự tính amount.
        // 3. Tạo payment transaction PENDING trước khi gọi MoMo.
        MomoCreatePaymentResponse response = momoPaymentService.createPayment(
                command.orderId(),
                command.amount(),
                command.orderInfo()
        );
        return ResponseEntity.ok(response);
    }
}
```

```java
public record CreateMomoPaymentCommand(
        String orderId,
        Long amount,
        String orderInfo
) {
}
```

Thực tế production không nên để client gửi `amount` rồi dùng luôn. Backend phải:

- Load order từ DB.
- Kiểm tra order đang `PENDING_PAYMENT`.
- Tự tính amount.
- Tạo payment transaction.
- Gọi MoMo.

## 11. Nhận IPN từ MoMo

DTO IPN:

```java
public record MomoIpnRequest(
        String partnerCode,
        String orderId,
        String requestId,
        Long amount,
        String orderInfo,
        String orderType,
        Long transId,
        Integer resultCode,
        String message,
        String payType,
        Long responseTime,
        String extraData,
        String signature
) {
}
```

Controller IPN:

```java
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/payments/momo")
public class MomoIpnController {

    private final MomoIpnService momoIpnService;

    public MomoIpnController(MomoIpnService momoIpnService) {
        this.momoIpnService = momoIpnService;
    }

    @PostMapping("/ipn")
    public ResponseEntity<Void> ipn(@RequestBody MomoIpnRequest request) {
        momoIpnService.handle(request);

        // Theo tài liệu MoMo, partner cần response HTTP 204 No Content.
        return ResponseEntity.noContent().build();
    }
}
```

## 12. Verify IPN signature

Theo tài liệu MoMo, raw signature IPN dùng format:

```text
accessKey=$accessKey&amount=$amount&extraData=$extraData
&message=$message&orderId=$orderId&orderInfo=$orderInfo
&orderType=$orderType&partnerCode=$partnerCode&payType=$payType
&requestId=$requestId&responseTime=$responseTime
&resultCode=$resultCode&transId=$transId
```

```java
public final class MomoIpnSignatureBuilder {

    private MomoIpnSignatureBuilder() {
    }

    public static String rawSignature(String accessKey, MomoIpnRequest request) {
        return "accessKey=" + accessKey
                + "&amount=" + request.amount()
                + "&extraData=" + nullToEmpty(request.extraData())
                + "&message=" + request.message()
                + "&orderId=" + request.orderId()
                + "&orderInfo=" + request.orderInfo()
                + "&orderType=" + request.orderType()
                + "&partnerCode=" + request.partnerCode()
                + "&payType=" + request.payType()
                + "&requestId=" + request.requestId()
                + "&responseTime=" + request.responseTime()
                + "&resultCode=" + request.resultCode()
                + "&transId=" + request.transId();
    }

    private static String nullToEmpty(String value) {
        return value == null ? "" : value;
    }
}
```

IPN service:

```java
import org.springframework.stereotype.Service;

@Service
public class MomoIpnService {

    private final MomoProperties properties;
    private final PaymentRepository paymentRepository;

    public MomoIpnService(MomoProperties properties, PaymentRepository paymentRepository) {
        this.properties = properties;
        this.paymentRepository = paymentRepository;
    }

    public void handle(MomoIpnRequest request) {
        String raw = MomoIpnSignatureBuilder.rawSignature(properties.accessKey(), request);
        String expectedSignature = HmacSha256.sign(raw, properties.secretKey());

        if (!expectedSignature.equals(request.signature())) {
            throw new IllegalArgumentException("Invalid MoMo IPN signature");
        }

        PaymentTransaction payment = paymentRepository.findByOrderId(request.orderId())
                .orElseThrow(() -> new IllegalArgumentException("Payment transaction not found"));

        if (!properties.partnerCode().equals(request.partnerCode())) {
            throw new IllegalArgumentException("Invalid partnerCode");
        }

        if (!payment.getAmount().equals(request.amount())) {
            throw new IllegalArgumentException("Invalid amount");
        }

        // Idempotency: nếu đã SUCCESS rồi thì không xử lý lại.
        if (payment.isFinalStatus()) {
            return;
        }

        if (request.resultCode() == 0) {
            payment.markSuccess(String.valueOf(request.transId()), request.payType());
        } else {
            payment.markFailed(request.resultCode(), request.message());
        }

        paymentRepository.save(payment);
    }
}
```

## 13. Trạng thái payment nên lưu trong DB

Gợi ý bảng:

```sql
CREATE TABLE payment_transactions (
    id BIGSERIAL PRIMARY KEY,
    order_id VARCHAR(100) NOT NULL,
    request_id VARCHAR(100) NOT NULL,
    gateway VARCHAR(30) NOT NULL,
    amount BIGINT NOT NULL,
    status VARCHAR(30) NOT NULL,
    gateway_trans_id VARCHAR(100),
    pay_type VARCHAR(50),
    result_code INT,
    message TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (order_id),
    UNIQUE (request_id)
);
```

Status gợi ý:

- `PENDING`
- `SUCCESS`
- `FAILED`
- `EXPIRED`
- `CANCELLED`

## 14. Redirect URL xử lý như thế nào?

`redirectUrl` là nơi user được chuyển về sau khi thanh toán.

Không nên:

- Cập nhật order `PAID` chỉ vì redirect báo success.
- Tin tuyệt đối query param trên redirect.

Nên:

- Hiển thị trạng thái tạm: "Đang xác nhận thanh toán".
- Gọi backend kiểm tra trạng thái payment trong DB.
- Nếu IPN đã về và success thì hiển thị thành công.
- Nếu IPN chưa về, frontend polling vài lần hoặc hiển thị hướng dẫn chờ.

Ví dụ endpoint:

```java
@GetMapping("/status/{orderId}")
public ResponseEntity<PaymentStatusResponse> status(@PathVariable String orderId) {
    // Load payment transaction từ DB và trả status cho frontend.
    return ResponseEntity.ok(paymentQueryService.getStatus(orderId));
}
```

## 15. Checklist production

- Có HTTPS cho `redirectUrl` và `ipnUrl`.
- Không commit `secretKey`.
- Không log full secret/raw sensitive data.
- Verify signature cho IPN.
- Đối chiếu `partnerCode`, `orderId`, `amount` với DB.
- Xử lý idempotency cho IPN vì MoMo/payment gateway có thể retry.
- Không tin amount từ frontend.
- Không đánh dấu order `PAID` chỉ bằng redirect.
- Có job reconciliation để rà soát payment `PENDING` quá lâu.
- Có timeout khi gọi MoMo, tài liệu MoMo khuyến nghị tối thiểu 30s cho API create.
- Có log theo `orderId`, `requestId`, `transId`.
- Có alert nếu IPN fail hoặc payment pending tăng bất thường.

## 16. Các lỗi thường gặp

### Sai signature

- Sai thứ tự field.
- Thiếu `extraData`.
- Dùng nhầm `secretKey`.
- Encode/trim string sai.
- Dùng raw signature của request create để verify IPN.

### Đơn hàng bị paid sai

- Chỉ dựa vào redirect.
- Không check amount.
- Không check order hiện tại có đang pending không.

### IPN bị gọi lặp

- Gateway retry khi không nhận được HTTP 204.
- Backend không idempotent.
- Payment success bị xử lý nhiều lần.

### Test local không nhận được IPN

- `ipnUrl` là localhost.
- MoMo server không gọi được máy local.
- Cần dùng public HTTPS URL như ngrok/cloudflared trong môi trường test.

## 17. Thiết kế code nên mở rộng được

Đừng viết toàn bộ logic MoMo dính chặt vào Order Service.

Nên có interface:

```java
public interface PaymentGateway {
    CreatePaymentResult createPayment(CreatePaymentRequest request);
    void handleNotification(Object notification);
}
```

Sau đó implement:

```java
public class MomoPaymentGateway implements PaymentGateway {
}
```

Lợi ích:

- Sau này thêm VNPAY/ZaloPay/Stripe dễ hơn.
- Business order không phụ thuộc quá sâu vào MoMo.
- Dễ viết test.
- Dễ mock payment gateway.

## 18. Flow khuyến nghị cho website của bạn

```text
1. User bấm thanh toán.
2. Frontend gọi backend create MoMo payment.
3. Backend kiểm tra order, tự tính amount.
4. Backend tạo payment transaction PENDING.
5. Backend gọi MoMo create payment.
6. Backend trả payUrl cho frontend.
7. Frontend redirect sang payUrl.
8. User thanh toán.
9. MoMo gọi ipnUrl.
10. Backend verify signature + check amount/orderId.
11. Backend cập nhật payment SUCCESS/FAILED.
12. Frontend kiểm tra status và hiển thị kết quả.
```

## 19. Câu trả lời mẫu khi phỏng vấn

- "Với website thanh toán MoMo cơ bản, em chọn flow `captureWallet`: backend tạo request với `orderId`, `amount`, `redirectUrl`, `ipnUrl`, ký HMAC SHA256 rồi gọi MoMo để lấy `payUrl`."
- "Em không cập nhật order paid dựa vào redirect vì redirect chạy qua browser và không đáng tin bằng IPN server-to-server."
- "Khi nhận IPN, em verify signature, check `partnerCode`, `orderId`, `amount` với database, sau đó mới cập nhật payment."
- "Em thiết kế IPN idempotent vì payment gateway có thể retry notification."
- "Em sẽ tách `PaymentGateway` interface để sau này thêm VNPAY/ZaloPay/Stripe không ảnh hưởng nghiệp vụ order."
