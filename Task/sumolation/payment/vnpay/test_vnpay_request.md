# VNPAY Demo Request/Response

File này dùng để test nhanh flow tạo URL thanh toán VNPAY trong môi trường sandbox.

Nguồn chính thức:

- VNPAY Thanh toán PAY: https://sandbox.vnpayment.vn/apis/docs/thanh-toan-pay/pay.html
- VNPAY Query/Refund: https://sandbox.vnpayment.vn/apis/docs/truy-van-hoan-tien/querydr%26refund.html

## 1. Endpoint sandbox

```text
GET https://sandbox.vnpayment.vn/paymentv2/vpcpay.html
```

VNPAY không dùng flow `POST create payment` giống MoMo. Backend sẽ:

- Tạo order/payment `PENDING` trong DB.
- Build query params `vnp_*`.
- Sort params theo tên tăng dần.
- Tạo `vnp_SecureHash`.
- Trả `paymentUrl` cho frontend.
- Frontend redirect user sang `paymentUrl`.

## 2. Thông tin cần có

```text
vnp_TmnCode     = mã website do VNPAY cấp
vnp_HashSecret  = secret dùng ký HMAC SHA512
vnp_PayUrl      = https://sandbox.vnpayment.vn/paymentv2/vpcpay.html
vnp_ReturnUrl   = URL frontend/backend để user quay về sau thanh toán
vnp_IpnUrl      = URL backend nhận IPN, cấu hình với VNPAY
```

Lưu ý:

- `vnp_HashSecret` không gửi sang VNPAY.
- `vnp_HashSecret` chỉ dùng để tạo/verify checksum.
- Không commit secret thật lên Git.
- `vnp_ReturnUrl` và `IPN URL` production phải là HTTPS public domain.

## 3. Request backend của website

Frontend gọi backend của mình:

```http
POST /api/payments/vnpay/create
Content-Type: application/json
```

Body mẫu:

```json
{
  "orderId": "ORDER_20260603_0001",
  "amount": 10000,
  "orderInfo": "Thanh toan don hang ORDER_20260603_0001",
  "bankCode": "",
  "locale": "vn"
}
```

Ý nghĩa:

- `amount = 10000`: số tiền thật theo VND.
- Khi gửi sang VNPAY, backend phải nhân `100`, tức `vnp_Amount = 1000000`.
- `bankCode` để rỗng nếu muốn user chọn phương thức tại VNPAY.

## 4. Params tạo URL VNPAY mẫu

```text
vnp_Version=2.1.0
vnp_Command=pay
vnp_TmnCode=DEMOV210
vnp_Amount=1000000
vnp_CurrCode=VND
vnp_IpAddr=127.0.0.1
vnp_Locale=vn
vnp_OrderInfo=Thanh toan don hang ORDER_20260603_0001
vnp_OrderType=other
vnp_ReturnUrl=https://your-domain.com/payment/vnpay/return
vnp_TxnRef=ORDER_20260603_0001
vnp_CreateDate=20260603120000
vnp_ExpireDate=20260603121500
```

Nếu muốn ép phương thức thanh toán:

```text
vnp_BankCode=VNPAYQR
```

Một số `vnp_BankCode` thường gặp:

- `VNPAYQR`: thanh toán quét QR.
- `VNBANK`: thẻ ATM/tài khoản ngân hàng nội địa.
- `INTCARD`: thẻ quốc tế.
- Bỏ trống: user tự chọn phương thức tại VNPAY.

## 5. Raw data để ký

Sort params theo tên tăng dần rồi nối query string:

```text
vnp_Amount=1000000&vnp_Command=pay&vnp_CreateDate=20260603120000&vnp_CurrCode=VND&vnp_ExpireDate=20260603121500&vnp_IpAddr=127.0.0.1&vnp_Locale=vn&vnp_OrderInfo=Thanh+toan+don+hang+ORDER_20260603_0001&vnp_OrderType=other&vnp_ReturnUrl=https%3A%2F%2Fyour-domain.com%2Fpayment%2Fvnpay%2Freturn&vnp_TmnCode=DEMOV210&vnp_TxnRef=ORDER_20260603_0001&vnp_Version=2.1.0
```

Ký bằng:

```text
HmacSHA512(hashData, vnp_HashSecret)
```

Sau đó append:

```text
&vnp_SecureHash={secureHash}
```

## 6. Payment URL mẫu

```text
https://sandbox.vnpayment.vn/paymentv2/vpcpay.html?vnp_Amount=1000000&vnp_Command=pay&vnp_CreateDate=20260603120000&vnp_CurrCode=VND&vnp_ExpireDate=20260603121500&vnp_IpAddr=127.0.0.1&vnp_Locale=vn&vnp_OrderInfo=Thanh+toan+don+hang+ORDER_20260603_0001&vnp_OrderType=other&vnp_ReturnUrl=https%3A%2F%2Fyour-domain.com%2Fpayment%2Fvnpay%2Freturn&vnp_TmnCode=DEMOV210&vnp_TxnRef=ORDER_20260603_0001&vnp_Version=2.1.0&vnp_SecureHash=YOUR_HMAC_SHA512_HASH
```

Backend nên trả về cho frontend:

