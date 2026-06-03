# Tích hợp thanh toán VNPAY cho Spring Boot

Tài liệu này hướng dẫn tích hợp VNPAY Payment Gateway cho website Spring Boot theo hướng an toàn, dễ bảo trì và có thể mở rộng thêm nhiều cổng thanh toán khác.

Nguồn tham khảo chính:

- VNPAY - Thanh toán PAY: https://sandbox.vnpayment.vn/apis/docs/thanh-toan-pay/pay.html
- VNPAY - Mô hình kết nối: https://sandbox.vnpayment.vn/apis/docs/mo-hinh-ket-noi/
- VNPAY - Query/Refund API: https://sandbox.vnpayment.vn/apis/docs/truy-van-hoan-tien/querydr%26refund.html
- VNPAY - Chuyển đổi thuật toán hash: https://sandbox.vnpayment.vn/apis/docs/chuyen-doi-thuat-toan/changeTypeHash.html

## 1. Nên chọn phương án nào?

### Khuyến nghị cho website bán hàng phổ thông

- Chọn flow `Thanh toán PAY`.
- Backend Spring Boot tạo `paymentUrl` bằng cách build query string tới:
  - Sandbox: `https://sandbox.vnpayment.vn/paymentv2/vpcpay.html`
  - Production: URL do VNPAY cung cấp khi ký hợp đồng.
- Frontend redirect user sang `paymentUrl`.
- VNPAY xử lý thanh toán trên trang của VNPAY.
- VNPAY redirect user về `vnp_ReturnUrl`.
- VNPAY gọi `IPN URL` để merchant cập nhật trạng thái thanh toán.

### Kết luận leader

- VNPAY phù hợp khi website cần hỗ trợ thanh toán qua ngân hàng nội địa, thẻ ATM, QR, thẻ quốc tế tùy cấu hình merchant.
- Flow tạo payment của VNPAY khác MoMo:
  - MoMo: backend gọi API create và nhận `payUrl`.
  - VNPAY: backend tự build URL thanh toán có `vnp_SecureHash`, sau đó frontend redirect.
- Không cập nhật order `PAID` chỉ dựa vào `vnp_ReturnUrl`.
- Trạng thái chuẩn phải dựa vào `IPN URL` sau khi verify `vnp_SecureHash` và đối chiếu `vnp_TxnRef`, `vnp_Amount`, `vnp_ResponseCode`, `vnp_TransactionStatus` với DB.
- Nếu không nhận được IPN hoặc trạng thái chưa chắc chắn, dùng QueryDR API để đối soát.

## 2. Luồng xử lý chuẩn

```text
User
  -> Website frontend
  -> Spring Boot backend: POST /api/payments/vnpay/create
  -> Backend tạo order/payment PENDING trong DB
  -> Backend build VNPAY payment URL
  -> Backend sort params theo tên tăng dần
  -> Backend ký HMAC SHA512 bằng vnp_HashSecret
  -> Backend trả paymentUrl cho frontend
  -> Frontend redirect user sang paymentUrl
  -> User thanh toán trên VNPAY
  -> VNPAY redirect user về vnp_ReturnUrl
  -> VNPAY gọi IPN URL server-to-server
  -> Backend verify vnp_SecureHash
  -> Backend check vnp_TmnCode/vnp_TxnRef/vnp_Amount với DB
  -> Backend cập nhật payment SUCCESS/FAILED
```

## 3. Field quan trọng của VNPAY

### Thông tin cấu hình

- `vnp_TmnCode`: mã website/merchant do VNPAY cấp.
- `vnp_HashSecret`: secret dùng tạo và verify checksum.
- `vnp_PayUrl`: URL thanh toán VNPAY.
- `vnp_ReturnUrl`: URL redirect user quay về website sau thanh toán.
- `vnp_IpnUrl`: URL backend nhận kết quả thanh toán server-to-server. VNPAY yêu cầu merchant gửi URL này khi cấu hình.

