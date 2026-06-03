# Tích hợp thanh toán ZaloPay cho Spring Boot

Tài liệu này hướng dẫn tích hợp ZaloPay Payment Gateway cho website Spring Boot theo hướng production-ready: tạo order, redirect user, nhận callback, verify chữ ký và cập nhật trạng thái thanh toán trong DB.

Nguồn tham khảo chính:

- ZaloPay - Create a new order: https://docs.zalopay.vn/docs/specs/order-create/
- ZaloPay - Payment Gateway: https://docs.zalopay.vn/docs/guides/payment-acceptance/payment-gateway/intro/
- ZaloPay - Callback: https://docs.zalopay.vn/docs/developer-tools/knowledge-base/callback
- ZaloPay - Query status of an order: https://docs.zalopay.vn/docs/specs/order-query/

## 1. Nên chọn phương án nào?

### Khuyến nghị cho website bán hàng phổ thông

- Chọn flow `Payment Gateway - Create Order`.
- Backend Spring Boot gọi API ZaloPay:
  - Sandbox: `POST https://sb-openapi.zalopay.vn/v2/create`
  - Production: endpoint do ZaloPay cấp khi onboarding.
- ZaloPay trả về `order_url`.
- Frontend redirect user sang `order_url`.
- User thanh toán trên ZaloPay Gateway.
- ZaloPay redirect user về URL trong `embed_data.redirecturl` hoặc config merchant portal.
- ZaloPay gọi `callback_url` server-to-server.
- Backend verify callback `mac` bằng `key2`, đối chiếu DB và cập nhật `SUCCESS/FAILED`.

### Kết luận leader

- ZaloPay giống MoMo ở điểm backend phải gọi API create để nhận URL thanh toán.
- ZaloPay khác MoMo ở phần ký:
  - Create order dùng `key1`.
  - Callback verify dùng `key2`.
- Không cập nhật order `PAID` chỉ dựa vào redirect user.
- Trạng thái chuẩn phải dựa vào callback server-to-server sau khi verify `mac`.
- Nếu callback bị miss, dùng `/v2/query` để đối soát order còn `PENDING`.

## 2. Luồng xử lý chuẩn

```text
User
  -> Website frontend
  -> Spring Boot backend: POST /api/payments/zalopay/create
  -> Backend tạo order/payment PENDING trong DB
  -> Backend tạo app_trans_id theo format yyMMdd_orderId
  -> Backend build embed_data/item
  -> Backend ký mac bằng key1
  -> Backend gọi ZaloPay /v2/create
  -> ZaloPay trả order_url
  -> Frontend redirect user sang order_url
  -> User thanh toán trên ZaloPay Gateway
  -> ZaloPay redirect user về redirecturl
  -> ZaloPay gọi callback_url server-to-server
  -> Backend verify callback mac bằng key2
  -> Backend check app_id/app_trans_id/amount với DB
  -> Backend cập nhật payment SUCCESS/FAILED
```

## 3. Field quan trọng của ZaloPay

### Thông tin cấu hình

- `app_id`: mã ứng dụng/merchant do ZaloPay cấp.
- `key1`: key dùng ký request create order và query.
- `key2`: key dùng verify callback từ ZaloPay.
- `create_endpoint`: endpoint tạo order.
- `query_endpoint`: endpoint truy vấn trạng thái order.
- `callback_url`: URL backend nhận callback server-to-server.
- `redirect_url`: URL user quay lại website sau thanh toán.

### Tham số tạo order

- `app_id`: app id do ZaloPay cấp.
- `app_user`: định danh user phía merchant, không được để rỗng.
- `app_time`: thời gian tạo order, unix timestamp milliseconds.
- `amount`: số tiền VND.
- `app_trans_id`: mã giao dịch phía merchant, format nên là `yyMMdd_orderId`.
- `embed_data`: JSON string, dùng `{}` nếu rỗng. Có thể chứa `redirecturl`.
- `item`: JSON array string, dùng `[]` nếu rỗng.
- `description`: mô tả đơn hàng.
- `bank_code`: tùy chọn, để rỗng cho user chọn phương thức.
- `callback_url`: URL ZaloPay gọi khi thanh toán hoàn tất.
- `mac`: chữ ký HMAC SHA256 bằng `key1`.

### Response tạo order

- `return_code`: `1` là success, `2` là failure, `3` là processing.
- `return_message`: mô tả kết quả.
- `sub_return_code`: mã chi tiết.
- `sub_return_message`: mô tả chi tiết.
- `order_url`: URL redirect user sang ZaloPay Gateway.
- `zp_trans_token`: token giao dịch.
- `order_token`: token order.

## 4. Cấu hình Spring Boot

### 4.1 `application.yml`

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

Production cần đổi:

- `create-endpoint`, `query-endpoint` sang production endpoint.
- `app-id`, `key1`, `key2` sang credential production.
- `callback-url`, `redirect-url` sang HTTPS domain thật.

Không commit `key1`, `key2` thật lên Git.

## 5. Mapping config

```java
import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "payment.zalopay")
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

## 6. DTO tạo payment

```java
public record ZaloPayCreatePaymentResponse(
        String appTransId,
        Long amount,
        String orderUrl,
        String zpTransToken,
        String orderToken,
        String status
) {
}
```

## 7. Tạo chữ ký HMAC SHA256

### 7.1 Create order

Raw data ký create order:

```text
app_id|app_trans_id|app_user|amount|app_time|embed_data|item
```

Ký bằng:

```text
HmacSHA256(rawData, key1)
```

Code Java:

```java
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;

public final class ZaloPaySigner {

    private ZaloPaySigner() {
    }

    public static String signHmacSha256(String data, String key) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            SecretKeySpec keySpec = new SecretKeySpec(
                    key.getBytes(StandardCharsets.UTF_8),
                    "HmacSHA256"
            );
            mac.init(keySpec);
            return toHex(mac.doFinal(data.getBytes(StandardCharsets.UTF_8)));
        } catch (Exception ex) {
            throw new IllegalStateException("Cannot create ZaloPay mac", ex);
        }
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

### 7.2 Callback

ZaloPay gửi callback body:

```json
{
  "data": "{...}",
  "mac": "...",
  "type": 1
}
```

Verify callback:

```text
expectedMac = HmacSHA256(data, key2)
```

Chỉ xử lý callback nếu `expectedMac` khớp `mac`.

### 7.3 Query order

Raw data query:

```text
app_id|app_trans_id|key1
```

Ký bằng:

```text
HmacSHA256(rawData, key1)
```

## 8. Service tạo order

```java
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.web.client.RestClient;

import java.time.LocalDate;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;

public class ZaloPayPaymentService {

    private static final ZoneId VN_ZONE = ZoneId.of("Asia/Ho_Chi_Minh");
    private static final DateTimeFormatter PREFIX = DateTimeFormatter.ofPattern("yyMMdd");

    private final ZaloPayProperties properties;
    private final PaymentRepository paymentRepository;
    private final RestClient restClient;
    private final ObjectMapper objectMapper;

    public ZaloPayPaymentService(ZaloPayProperties properties,
                                 PaymentRepository paymentRepository,
                                 RestClient restClient,
                                 ObjectMapper objectMapper) {
        this.properties = properties;
        this.paymentRepository = paymentRepository;
        this.restClient = restClient;
        this.objectMapper = objectMapper;
    }

    public ZaloPayCreatePaymentResponse createPayment(CreatePaymentCommand command) throws Exception {
        long appTime = System.currentTimeMillis();
        String appTransId = LocalDate.now(VN_ZONE).format(PREFIX) + "_" + command.orderId();
        String appUser = command.userId() == null ? properties.defaultAppUser() : command.userId();

        String embedData = objectMapper.writeValueAsString(Map.of(
                "redirecturl", properties.redirectUrl()
        ));
        String item = objectMapper.writeValueAsString(List.of(
                Map.of(
                        "itemid", command.orderId(),
                        "itemname", "Order " + command.orderId(),
                        "itemprice", command.amount(),
                        "itemquantity", 1
                )
        ));

        paymentRepository.createPending(command.orderId(), appTransId, command.amount(), "ZALOPAY");

        String rawMac = properties.appId() + "|" + appTransId + "|" + appUser + "|" +
                command.amount() + "|" + appTime + "|" + embedData + "|" + item;
        String mac = ZaloPaySigner.signHmacSha256(rawMac, properties.key1());

        Map<String, Object> request = Map.of(
                "app_id", properties.appId(),
                "app_user", appUser,
                "app_time", appTime,
                "amount", command.amount(),
                "app_trans_id", appTransId,
                "embed_data", embedData,
                "item", item,
                "description", "Thanh toan don hang " + command.orderId(),
                "callback_url", properties.callbackUrl(),
                "mac", mac
        );

        ZaloPayCreateOrderResponse response = restClient.post()
                .uri(properties.createEndpoint())
                .body(request)
                .retrieve()
                .body(ZaloPayCreateOrderResponse.class);

        if (response == null || response.returnCode() != 1) {
            paymentRepository.markCreateFailed(appTransId, response);
            throw new IllegalStateException("ZaloPay create order failed");
        }

        return new ZaloPayCreatePaymentResponse(
                appTransId,
                command.amount(),
                response.orderUrl(),
                response.zpTransToken(),
                response.orderToken(),
                "PENDING"
        );
    }
}
```

Response DTO:

