# Thuật ngữ Payment Gateway

File này giải thích nhanh các thuật ngữ thường gặp khi tích hợp cổng thanh toán như MoMo, VNPAY, ZaloPay.

## 1. Thuật ngữ luồng thanh toán

| Thuật ngữ | Giải thích tiếng Việt | Ví dụ trong MoMo/VNPAY/ZaloPay | Lưu ý khi thiết kế |
|---|---|---|---|
| Payment Gateway | Cổng thanh toán trung gian giữa website và ngân hàng/ví điện tử | MoMo, VNPAY, ZaloPay | App không tự xử lý tiền trực tiếp, mà gọi gateway |
| Merchant | Đơn vị bán hàng tích hợp thanh toán | Website/app của mình | Merchant nhận credential từ gateway |
| Provider | Nhà cung cấp cổng thanh toán | MoMo, VNPAY, ZaloPay | Trong code nên dùng enum `PaymentProvider` |
| Checkout | Màn hình/quy trình khách xác nhận thanh toán | Trang thanh toán MoMo/VNPAY/ZaloPay | User thường được redirect sang gateway |
| Payment URL | URL thanh toán để frontend redirect user sang gateway | MoMo `payUrl`, VNPAY `paymentUrl`, ZaloPay `order_url` | Frontend chỉ redirect, không tự mark paid |
| Redirect | Chuyển trình duyệt user từ website sang gateway hoặc quay lại website | `redirectUrl`, `vnp_ReturnUrl`, `redirecturl` | Redirect đi qua browser, không đáng tin tuyệt đối |
| Return URL | URL user quay lại website sau khi thanh toán | VNPAY `vnp_ReturnUrl` | Chỉ dùng hiển thị kết quả, không phải nguồn cập nhật trạng thái chuẩn |
| Redirect URL | URL user quay lại website sau khi thanh toán | MoMo `redirectUrl`, ZaloPay `redirecturl` | Có thể bị user reload, copy, sửa query params |
| IPN | Instant Payment Notification, thông báo thanh toán tức thời từ gateway tới backend | MoMo `ipnUrl`, VNPAY IPN URL | Đây là server-to-server, dùng để cập nhật trạng thái sau khi verify |
| Callback | Request provider gọi về backend để báo kết quả | ZaloPay `callback_url`, MoMo IPN cũng có thể gọi là callback | Callback phải verify chữ ký trước khi update DB |
| Server-to-server | Giao tiếp trực tiếp từ server provider tới server backend của mình | Gateway gọi `/api/payments/.../ipn` | Không đi qua browser của user, tin cậy hơn redirect nhưng vẫn phải verify signature |
| Client-to-server | Frontend/browser gọi backend | Website gọi `POST /api/payments/create` | Request từ client cần auth/validate |
| Browser redirect | Chuyển hướng qua trình duyệt user | Frontend `window.location.href = paymentUrl` | Không dùng làm bằng chứng thanh toán duy nhất |

## 2. IPN/callback server-to-server là gì?

| Câu hỏi | Trả lời |
|---|---|
| IPN/callback server-to-server là gì? | Là request do cổng thanh toán chủ động gọi trực tiếp vào backend của mình để báo kết quả giao dịch. |
| Vì sao cần IPN/callback? | Vì user redirect về website có thể bị mất mạng, tắt trình duyệt, sửa URL, hoặc không quay lại. Backend vẫn cần nguồn xác nhận thanh toán độc lập. |
| Nó khác redirect như thế nào? | Redirect đi qua browser user. IPN/callback đi từ server gateway sang server backend. |
| Có tin IPN/callback ngay được không? | Không. Phải verify signature/mac/hash và đối chiếu order/amount trong DB. |
| Sau khi verify đúng thì làm gì? | Cập nhật payment `SUCCESS` hoặc `FAILED`, lưu transaction id của provider, lưu raw payload để audit/debug. |
| Nếu IPN/callback gọi nhiều lần thì sao? | Backend phải xử lý idempotent, tức gọi lại nhiều lần cũng không làm sai trạng thái hoặc cộng tiền nhiều lần. |
| Nếu IPN/callback không tới thì sao? | Dùng API query/đối soát của gateway để kiểm tra lại giao dịch đang `PENDING`. |

## 3. Thuật ngữ bảo mật và chữ ký