### Tham số tạo payment URL

- `vnp_Version`: phiên bản API, thường là `2.1.0`.
- `vnp_Command`: với thanh toán là `pay`.
- `vnp_TmnCode`: mã merchant.
- `vnp_Amount`: số tiền nhân `100`. Ví dụ `10,000 VND` gửi là `1000000`.
- `vnp_BankCode`: tùy chọn. Bỏ trống để user chọn phương thức tại VNPAY.
- `vnp_CreateDate`: thời gian tạo giao dịch `yyyyMMddHHmmss`, GMT+7.
- `vnp_CurrCode`: chỉ hỗ trợ `VND`.
- `vnp_IpAddr`: IP của user.
- `vnp_Locale`: `vn` hoặc `en`.
- `vnp_OrderInfo`: mô tả giao dịch, nên dùng không dấu và tránh ký tự đặc biệt.
- `vnp_OrderType`: loại hàng hóa, ví dụ `other`.
- `vnp_ReturnUrl`: URL nhận redirect.
- `vnp_ExpireDate`: thời gian hết hạn thanh toán `yyyyMMddHHmmss`, GMT+7.
- `vnp_TxnRef`: mã giao dịch phía merchant, phải unique.
- `vnp_SecureHash`: checksum HMAC SHA512.

## 4. Cấu hình Spring Boot

### 4.1 `application.yml`

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

Production cần đổi:

- `pay-url`, `query-url` sang endpoint production VNPAY cấp.
- `tmn-code`, `hash-secret` sang thông tin production.
- `return-url`, `ipn-url` sang HTTPS domain thật.

Không commit `hash-secret` thật lên Git.

## 5. Dependency gợi ý

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

## 6. Mapping config

```java
import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "payment.vnpay")
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

## 7. DTO backend trả về cho frontend

```java
public record VnpayCreatePaymentResponse(
        String txnRef,
        Long amount,
        String paymentUrl,
        String status
) {
}
```

Frontend chỉ cần redirect:

```js
window.location.href = response.paymentUrl;
```

## 8. Tạo chữ ký HMAC SHA512

Quy tắc quan trọng:

- Loại bỏ `vnp_SecureHash` và `vnp_SecureHashType` khỏi dữ liệu ký.
- Sort params theo tên tăng dần.
- Build hash data dạng query string.
- Ký bằng `HmacSHA512(hashData, vnp_HashSecret)`.
- Append `vnp_SecureHash` vào URL cuối cùng.

Code Java gợi ý:

```java
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.Map;
import java.util.TreeMap;
import java.util.stream.Collectors;

public final class VnpaySigner {

    private VnpaySigner() {
    }

    public static String buildHashData(Map<String, String> params) {
        return new TreeMap<>(params).entrySet().stream()
                .filter(entry -> entry.getValue() != null && !entry.getValue().isBlank())
                .filter(entry -> !entry.getKey().equals("vnp_SecureHash"))
                .filter(entry -> !entry.getKey().equals("vnp_SecureHashType"))
                .map(entry -> encode(entry.getKey()) + "=" + encode(entry.getValue()))
                .collect(Collectors.joining("&"));
    }

    public static String signHmacSha512(String hashData, String secretKey) {
        try {
            Mac mac = Mac.getInstance("HmacSHA512");
            SecretKeySpec keySpec = new SecretKeySpec(
                    secretKey.getBytes(StandardCharsets.UTF_8),
                    "HmacSHA512"
            );
            mac.init(keySpec);
            return toHex(mac.doFinal(hashData.getBytes(StandardCharsets.UTF_8)));
        } catch (Exception ex) {
            throw new IllegalStateException("Cannot create VNPAY secure hash", ex);
        }
    }

    private static String encode(String value) {
        return URLEncoder.encode(value, StandardCharsets.UTF_8);
    }

