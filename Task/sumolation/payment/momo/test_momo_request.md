# MoMo Demo Request/Response

File này dùng để test nhanh API tạo thanh toán MoMo trong môi trường demo/sandbox.

Nguồn chính thức:

- MoMo Thanh Toán Thông Thường: https://developers.momo.vn/v3/vi/docs/payment/api/wallet/onetime/

## 1. Endpoint demo

```text
POST https://test-payment.momo.vn/v2/gateway/api/create
Content-Type: application/json
```

Mục tiêu:

- Backend gửi request tạo giao dịch.
- MoMo trả về `payUrl`.
- Frontend redirect user sang `payUrl` để thanh toán.

## 2. RequestType nên dùng để test website

```text
requestType = captureWallet
```

Ý nghĩa:

- Đây là flow thanh toán ví MoMo thông thường.
- Phù hợp website checkout cơ bản.
- Backend tạo request, MoMo trả về link thanh toán.

## 3. Các thông tin cần có

```text
partnerCode  = do MoMo cấp
accessKey    = do MoMo cấp
secretKey    = do MoMo cấp
endpoint     = https://test-payment.momo.vn/v2/gateway/api/create
redirectUrl  = URL frontend để user quay về sau thanh toán
ipnUrl       = URL backend nhận kết quả thanh toán server-to-server
```

Lưu ý:

- `secretKey` không gửi lên request.
- `secretKey` chỉ dùng để ký HMAC SHA256.
- Không commit `secretKey` thật lên Git.
- `ipnUrl` không được là `localhost` nếu muốn MoMo gọi được từ internet.

## 4. Raw signature format cho captureWallet

Theo tài liệu MoMo, raw signature cần đúng thứ tự:

```text
accessKey=$accessKey&amount=$amount&extraData=$extraData&ipnUrl=$ipnUrl&orderId=$orderId&orderInfo=$orderInfo&partnerCode=$partnerCode&redirectUrl=$redirectUrl&requestId=$requestId&requestType=$requestType
```

Ví dụ raw signature:

```text
accessKey=F8BBA8422F2F6A86&amount=1000&extraData=eyJza3VzIjoiIn0=&ipnUrl=https://example.com/momo_ip&orderId=Partner_Transaction_ID_1721725424433&orderInfo=Thank you for your purchase at MoMo_test&partnerCode=MOMOT5BZ20231213_TEST&redirectUrl=https://momo.vn/&requestId=Request_ID_1721725424433&requestType=captureWallet
```

Sau đó ký bằng:

```text
HmacSHA256(rawSignature, secretKey)
```

## 5. Request mẫu từ tài liệu MoMo

Đây là mẫu từ tài liệu MoMo, dùng để hiểu format field.

```json
{
  "partnerCode": "MOMOT5BZ20231213_TEST",
  "requestType": "captureWallet",
  "ipnUrl": "https://example.com/momo_ip",
  "redirectUrl": "https://momo.vn/",
  "orderId": "Partner_Transaction_ID_1721725424433",
  "amount": "1000",
  "orderInfo": "Thank you for your purchase at MoMo_test",
  "requestId": "Request_ID_1721725424433",
  "extraData": "eyJza3VzIjoiIn0=",
  "signature": "5d9eae90a89b45731c7667e9056c95739eb5162a272dfc288aac6090e762b0b9",
  "lang": "en"
}
```

Ghi chú:

- `amount` trong docs sample là `"1000"`, nhưng theo mô tả field là kiểu `Long`.
- Khi code Spring Boot, nên dùng `Long`.
- `extraData` có thể là chuỗi rỗng `""` hoặc base64 JSON.

## 6. cURL mẫu

```bash
curl --location 'https://test-payment.momo.vn/v2/gateway/api/create' \
  --header 'Content-Type: application/json' \
  --data '{
    "partnerCode": "MOMOT5BZ20231213_TEST",
    "requestType": "captureWallet",
    "ipnUrl": "https://example.com/momo_ip",
    "redirectUrl": "https://momo.vn/",
    "orderId": "Partner_Transaction_ID_1721725424433",
    "amount": 1000,
    "orderInfo": "Thank you for your purchase at MoMo_test",
    "requestId": "Request_ID_1721725424433",
    "extraData": "eyJza3VzIjoiIn0=",
    "signature": "5d9eae90a89b45731c7667e9056c95739eb5162a272dfc288aac6090e762b0b9",
    "lang": "en"
  }'
```

Nếu muốn test bằng thông tin của bạn:

- Đổi `partnerCode`.
- Đổi `accessKey` trong raw signature.
- Đổi `secretKey` khi ký.
- Đổi `orderId`.
- Đổi `requestId`.
- Đổi `amount`.
- Đổi `redirectUrl`.
- Đổi `ipnUrl`.
- Tạo lại `signature`.

