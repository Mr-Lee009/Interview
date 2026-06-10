# Saga Pattern

## 1. Saga Pattern là gì

`Saga Pattern` là cách xử lý một nghiệp vụ dài chạy qua nhiều service, trong đó:

- mỗi service tự xử lý `local transaction` trên database của chính nó
- sau khi hoàn tất, service sẽ phát `event` hoặc trả `response/command result`
- nếu một bước sau bị lỗi, hệ thống không rollback DB xuyên service như transaction ACID
- thay vào đó, hệ thống chạy các `compensating transaction` để hoàn tác về mặt nghiệp vụ

Nói ngắn gọn:

- `ACID transaction` rollback dữ liệu ngay trong cùng một transaction
- `Saga` bù trừ nghiệp vụ giữa nhiều transaction độc lập

## 2. Vì sao cần Saga trong microservices

Trong `monolith`, nhiều thao tác có thể nằm trong cùng một database transaction:

1. trừ tiền
2. tạo bút toán
3. cập nhật trạng thái

Nếu bước 3 lỗi thì có thể `ROLLBACK`.

Trong `microservices`, mỗi service thường có DB riêng:

- `Order Service`
- `Payment Service`
- `Inventory Service`
- `Shipping Service`

Lúc này không nên phụ thuộc vào `distributed transaction` kiểu `2PC` cho toàn hệ thống vì:

- coupling cao
- khó scale
- ảnh hưởng availability
- dễ thành bottleneck

Saga là cách phổ biến hơn để đảm bảo `business consistency` thay vì `immediate consistency`.

## 3. Bản chất của Saga

Một Saga thường có 2 loại action:

1. `forward action`
   Là bước xử lý chính của nghiệp vụ, ví dụ:
   - tạo order
   - giữ tồn kho
   - thu tiền
   - tạo shipment

2. `compensating action`
   Là bước bù trừ khi flow bị lỗi ở giữa, ví dụ:
   - hủy order
   - trả lại tồn kho
   - hoàn tiền
   - hủy shipment draft

Lưu ý quan trọng:

- compensating transaction không phải lúc nào cũng đưa dữ liệu về đúng trạng thái ban đầu 100%
- có bước bù tự động được, có bước phải `manual reconciliation`
- vì vậy Saga là mô hình đảm bảo `eventual consistency`

## 4. Hai cách triển khai Saga

### 4.1 Choreography

Các service tự phản ứng với event của nhau, không có coordinator trung tâm.

Ví dụ:

1. `Order Service` phát `OrderCreated`
2. `Inventory Service` nhận event và giữ hàng, rồi phát `InventoryReserved`
3. `Payment Service` nhận event và thu tiền, rồi phát `PaymentCompleted`
4. `Shipping Service` nhận event và tạo vận đơn

Khi lỗi:

1. `Payment Service` phát `PaymentFailed`
2. `Inventory Service` nhận event lỗi và trả lại tồn kho
3. `Order Service` cập nhật order sang `CANCELLED`

Ưu điểm:

- loose coupling ở mức điều phối
- không cần một coordinator riêng
- hợp với flow ngắn, đơn giản

Nhược điểm:

- khó trace end-to-end
- logic nghiệp vụ bị phân tán
- càng nhiều bước càng dễ rối event

### 4.2 Orchestration

Có một `Saga Orchestrator` hoặc `Workflow Coordinator` điều phối toàn bộ flow.

Ví dụ:

1. orchestrator gọi `Order Service`
2. orchestrator gọi `Inventory Service`
3. orchestrator gọi `Payment Service`
4. orchestrator gọi `Shipping Service`
5. nếu lỗi ở bước nào, orchestrator ra lệnh bù trừ cho các bước trước

Ưu điểm:

- dễ nhìn flow tổng thể
- dễ debug
- hợp với workflow dài hoặc nhiều nhánh điều kiện

Nhược điểm:

- coordinator là central dependency
- nếu thiết kế kém có thể thành bottleneck
- service bị phụ thuộc nhiều hơn vào coordinator

Lưu ý:

- orchestrator không nhất thiết là `single point of failure`
- nếu làm production đúng cách, nó có thể chạy HA, lưu state bền vững và resume sau khi restart

## 5. Ví dụ thực tế: Đặt hàng trên sàn thương mại điện tử

Đây là ví dụ tôi thấy thực tế và dễ hiểu hơn ví dụ chuyển tiền.

### 5.1 Yêu cầu nghiệp vụ

Người dùng đặt một đơn hàng.

Hệ thống cần làm các bước:

1. tạo order
2. giữ tồn kho
3. thanh toán
4. tạo shipment
5. gửi thông báo xác nhận

Các service tham gia:

- `Order Service`
- `Inventory Service`
- `Payment Service`
- `Shipping Service`
- `Notification Service`

### 5.2 Forward flow