    private static String toHex(byte[] bytes) {
        StringBuilder result = new StringBuilder(bytes.length * 2);
        for (byte item : bytes) {
            result.append(String.format("%02x", item));
        }
        return result.toString();
    }
}
```

## 9. Service tạo payment URL

```java
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.LinkedHashMap;
import java.util.Map;

public class VnpayPaymentService {

    private static final ZoneId VN_ZONE = ZoneId.of("Asia/Ho_Chi_Minh");
    private static final DateTimeFormatter VNPAY_TIME = DateTimeFormatter.ofPattern("yyyyMMddHHmmss");

    private final VnpayProperties properties;
    private final PaymentRepository paymentRepository;

    public VnpayPaymentService(VnpayProperties properties, PaymentRepository paymentRepository) {
        this.properties = properties;
        this.paymentRepository = paymentRepository;
    }

    public VnpayCreatePaymentResponse createPayment(CreatePaymentCommand command, String clientIp) {
        String txnRef = command.orderId();

        paymentRepository.createPending(txnRef, command.amount(), "VNPAY");

        LocalDateTime now = LocalDateTime.now(VN_ZONE);
        LocalDateTime expire = now.plusMinutes(properties.expireMinutes());

        Map<String, String> params = new LinkedHashMap<>();
        params.put("vnp_Version", properties.version());
        params.put("vnp_Command", properties.command());
        params.put("vnp_TmnCode", properties.tmnCode());
        params.put("vnp_Amount", String.valueOf(command.amount() * 100));
        params.put("vnp_CurrCode", properties.currCode());
        params.put("vnp_IpAddr", clientIp);
        params.put("vnp_Locale", properties.locale());
        params.put("vnp_OrderInfo", "Thanh toan don hang " + txnRef);
        params.put("vnp_OrderType", properties.orderType());
        params.put("vnp_ReturnUrl", properties.returnUrl());
        params.put("vnp_TxnRef", txnRef);
        params.put("vnp_CreateDate", VNPAY_TIME.format(now));
        params.put("vnp_ExpireDate", VNPAY_TIME.format(expire));

        String hashData = VnpaySigner.buildHashData(params);
        String secureHash = VnpaySigner.signHmacSha512(hashData, properties.hashSecret());
        String paymentUrl = properties.payUrl() + "?" + hashData + "&vnp_SecureHash=" + secureHash;

        return new VnpayCreatePaymentResponse(txnRef, command.amount(), paymentUrl, "PENDING");
    }
}
```

## 10. Controller tạo payment

```java
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/payments/vnpay")
public class VnpayPaymentController {

    private final VnpayPaymentService paymentService;

    public VnpayPaymentController(VnpayPaymentService paymentService) {
        this.paymentService = paymentService;
    }

    @PostMapping("/create")
    public VnpayCreatePaymentResponse create(@RequestBody CreatePaymentCommand command,
                                             HttpServletRequest request) {
        return paymentService.createPayment(command, getClientIp(request));
    }