## 7. Response success mẫu

MoMo trả về response tương tự:

```json
{
  "partnerCode": "MOMOT5BZ20231213_TEST",
  "orderId": "Partner_Transaction_ID_1721720620078",
  "requestId": "Request_ID_1721720620078",
  "amount": 1000,
  "responseTime": 1721720619912,
  "message": "Successful.",
  "resultCode": 0,
  "payUrl": "https://test-payment.momo.vn/v2/gateway/pay?t=TU9NT1Q1QloyMDIzMTIxM19URVNUfFBhcnRuZXJfVHJhbnNhY3Rpb25fSURfMTcyMTcyMDYyMDA3OA&s=6c14385cd4355e0abe0e0563a2da20705bceca9fac79746b2bf6a4c380374b44",
  "deeplink": "momo://app?action=payWithApp&isScanQR=false&serviceType=app&sid=TU9NT1Q1QloyMDIzMTIxM19URVNUfFBhcnRuZXJfVHJhbnNhY3Rpb25fSURfMTcyMTcyMDYyMDA3OA&v=3.0",
  "qrCodeUrl": "00020101021226110007vn.momo38260010A0000007270208QRIBFTTA5303704540410005802VN62480515MMTCfKWQmuH5nQR0825Thank you for your purcha6304B293"
}
```

Ý nghĩa:

- `resultCode = 0`: tạo payment request thành công.
- `payUrl`: URL redirect user sang trang thanh toán MoMo.
- `deeplink`: mở app MoMo trên mobile.
- `qrCodeUrl`: dữ liệu tạo QR, không phải URL ảnh QR.

Backend nên trả về cho frontend:

```json
{
  "orderId": "Partner_Transaction_ID_1721720620078",
  "requestId": "Request_ID_1721720620078",
  "amount": 1000,
  "paymentUrl": "https://test-payment.momo.vn/v2/gateway/pay?...",
  "status": "PENDING"
}
```

Frontend:

- Nhận `paymentUrl`.
- Redirect user sang `paymentUrl`.
- Không tự đánh dấu order là `PAID`.

## 8. Response lỗi mẫu

Ví dụ sai signature hoặc thông tin request:

```json
{
  "partnerCode": "MOMOT5BZ20231213_TEST",
  "orderId": "Partner_Transaction_ID_1721725424433",
  "requestId": "Request_ID_1721725424433",
  "amount": 1000,
  "responseTime": 1721720619912,
  "message": "Invalid signature.",
  "resultCode": 5
}
```

Ghi chú:

- `resultCode` cụ thể có thể khác tùy lỗi thực tế.
- Khi debug, luôn log:
  - `orderId`
  - `requestId`
  - `amount`
  - `resultCode`
  - `message`
- Không log `secretKey`.

## 9. IPN request mẫu từ MoMo

Sau khi user thanh toán, MoMo sẽ gọi `ipnUrl` của backend.

```json
{
  "orderType": "momo_wallet",
  "amount": 1000,
  "partnerCode": "MOMOT5BZ20231213_TEST",
  "orderId": "Partner_Transaction_ID_1721720620078",
  "extraData": "eyJza3VzIjoiIn0=",
  "signature": "7b9f4ca728076c32f16041cbc917ebf5e6e7359f0bde343dde3add69a518cf0d",
  "transId": 4088878653,
  "responseTime": 1721720663942,
  "resultCode": 0,
  "message": "Successful.",
  "payType": "qr",
  "requestId": "Request_ID_1721720620078",
  "orderInfo": "Thank you for your purchase at MoMo_test"
}
```

Backend cần:

- Verify `signature`.
- Check `partnerCode`.
- Check `orderId`.
- Check `amount`.
- Check payment hiện tại có còn `PENDING` không.
- Nếu `resultCode = 0`, cập nhật payment `SUCCESS`.
- Nếu khác `0`, cập nhật `FAILED` hoặc giữ trạng thái phù hợp.
- Trả HTTP `204 No Content`.

## 10. Raw signature format cho IPN

Theo tài liệu MoMo:

```text
accessKey=$accessKey&amount=$amount&extraData=$extraData&message=$message&orderId=$orderId&orderInfo=$orderInfo&orderType=$orderType&partnerCode=$partnerCode&payType=$payType&requestId=$requestId&responseTime=$responseTime&resultCode=$resultCode&transId=$transId
```

Ví dụ:

```text
accessKey=F8BBA8422F2F6A86&amount=1000&extraData=eyJza3VzIjoiIn0=&message=Successful.&orderId=Partner_Transaction_ID_1721720620078&orderInfo=Thank you for your purchase at MoMo_test&orderType=momo_wallet&partnerCode=MOMOT5BZ20231213_TEST&payType=qr&requestId=Request_ID_1721720620078&responseTime=1721720663942&resultCode=0&transId=4088878653
```

