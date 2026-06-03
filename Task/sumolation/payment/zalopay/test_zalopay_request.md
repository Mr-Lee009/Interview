# ZaloPay Demo Request/Response

File này dùng để test nhanh API tạo thanh toán ZaloPay trong môi trường sandbox.

Nguồn chính thức:

- ZaloPay Create Order: https://docs.zalopay.vn/docs/specs/order-create/
- ZaloPay Callback: https://docs.zalopay.vn/docs/developer-tools/knowledge-base/callback
- ZaloPay Query Order: https://docs.zalopay.vn/docs/specs/order-query/

## 1. Endpoint sandbox

```text
POST https://sb-openapi.zalopay.vn/v2/create
Content-Type: application/json
```

Mục tiêu:

- Backend gửi request tạo order.
- ZaloPay trả về `order_url`.
- Frontend redirect user sang `order_url` để thanh toán.
- ZaloPay gọi `callback_url` sau khi thanh toán.

## 2. Thông tin cần có

```text
app_id          = do ZaloPay cấp
key1            = dùng ký create order/query
key2            = dùng verify callback
createEndpoint  = https://sb-openapi.zalopay.vn/v2/create
queryEndpoint   = https://sb-openapi.zalopay.vn/v2/query
callback_url    = URL backend nhận callback server-to-server
redirecturl     = URL user quay về website sau thanh toán
```

Lưu ý:

- `key1`, `key2` không gửi trực tiếp cho frontend.
- Không commit key thật lên Git.
- `callback_url` không được là `localhost` nếu muốn ZaloPay gọi được từ internet.

## 3. Request backend của website

Frontend gọi backend của mình:

```http
POST /api/payments/zalopay/create
Content-Type: application/json
```

Body mẫu:

```json
{
  "orderId": "ORDER_20260603_0001",
  "userId": "user_1001",
  "amount": 10000,
  "orderInfo": "Thanh toan don hang ORDER_20260603_0001"
}
```

Backend sẽ map thành request ZaloPay.

## 4. Request tạo order gửi sang ZaloPay

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
  "bank_code": "",
  "mac": "YOUR_HMAC_SHA256_MAC"
}
```

Ghi chú:

- `app_trans_id` nên có prefix ngày theo format `yyMMdd_orderId`.
- `amount` là số tiền VND trực tiếp, không nhân `100`.
- `embed_data` là JSON string.
- `item` là JSON array string.
- `bank_code` để rỗng nếu muốn user tự chọn phương thức.

## 5. Raw signature create order

Raw data:

```text
app_id|app_trans_id|app_user|amount|app_time|embed_data|item
```

Ví dụ:

```text
2553|260603_ORDER_20260603_0001|user_1001|10000|1780488000000|{"redirecturl":"https://your-domain.com/payment/zalopay/return"}|[{"itemid":"ORDER_20260603_0001","itemname":"Order ORDER_20260603_0001","itemprice":10000,"itemquantity":1}]
```

Ký bằng:

```text
HmacSHA256(rawData, key1)
```

## 6. cURL mẫu

```bash
curl --location 'https://sb-openapi.zalopay.vn/v2/create' \
  --header 'Content-Type: application/json' \
  --data '{
    "app_id": 2553,
    "app_user": "user_1001",
    "app_time": 1780488000000,
    "amount": 10000,
    "app_trans_id": "260603_ORDER_20260603_0001",
    "embed_data": "{\"redirecturl\":\"https://your-domain.com/payment/zalopay/return\"}",
    "item": "[{\"itemid\":\"ORDER_20260603_0001\",\"itemname\":\"Order ORDER_20260603_0001\",\"itemprice\":10000,\"itemquantity\":1}]",
    "description": "Thanh toan don hang ORDER_20260603_0001",
    "callback_url": "https://your-domain.com/api/payments/zalopay/callback",
    "bank_code": "",
    "mac": "YOUR_HMAC_SHA256_MAC"
  }'