```json
{
  "txnRef": "ORDER_20260603_0001",
  "amount": 10000,
  "paymentUrl": "https://sandbox.vnpayment.vn/paymentv2/vpcpay.html?...",
  "status": "PENDING"
}
```

Frontend:

```js
window.location.href = response.paymentUrl;
```

## 7. ReturnUrl mẫu

Sau khi user thanh toán, VNPAY redirect về `vnp_ReturnUrl` với query params tương tự:

```text
GET https://your-domain.com/payment/vnpay/return
  ?vnp_Amount=1000000
  &vnp_BankCode=NCB
  &vnp_BankTranNo=VNP14226112
  &vnp_CardType=ATM
  &vnp_OrderInfo=Thanh+toan+don+hang+ORDER_20260603_0001
  &vnp_PayDate=20260603120530
  &vnp_ResponseCode=00
  &vnp_TmnCode=DEMOV210
  &vnp_TransactionNo=14226112
  &vnp_TransactionStatus=00
  &vnp_TxnRef=ORDER_20260603_0001
  &vnp_SecureHash=RETURN_SECURE_HASH
```

Ý nghĩa:

- `vnp_ResponseCode=00`: giao dịch thành công theo response.
- `vnp_TransactionStatus=00`: trạng thái giao dịch thành công.
- `vnp_TransactionNo`: mã giao dịch tại VNPAY.
- `vnp_TxnRef`: mã giao dịch/order phía merchant.

Không làm:

- Không mark `PAID` chỉ dựa vào ReturnUrl.
- Không tin params nếu chưa verify `vnp_SecureHash`.

Nên làm:

- Verify chữ ký.
- Hiển thị kết quả tạm thời cho user.
- Đọc trạng thái chuẩn từ DB sau khi IPN cập nhật.

## 8. IPN request mẫu

VNPAY gọi IPN URL server-to-server, thường là GET với query params:

```text
GET https://your-domain.com/api/payments/vnpay/ipn
  ?vnp_Amount=1000000
  &vnp_BankCode=NCB
  &vnp_BankTranNo=VNP14226112
  &vnp_CardType=ATM
  &vnp_OrderInfo=Thanh+toan+don+hang+ORDER_20260603_0001
  &vnp_PayDate=20260603120530
  &vnp_ResponseCode=00
  &vnp_TmnCode=DEMOV210
  &vnp_TransactionNo=14226112
  &vnp_TransactionStatus=00
  &vnp_TxnRef=ORDER_20260603_0001
  &vnp_SecureHash=IPN_SECURE_HASH
```

Backend xử lý:

- Verify `vnp_SecureHash`.
- Tìm payment theo `vnp_TxnRef`.
- Check `vnp_Amount` đúng DB.
- Nếu `vnp_ResponseCode=00` và `vnp_TransactionStatus=00`, cập nhật `SUCCESS`.
- Nếu fail, cập nhật `FAILED` hoặc giữ `PENDING` tùy nghiệp vụ.
- Lưu `vnp_TransactionNo`.

## 9. IPN response mẫu

Confirm thành công:

```json
{
  "RspCode": "00",
  "Message": "Confirm Success"
}
```

Sai checksum:

```json
{
  "RspCode": "97",
  "Message": "Invalid Checksum"
}
```

Không tìm thấy order:

```json
{
  "RspCode": "01",
  "Message": "Order not Found"
}
```

Sai amount:

```json
{
  "RspCode": "04",
  "Message": "Invalid amount"
}
```

Order đã confirm:

```json
{
  "RspCode": "02",
  "Message": "Order already confirmed"
}
```

## 10. QueryDR request mẫu

Dùng khi cần truy vấn lại kết quả giao dịch.

Endpoint sandbox:

```text
POST https://sandbox.vnpayment.vn/merchant_webapi/api/transaction
Content-Type: application/json
```

Body mẫu:

```json
{
  "vnp_RequestId": "REQ_20260603_0001",
  "vnp_Version": "2.1.0",
  "vnp_Command": "querydr",
  "vnp_TmnCode": "DEMOV210",
  "vnp_TxnRef": "ORDER_20260603_0001",
  "vnp_OrderInfo": "Truy van giao dich ORDER_20260603_0001",
  "vnp_TransactionDate": "20260603120000",
  "vnp_CreateDate": "20260603122000",
  "vnp_IpAddr": "127.0.0.1",
  "vnp_SecureHash": "QUERYDR_HMAC_HASH"
}
```

Ghi chú:

- QueryDR có raw signature riêng theo tài liệu VNPAY.
- Không dùng QueryDR thay IPN trong flow bình thường.
- Dùng QueryDR cho job đối soát hoặc khi payment kẹt `PENDING`.

## 11. Lỗi thường gặp khi test

- Sai `vnp_HashSecret`: VNPAY báo invalid checksum.
- Quên nhân `amount * 100`: thanh toán lệch tiền.
- `vnp_TxnRef` bị trùng: giao dịch không hợp lệ hoặc khó đối soát.
- Dùng tiếng Việt có dấu/ký tự đặc biệt trong `vnp_OrderInfo`: dễ lỗi encode hoặc checksum.
- Build hash data không sort theo tên params.
- Dùng encode khác nhau giữa hash data và query URL.
- Dùng `localhost` cho ReturnUrl/IPN production.
- Mark `PAID` bằng ReturnUrl trước khi IPN xác nhận.