| Thuật ngữ | Giải thích tiếng Việt | Ví dụ | Lưu ý khi thiết kế |
|---|---|---|---|
| Signature | Chữ ký điện tử/hash để chứng minh request không bị sửa | MoMo `signature` | Backend tự tính lại rồi so sánh |
| Secure Hash | Chữ ký bảo mật dạng hash | VNPAY `vnp_SecureHash` | Loại bỏ `vnp_SecureHash` khỏi raw data khi verify |
| MAC | Message Authentication Code, mã xác thực message | ZaloPay `mac` | ZaloPay create dùng `key1`, callback dùng `key2` |
| HMAC | Hash-based Message Authentication Code | HMAC SHA256, HMAC SHA512 | Dùng secret key để ký raw data |
| Secret Key | Khóa bí mật để ký/verify | MoMo `secretKey` | Không commit Git, không trả frontend |
| Hash Secret | Secret dùng tạo secure hash | VNPAY `vnp_HashSecret` | Nên lưu trong env/Secret Manager |
| Key1 | Key ZaloPay dùng ký create/query | ZaloPay `key1` | Không dùng để verify callback |
| Key2 | Key ZaloPay dùng verify callback | ZaloPay `key2` | Callback sai key2 thì phải reject |
| Raw Data | Chuỗi dữ liệu trước khi ký | `amount=...&orderId=...` | Thứ tự field phải đúng theo docs gateway |
| Verify Signature | Tự tính lại chữ ký và so với chữ ký provider gửi | Verify IPN/callback | Là bước bắt buộc trước khi update DB |

## 4. Thuật ngữ trạng thái payment

| Thuật ngữ | Giải thích tiếng Việt | Khi nào dùng |
|---|---|---|
| PENDING | Đã tạo giao dịch, chờ user thanh toán hoặc chờ callback | Sau khi backend tạo payment URL |
| SUCCESS | Gateway xác nhận thanh toán thành công và backend verify hợp lệ | Sau IPN/callback hợp lệ |
| FAILED | Gateway báo thanh toán thất bại | User hủy, hết hạn, lỗi ngân hàng |
| EXPIRED | Giao dịch quá hạn thanh toán | Payment pending quá thời gian cho phép |
| REVIEW | Giao dịch cần kiểm tra thủ công | Sai signature, lệch amount, callback bất thường |
| Idempotency | Cơ chế xử lý lặp không gây sai dữ liệu | Callback gọi lại nhiều lần vẫn chỉ update một lần |
| Reconcile | Đối soát lại giao dịch với gateway | Job kiểm tra payment pending lâu |
| Query Payment | API hỏi lại trạng thái giao dịch từ gateway | VNPAY QueryDR, ZaloPay `/v2/query` |

## 5. Mapping theo từng gateway

| Khái niệm chung | MoMo | VNPAY | ZaloPay |
|---|---|---|---|
| URL thanh toán | `payUrl` | Backend build `paymentUrl` từ `vpcpay.html` | `order_url` |
| User quay lại website | `redirectUrl` | `vnp_ReturnUrl` | `redirecturl` |
| Server callback | `ipnUrl` | IPN URL | `callback_url` |
| Mã giao dịch merchant | `orderId` | `vnp_TxnRef` | `app_trans_id` |
| Mã giao dịch provider | `transId` | `vnp_TransactionNo` | `zp_trans_id` |
| Chữ ký create | `signature` | `vnp_SecureHash` | `mac` |
| Key ký create | `secretKey` | `vnp_HashSecret` | `key1` |
| Key verify callback | `secretKey` | `vnp_HashSecret` | `key2` |
| Amount gửi provider | VND trực tiếp | `amount * 100` | VND trực tiếp |

## 6. Rule quan trọng

| Rule | Giải thích |
|---|---|
| Không mark paid bằng redirect | Redirect là browser flow, có thể không đáng tin hoặc bị gián đoạn |
| Luôn verify chữ ký callback/IPN | Để chắc request thật sự đến từ gateway và dữ liệu không bị sửa |
| Luôn check amount với DB | Tránh case provider báo amount khác order |
| Callback/IPN phải idempotent | Provider có thể gọi lại nhiều lần |
| Lưu raw payload | Cần cho debug, audit và đối soát |
| Có query job cho pending lâu | Phòng trường hợp callback/IPN không tới |

