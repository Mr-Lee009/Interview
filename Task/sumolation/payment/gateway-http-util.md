# PaymentGatewayHttpUtil

## 1. Mục đích

`PaymentGatewayHttpUtil` là class util dùng chung để gọi HTTP sang các cổng thanh toán như:

- `MOMO`
- `VNPAY`
- `ZALOPAY`

Mục tiêu:

1. Tránh lặp lại code gọi HTTP trong từng adapter
2. Chuẩn hóa timeout, header, logging và xử lý lỗi kỹ thuật
3. Giúp các gateway adapter chỉ tập trung vào business riêng của từng cổng

## 2. Khi nào nên dùng

Nên dùng class này khi gateway adapter cần:

1. Gọi API `create payment`
2. Gọi API `query payment`
3. Gửi `GET` hoặc `POST`
4. Gửi `JSON body` hoặc `form params`
5. Nhận raw response để adapter tự parse

## 3. Không nên để class này làm gì

Class util này không nên xử lý:

1. Ký request
2. Verify callback
3. Mapping status thanh toán
4. Quyết định business thành công hay thất bại
5. Đọc dữ liệu DB

Lý do:

- Đây là trách nhiệm của từng `gateway adapter`
- Nếu nhồi business vào util thì util sẽ trở thành god class

## 4. Trách nhiệm chính

`PaymentGatewayHttpUtil` chỉ nên làm:

1. Tạo HTTP request
2. Set header
3. Set connect timeout / read timeout
4. Gửi request
5. Trả về raw response
6. Chuẩn hóa lỗi kỹ thuật như timeout, connection error, HTTP error
7. Ghi log request/response ở mức phù hợp

## 5. Thiết kế class gợi ý

```java
public class PaymentGatewayHttpUtil {

    public RawGatewayHttpResponse postJson(
            String url,
            Map<String, String> headers,
            String jsonBody,
            int timeoutSeconds
    ) {
        return null;
    }

    public RawGatewayHttpResponse postForm(
            String url,
            Map<String, String> headers,
            Map<String, String> formData,
            int timeoutSeconds
    ) {
        return null;
    }

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

## 6. DTO trả về từ util

Nên có một DTO chung cho raw response:

```java
public record RawGatewayHttpResponse(
        int httpStatus,
        String responseBody,
        Map<String, List<String>> responseHeaders,
        boolean success
) {
}
```

Ý nghĩa:

| Field | Dùng để làm gì |
|---|---|
| `httpStatus` | Biết status code trả về |
| `responseBody` | Adapter tự parse JSON/XML/text |
| `responseHeaders` | Dùng khi cần đọc header từ provider |
| `success` | Đánh dấu request kỹ thuật có thành công hay không |

## 7. Exception gợi ý

Nên có một exception kỹ thuật riêng:

```java
public class PaymentGatewayHttpException extends RuntimeException {
    public PaymentGatewayHttpException(String message, Throwable cause) {
        super(message, cause);
    }
}
```

Dùng cho các lỗi như:

1. Timeout
2. Không kết nối được gateway
3. DNS lỗi
4. SSL lỗi
5. HTTP client lỗi

## 8. Ví dụ code Java

Ví dụ dùng `java.net.http.HttpClient`:

```java
import java.io.IOException;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

public class PaymentGatewayHttpUtil {

    private final HttpClient httpClient;

    public PaymentGatewayHttpUtil() {
        this.httpClient = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(10))
                .build();
    }

    public RawGatewayHttpResponse postJson(
            String url,
            Map<String, String> headers,
            String jsonBody,
            int timeoutSeconds
    ) {
        try {
            HttpRequest.Builder builder = HttpRequest.newBuilder()
                    .uri(URI.create(url))
                    .timeout(Duration.ofSeconds(timeoutSeconds))
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(jsonBody));

            // Gắn thêm header riêng của từng gateway nếu có
            if (headers != null) {
                headers.forEach(builder::header);
            }

            HttpResponse<String> response = httpClient.send(
                    builder.build(),
                    HttpResponse.BodyHandlers.ofString()
            );

            return new RawGatewayHttpResponse(
                    response.statusCode(),
                    response.body(),
                    response.headers().map(),
                    response.statusCode() >= 200 && response.statusCode() < 300
            );
        } catch (IOException | InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new PaymentGatewayHttpException("Call gateway by POST JSON failed", e);
        }
    }

    public RawGatewayHttpResponse get(
            String url,
            Map<String, String> headers,
            Map<String, String> queryParams,
            int timeoutSeconds
    ) {
        try {
            String fullUrl = buildUrl(url, queryParams);

            HttpRequest.Builder builder = HttpRequest.newBuilder()
                    .uri(URI.create(fullUrl))
                    .timeout(Duration.ofSeconds(timeoutSeconds))
                    .GET();

            if (headers != null) {
                headers.forEach(builder::header);
            }

            HttpResponse<String> response = httpClient.send(
                    builder.build(),
                    HttpResponse.BodyHandlers.ofString()
            );

            return new RawGatewayHttpResponse(
                    response.statusCode(),
                    response.body(),
                    response.headers().map(),
                    response.statusCode() >= 200 && response.statusCode() < 300
            );
        } catch (IOException | InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new PaymentGatewayHttpException("Call gateway by GET failed", e);
        }
    }

    private String buildUrl(String url, Map<String, String> queryParams) {
        if (queryParams == null || queryParams.isEmpty()) {
            return url;
        }

        String query = queryParams.entrySet().stream()
                .map(entry -> encode(entry.getKey()) + "=" + encode(entry.getValue()))
                .collect(Collectors.joining("&"));

        return url + "?" + query;
    }

    private String encode(String value) {
        return URLEncoder.encode(value, StandardCharsets.UTF_8);
    }
}
```

## 9. Cách dùng trong gateway adapter

Ví dụ trong `ZaloPayPaymentGateway`:

```java
public class ZaloPayPaymentGateway implements PaymentGateway {

    private final PaymentGatewayHttpUtil httpUtil;

    public ZaloPayPaymentGateway(PaymentGatewayHttpUtil httpUtil) {
        this.httpUtil = httpUtil;
    }

    @Override
    public GatewayCreatePaymentResult createPayment(
            CreatePaymentRequest request,
            PaymentGatewayConfigEntity config
    ) {
        String rawJson = "{...signed body...}";

        RawGatewayHttpResponse response = httpUtil.postJson(
                config.getEndpointBaseUrl() + config.getCreateApiPath(),
                Map.of(),
                rawJson,
                config.getTimeoutSeconds()
        );

        // Adapter tự parse responseBody và map sang DTO chung
        return new GatewayCreatePaymentResult(
                "gateway-ref",
                "https://redirect-url",
                response.responseBody()
        );
    }
}
```

## 10. Nên đặt class ở đâu

Khuyến nghị:

```text
payment/
  util/
    PaymentGatewayHttpUtil.java
```

Nếu sau này class này lớn hơn và có thêm retry, circuit breaker, metrics, auth, interceptors thì có thể đổi sang:

```text
payment/
  infrastructure/
    http/
      PaymentGatewayHttpClient.java
```

## 11. Kết luận

`PaymentGatewayHttpUtil` là hợp lý và nên có.

Nó giúp:

1. Giảm lặp code gọi HTTP giữa các gateway
2. Giữ adapter gọn hơn
3. Dễ chuẩn hóa timeout, error handling và logging

Nhưng nên giữ đúng ranh giới:

- util chỉ lo gọi HTTP
- adapter lo business riêng của từng cổng thanh toán