```

Nếu đổi bất kỳ field nào trong raw data, phải tạo lại `mac`.

## 7. Response success mẫu

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

Ý nghĩa:

- `return_code = 1`: tạo order thành công.
- `order_url`: URL redirect user sang ZaloPay Gateway.
- `zp_trans_token`: token giao dịch.
- `order_token`: token order.

Backend nên trả về cho frontend:

```json
{
  "appTransId": "260603_ORDER_20260603_0001",
  "amount": 10000,
  "orderUrl": "https://qcgateway.zalopay.vn/openinapp?order=...",
  "status": "PENDING"
}
```

Frontend:

```js
window.location.href = response.orderUrl;
```

## 8. Response lỗi mẫu

Ví dụ trùng `app_trans_id`:

```json
{
  "return_code": 2,
  "return_message": "Giao dịch thất bại",
  "sub_return_code": -68,
  "sub_return_message": "DUPLICATE_APPS_TRANS_ID"
}
```

Ví dụ sai `mac`:

```json
{
  "return_code": 2,
  "return_message": "Giao dịch thất bại",
  "sub_return_code": -402,
  "sub_return_message": "Invalid mac"
}
```

Khi debug, log:

- `app_trans_id`
- `amount`
- `return_code`
- `sub_return_code`
- `sub_return_message`

Không log `key1`, `key2`.

## 9. Callback request mẫu từ ZaloPay

ZaloPay gọi backend:

```http
POST /api/payments/zalopay/callback
Content-Type: application/json
```

Body mẫu:

```json
{
  "data": "{\"app_id\":2553,\"app_trans_id\":\"260603_ORDER_20260603_0001\",\"app_time\":1780488000000,\"app_user\":\"user_1001\",\"amount\":10000,\"embed_data\":\"{\\\"redirecturl\\\":\\\"https://your-domain.com/payment/zalopay/return\\\"}\",\"item\":\"[{\\\"itemid\\\":\\\"ORDER_20260603_0001\\\",\\\"itemname\\\":\\\"Order ORDER_20260603_0001\\\",\\\"itemprice\\\":10000,\\\"itemquantity\\\":1}]\",\"zp_trans_id\":260603000000389,\"server_time\":1780488060000,\"channel\":38,\"merchant_user_id\":\"ZLP_USER_SAMPLE\",\"user_fee_amount\":0,\"discount_amount\":0,\"status\":1}",
  "mac": "CALLBACK_HMAC_SHA256_MAC",
  "type": 1
}
```

Verify callback:

```text
expectedMac = HmacSHA256(data, key2)
```

Backend chỉ cập nhật DB nếu:

- `expectedMac == mac`
- `app_id` đúng
- `app_trans_id` tồn tại
- `amount` đúng DB
- `status = 1`

## 10. Callback response mẫu

Thành công:

```json
{
  "return_code": 1,
  "return_message": "success"
}
```

Lỗi tạm thời, muốn ZaloPay callback lại:

```json
{
  "return_code": 0,
  "return_message": "temporary error"
}
```

Lỗi không callback lại:

```json
{
  "return_code": -1,
  "return_message": "invalid mac"
}
```

## 11. Query order request mẫu

Dùng khi callback bị miss hoặc payment `PENDING` quá lâu.

Endpoint:

```text
POST https://sb-openapi.zalopay.vn/v2/query
Content-Type: application/json
```

Raw mac:

```text
app_id|app_trans_id|key1
```

Body mẫu:

```json
{
  "app_id": 2553,
  "app_trans_id": "260603_ORDER_20260603_0001",
  "mac": "QUERY_HMAC_SHA256_MAC"
}
```

cURL:

```bash
curl --location 'https://sb-openapi.zalopay.vn/v2/query' \
  --header 'Content-Type: application/json' \
  --data '{
    "app_id": 2553,
    "app_trans_id": "260603_ORDER_20260603_0001",
    "mac": "QUERY_HMAC_SHA256_MAC"
  }'
```

## 12. Query order response mẫu

```json
{
  "return_code": 1,
  "return_message": "Giao dịch thành công",
  "sub_return_code": 1,
  "sub_return_message": "Giao dịch thành công",
  "is_processing": false,
  "amount": 10000,
  "zp_trans_id": 260603000000389,
  "server_time": 1780488060000,
  "discount_amount": 0
}
```

Nếu `return_code = 3` hoặc `is_processing = true`, tiếp tục giữ `PENDING` và query lại theo lịch.

## 13. Lỗi thường gặp khi test

- Sai `key1`: create/query bị invalid mac.
- Sai `key2`: callback verify fail.
- `app_trans_id` không có prefix ngày `yyMMdd`.
- `app_trans_id` bị trùng.
- `embed_data` hoặc `item` build khác giữa lúc ký và lúc gửi request.
- Dùng `amount` khác giữa DB và callback.
- Dùng callback URL `localhost`.
- Mark `PAID` bằng redirect thay vì callback.