1. `Order Service` tạo order với trạng thái `PENDING`
2. `Inventory Service` giữ số lượng sản phẩm
3. `Payment Service` thu tiền hoặc authorize payment
4. `Shipping Service` tạo vận đơn nháp
5. `Order Service` cập nhật trạng thái `CONFIRMED`
6. `Notification Service` gửi email hoặc push notification

### 5.3 Trường hợp lỗi

Giả sử flow lỗi ở bước `Shipping Service`.

Khi đó:

1. `Shipping Service` tạo vận đơn thất bại
2. Saga xác định flow không thể hoàn tất
3. `Payment Service` thực hiện hoàn tiền hoặc void authorization
4. `Inventory Service` trả lại tồn kho
5. `Order Service` cập nhật trạng thái `FAILED` hoặc `CANCELLED`

### 5.4 Điều cần làm rõ trong thiết kế

Đây là chỗ nhiều tài liệu viết quá đẹp nhưng không thực tế. Khi design thật, cần trả lời rõ:

1. Nếu đã thu tiền thành công nhưng hoàn tiền lỗi thì sao?
2. Nếu callback của cổng thanh toán đến muộn thì order xử lý thế nào?
3. Nếu message bị gửi lại 2 lần thì có giữ tồn kho 2 lần không?
4. Nếu `Shipping Service` thành công nhưng response timeout thì coordinator nghĩ là fail hay success?
5. Nếu một bước cần con người xử lý thì trạng thái trung gian nào sẽ được dùng?

Đó mới là phần khó thật của Saga.

## 6. Các trạng thái thường gặp

Một Saga thường cần status rõ ràng cho từng bước và cho toàn flow.

Ví dụ `order status`:

- `PENDING`
- `PROCESSING`
- `CONFIRMED`
- `FAILED`
- `CANCELLED`
- `COMPENSATING`
- `COMPENSATED`

Ví dụ `payment status`:

- `INIT`
- `AUTHORIZED`
- `CAPTURED`
- `FAILED`
- `REFUND_PENDING`
- `REFUNDED`

Không có status rõ ràng thì rất khó debug và retry an toàn.

## 7. Những vấn đề phải xử lý khi dùng Saga

### 7.1 Idempotency

Message có thể bị gửi lại do:

- broker redelivery
- consumer retry
- timeout rồi retry
- duplicate callback từ bên thứ ba

Vì vậy mỗi bước cần chống chạy lặp:

- dùng `transactionId`, `orderId`, `eventId`, `requestId`
- lưu bảng processed event hoặc idempotency key
- cập nhật state theo nguyên tắc an toàn khi retry

### 7.2 Retry

Không phải lỗi nào cũng nên bù trừ ngay.

Nên phân biệt:

- `transient error`: timeout, network glitch, service tạm unavailable
- `business error`: hết hàng, thẻ bị từ chối, user không hợp lệ

Với `transient error`, thường nên retry trước.
Với `business error`, thường nên fail sớm và chạy compensation.

### 7.3 Observability

Saga mà không có tracing thì rất khó vận hành.

Cần có:

- `traceId`
- `correlationId`
- log theo step
- metric theo số lần fail, retry, compensate
- dashboard theo trạng thái saga

### 7.4 Timeout và trạng thái treo

Một bước có thể không trả kết quả ngay.

Ví dụ:

- cổng thanh toán chưa callback
- shipping provider xử lý chậm
- inventory lock chưa được xác nhận

Khi đó cần:

- timeout rule
- trạng thái chờ
- job reconciliation
- cơ chế resume flow

## 8. Khi nào nên dùng Saga

Nên dùng khi:

- flow đi qua nhiều service
- mỗi service có DB riêng
- cần đảm bảo nhất quán nghiệp vụ
- có thể chấp nhận `eventual consistency`

Không nên dùng khi:

- chỉ có một service hoặc một DB
- flow rất ngắn và có thể xử lý bằng local transaction
- nghiệp vụ không có cách bù trừ rõ ràng
- team chưa có khả năng vận hành message-driven system

## 9. Chọn Choreography hay Orchestration

Tôi thường chọn như sau:

- chọn `Choreography` khi flow ngắn, ít bước, ít nhánh, team quen event-driven
- chọn `Orchestration` khi flow dài, nhiều rule, nhiều nhánh fail, cần dễ debug

Nếu bài toán là:

- `order -> reserve stock -> pay -> ship`
- có nhiều branch như `COD`, `prepaid`, `split shipment`, `partial refund`

thì tôi nghiêng về `Orchestration`.

## 10. Kết luận

Saga không thay thế ACID transaction.

Saga là cách phối hợp nhiều `local transaction` để giữ cho hệ thống nhất quán về mặt nghiệp vụ trong môi trường phân tán.

Điểm quan trọng nhất không phải là vẽ được flow đẹp, mà là trả lời được:

- bước nào là forward action
- bước nào là compensating action
- idempotency xử lý ra sao
- retry ở đâu
- timeout ở đâu
- trace như thế nào
- trạng thái cuối cùng của từng bước là gì

Nếu trả lời được các câu đó, bạn mới thật sự thiết kế Saga ổn.