Ký bằng:

```text
HmacSHA256(rawIpnSignature, secretKey)
```

## 11. Postman setup nhanh

### Method

```text
POST
```

### URL

```text
https://test-payment.momo.vn/v2/gateway/api/create
```

### Headers

```text
Content-Type: application/json
```

### Body

Chọn `raw` -> `JSON`, dán request mẫu:

```json
{
  "partnerCode": "YOUR_PARTNER_CODE",
  "requestType": "captureWallet",
  "ipnUrl": "https://your-public-domain.com/api/payments/momo/ipn",
  "redirectUrl": "https://your-frontend-domain.com/payment/momo/return",
  "orderId": "ORDER_100001",
  "amount": 1000,
  "orderInfo": "Thanh toan don hang ORDER_100001",
  "requestId": "REQ_ORDER_100001",
  "extraData": "",
  "signature": "GENERATED_SIGNATURE",
  "lang": "vi"
}
```

## 12. Node.js snippet tạo signature để test nhanh

Nếu muốn tạo signature nhanh ngoài Java:

```js
const crypto = require("crypto");

const accessKey = "YOUR_ACCESS_KEY";
const secretKey = "YOUR_SECRET_KEY";

const data = {
  partnerCode: "YOUR_PARTNER_CODE",
  requestType: "captureWallet",
  ipnUrl: "https://your-public-domain.com/api/payments/momo/ipn",
  redirectUrl: "https://your-frontend-domain.com/payment/momo/return",
  orderId: "ORDER_100001",
  amount: 1000,
  orderInfo: "Thanh toan don hang ORDER_100001",
  requestId: "REQ_ORDER_100001",
  extraData: ""
};

const rawSignature =
  `accessKey=${accessKey}` +
  `&amount=${data.amount}` +
  `&extraData=${data.extraData}` +
  `&ipnUrl=${data.ipnUrl}` +
  `&orderId=${data.orderId}` +
  `&orderInfo=${data.orderInfo}` +
  `&partnerCode=${data.partnerCode}` +
  `&redirectUrl=${data.redirectUrl}` +
  `&requestId=${data.requestId}` +
  `&requestType=${data.requestType}`;

const signature = crypto
  .createHmac("sha256", secretKey)
  .update(rawSignature)
  .digest("hex");

console.log(signature);
```

## 13. Java snippet tạo signature

```java
String rawSignature = "accessKey=" + accessKey
        + "&amount=" + amount
        + "&extraData=" + extraData
        + "&ipnUrl=" + ipnUrl
        + "&orderId=" + orderId
        + "&orderInfo=" + orderInfo
        + "&partnerCode=" + partnerCode
        + "&redirectUrl=" + redirectUrl
        + "&requestId=" + requestId
        + "&requestType=" + requestType;

String signature = HmacSha256.sign(rawSignature, secretKey);
```

Xem implementation đầy đủ trong:

```text
Task/sumolation/payment/doc.md
```

## 14. Checklist trước khi bấm Send

- `endpoint` đang là sandbox.
- `partnerCode`, `accessKey`, `secretKey` đúng cùng môi trường.
- `orderId` unique cho mỗi lần test.
- `requestId` unique cho mỗi lần test.
- `amount >= 1000`.
- `amount <= 50000000`.
- `ipnUrl` là URL public HTTPS nếu muốn nhận IPN.
- `redirectUrl` là URL frontend hợp lệ.
- `signature` được tạo lại sau mọi thay đổi field.
- Không có khoảng trắng thừa trong raw signature.

## 15. Cách đọc kết quả test

### Tạo payment thành công

- HTTP status thường là `200`.
- `resultCode = 0`.
- Có `payUrl`.
- Copy `payUrl` mở trên browser để thanh toán test.

### Tạo payment thất bại

- Không có `payUrl`.
- Xem `resultCode` và `message`.
- Check lại:
  - signature.
  - partnerCode/accessKey/secretKey.
  - endpoint đúng sandbox hay production.
  - amount hợp lệ.
  - orderId/requestId có bị trùng không.

### Thanh toán thành công nhưng order chưa PAID

- Check backend có nhận IPN không.
- Check `ipnUrl` có public không.
- Check backend trả HTTP `204`.
- Check signature IPN.
- Check logic idempotency.

## 16. Rule an toàn

- Redirect chỉ để user quay lại website.
- IPN mới là nguồn chính để cập nhật payment.
- Luôn verify signature.
- Luôn check amount trong IPN với amount trong DB.
- Luôn xử lý idempotent vì IPN có thể retry.