```java
import com.fasterxml.jackson.annotation.JsonProperty;

public record ZaloPayCreateOrderResponse(
        @JsonProperty("return_code") Integer returnCode,
        @JsonProperty("return_message") String returnMessage,
        @JsonProperty("sub_return_code") Integer subReturnCode,
        @JsonProperty("sub_return_message") String subReturnMessage,
        @JsonProperty("order_url") String orderUrl,
        @JsonProperty("zp_trans_token") String zpTransToken,
        @JsonProperty("order_token") String orderToken
) {
}
```

## 9. Controller tạo payment

```java
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/payments/zalopay")
public class ZaloPayPaymentController {

    private final ZaloPayPaymentService paymentService;

    public ZaloPayPaymentController(ZaloPayPaymentService paymentService) {
        this.paymentService = paymentService;
    }

    @PostMapping("/create")
    public ZaloPayCreatePaymentResponse create(@RequestBody CreatePaymentCommand command) throws Exception {
        return paymentService.createPayment(command);
    }
}
```

## 10. Xử lý redirect URL

Redirect URL dùng để user quay lại website sau khi thanh toán.

Không nên:

- Mark order `PAID` chỉ vì user quay về redirect URL.
- Tin query params redirect nếu chưa đối chiếu DB.

Nên:

- Hiển thị trạng thái tạm thời.
- Poll backend để lấy trạng thái mới nhất từ DB.
- Nếu DB vẫn `PENDING`, hiển thị `Đang xác nhận thanh toán`.

## 11. Xử lý callback

Callback là nguồn cập nhật trạng thái chính.

Checklist khi nhận callback:

- Parse body gồm `data`, `mac`, `type`.
- Verify `mac = HmacSHA256(data, key2)`.
- Parse JSON trong `data`.
- Tìm payment theo `app_trans_id`.
- Check `app_id` đúng app.
- Check `amount` đúng DB.
- Nếu `status=1`, cập nhật `SUCCESS`.
- Lưu `zp_trans_id`.
- Xử lý idempotent vì callback có thể gọi lại.
- Trả response theo contract ZaloPay.

Response callback thành công:

```json
{
  "return_code": 1,
  "return_message": "success"
}
```

Nếu lỗi tạm thời và muốn ZaloPay callback lại:

```json
{
  "return_code": 0,
  "return_message": "temporary error"
}
```

Nếu lỗi không callback lại:

```json
{
  "return_code": -1,
  "return_message": "invalid mac"
}
```

## 12. Query order khi cần đối soát

Dùng `/v2/query` khi:

- User quay về website nhưng callback chưa tới.
- Payment `PENDING` quá lâu.
- Callback fail do backend timeout.
- Job đối soát cuối ngày.

Endpoint sandbox:

```text
POST https://sb-openapi.zalopay.vn/v2/query
Content-Type: application/json
```

Raw mac:

```text
app_id|app_trans_id|key1
```

Không dùng query thay callback trong luồng bình thường. Query là cơ chế xác nhận lại.

## 13. Database gợi ý

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

- `PENDING`: đã tạo order_url, chờ user thanh toán.
- `SUCCESS`: callback/query xác nhận thành công.
- `FAILED`: callback/query xác nhận thất bại.
- `EXPIRED`: quá thời gian thanh toán.
- `REVIEW`: lệch dữ liệu, cần kiểm tra thủ công.

## 14. Checklist production

- Dùng HTTPS cho `callback-url` và `redirect-url`.
- Không để callback URL là `localhost`.
- Không log `key1`, `key2`.
- Log `app_trans_id`, `amount`, `return_code`, `zp_trans_id`.
- Verify callback bằng `key2`.
- Check amount với DB trước khi mark `SUCCESS`.
- Idempotency: callback có thể gửi lại.
- Có scheduled job query order cho payment `PENDING` lâu.
- `app_trans_id` phải đúng format `yyMMdd_orderId` và unique.
- Có alert nếu tỉ lệ invalid mac tăng.

## 15. So sánh nhanh MoMo, VNPAY, ZaloPay

| Tiêu chí | MoMo | VNPAY | ZaloPay |
|---|---|---|---|
| Cách tạo payment | Gọi API create | Build URL + secure hash | Gọi API `/v2/create` |
| URL thanh toán | MoMo trả `payUrl` | Backend tự tạo `paymentUrl` | ZaloPay trả `order_url` |
| Callback user | `redirectUrl` | `vnp_ReturnUrl` | `redirecturl` |
| Callback server | `ipnUrl` | `IPN URL` | `callback_url` |
| Signature create | HMAC SHA256 | HMAC SHA512 | HMAC SHA256 bằng `key1` |
| Signature callback | HMAC SHA256 | HMAC SHA512 | HMAC SHA256 bằng `key2` |
| Amount | VND trực tiếp | `amount * 100` | VND trực tiếp |
| Nguồn cập nhật trạng thái chuẩn | IPN | IPN | Callback |