    private String getClientIp(HttpServletRequest request) {
        String forwardedFor = request.getHeader("X-Forwarded-For");
        if (forwardedFor != null && !forwardedFor.isBlank()) {
            return forwardedFor.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }
}
```

## 11. Xử lý ReturnUrl

`vnp_ReturnUrl` dùng để hiển thị kết quả cho user sau khi VNPAY redirect về website.

Không nên:

- Mark order `PAID` chỉ vì ReturnUrl có `vnp_ResponseCode=00`.
- Tin vào query params nếu chưa verify `vnp_SecureHash`.

Nên:

- Verify chữ ký.
- Hiển thị trạng thái tạm thời cho user.
- Nếu DB đã có trạng thái từ IPN, hiển thị theo DB.
- Nếu DB chưa có trạng thái, hiển thị `Đang xác nhận thanh toán` và cho backend query lại VNPAY nếu cần.

## 12. Xử lý IPN URL

IPN là nơi backend cập nhật trạng thái thanh toán chuẩn.

Checklist khi nhận IPN:

- Lấy toàn bộ query params VNPAY gửi.
- Verify `vnp_SecureHash`.
- Tìm payment theo `vnp_TxnRef`.
- Check `vnp_TmnCode` đúng merchant.
- Check `vnp_Amount` đúng bằng `amount * 100` trong DB.
- Check trạng thái hiện tại có đang `PENDING` không.
- Nếu `vnp_ResponseCode=00` và `vnp_TransactionStatus=00`, cập nhật `SUCCESS`.
- Nếu khác `00`, cập nhật `FAILED` hoặc giữ `PENDING` tùy nghiệp vụ.
- Trả JSON cho VNPAY theo contract IPN.

Response IPN thường dùng:

```json
{
  "RspCode": "00",
  "Message": "Confirm Success"
}
```

Các lỗi thường gặp:

- `97`: invalid checksum.
- `01`: không tìm thấy order.
- `04`: số tiền không hợp lệ.
- `02`: order đã được confirm trước đó.

## 13. QueryDR khi cần đối soát

Dùng QueryDR API khi:

- User quay về ReturnUrl nhưng IPN chưa tới.
- Backend timeout khi xử lý IPN.
- Cần job đối soát cuối ngày.
- Payment còn `PENDING` quá lâu.

Endpoint sandbox:

```text
POST https://sandbox.vnpayment.vn/merchant_webapi/api/transaction
Content-Type: application/json
```

Không gọi QueryDR thay cho IPN trong luồng bình thường. QueryDR nên là cơ chế kiểm tra lại.

## 14. Database gợi ý

```sql
create table payment_transaction (
    id bigint primary key,
    gateway varchar(30) not null,
    order_id varchar(100) not null,
    gateway_txn_ref varchar(100) not null,
    gateway_transaction_no varchar(100),
    amount bigint not null,
    status varchar(30) not null,
    request_payload text,
    response_payload text,
    created_at timestamp not null,
    updated_at timestamp not null,
    unique (gateway, gateway_txn_ref)
);
```

Status gợi ý:

- `PENDING`: đã tạo URL, chờ user thanh toán.
- `SUCCESS`: VNPAY báo thành công và backend đã verify.
- `FAILED`: VNPAY báo thất bại.
- `EXPIRED`: quá hạn thanh toán.
- `REVIEW`: lệch dữ liệu, cần kiểm tra thủ công.

## 15. Checklist production

- Dùng HTTPS cho `return-url` và `ipn-url`.
- Không để `localhost` cho URL mà VNPAY cần gọi.
- Không log `vnp_HashSecret`.
- Log `txnRef`, `amount`, `responseCode`, `transactionStatus`, `transactionNo`.
- Verify chữ ký cho cả ReturnUrl và IPN.
- Check amount với DB trước khi mark `SUCCESS`.
- Idempotency: IPN có thể gọi lại, xử lý update nhiều lần phải an toàn.
- Có job đối soát QueryDR cho payment `PENDING` lâu.
- Có alert nếu tỉ lệ invalid checksum tăng.
- Có bảng mapping mã lỗi VNPAY để CSKH tra cứu.

## 16. So sánh nhanh MoMo và VNPAY

| Tiêu chí | MoMo | VNPAY |
|---|---|---|
| Cách tạo payment | Gọi API create | Build URL + secure hash |
| URL thanh toán | MoMo trả `payUrl` | Backend tự tạo `paymentUrl` |
| Callback user | `redirectUrl` | `vnp_ReturnUrl` |
| Callback server | `ipnUrl` | `IPN URL` |
| Signature | HMAC SHA256 tùy raw format | HMAC SHA512 trên sorted query params |
| Amount | Gửi VND trực tiếp | Gửi `amount * 100` |
| Nguồn cập nhật trạng thái chuẩn | IPN | IPN |

