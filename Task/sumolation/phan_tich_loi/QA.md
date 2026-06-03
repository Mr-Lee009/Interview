Để giúp bạn rèn luyện tư duy xử lý lỗi trong môi trường **Microservices**, tôi sẽ đưa ra 3 ví dụ "kinh điển" nhất mà các kỹ sư thường gặp. Đây là những lỗi thường rất khó tái hiện vì nó liên quan đến sự phối hợp giữa nhiều dịch vụ.

---

### 1. Lỗi "Dây chuyền" (Cascading Failure) do Timeout

**Tình huống:** Service A gọi Service B, Service B gọi Service C.

* **Vấn đề:** Service C bị quá tải (CPU 100%) và phản hồi cực chậm. Service B đợi C nên cũng bị treo (block thread), dẫn đến service A cũng treo theo. Cuối cùng, toàn bộ hệ thống bị "đứng" dù Service A và B không hề lỗi code.
* **Cách check:**
* Kiểm tra **Distributed Tracing** (Jaeger/Zipkin) để xem request bị "nghẽn" ở đâu.
* Xem **Service Map** để biết request nào gây ra hiệu ứng domino.
* Sử dụng **Circuit Breaker** (như Resilience4j) để ngắt kết nối với service đang lỗi, tránh làm sập cả hệ thống.



---

### 2. Lỗi Nhất quán dữ liệu (Data Inconsistency) trong Distributed Transaction

**Tình huống:** Bạn thực hiện một luồng mua hàng: Trừ tiền ở *Wallet Service* $\rightarrow$ Trừ kho ở *Inventory Service*.

* **Vấn đề:** Trừ tiền thành công, nhưng đến bước trừ kho thì *Inventory Service* bị lỗi network. Người dùng đã mất tiền nhưng đơn hàng vẫn không được tạo.
* **Cách check:**
* Vì không có Transaction ACID giữa các service, bạn không thể dùng `rollback` thông thường.
* Phải check **Log của Message Broker** (như Kafka/RabbitMQ) để xem message có bị mất không (lost message) hoặc bị xử lý lặp (duplicate message).
* Sử dụng cơ chế **Saga Pattern** để thực hiện các giao dịch bù trừ (compensating transaction) - nếu bước 2 lỗi thì tự động chạy một lệnh hoàn tiền ở bước 1.



---

### 3. Lỗi "Ghost" (Lỗi môi trường/Cấu hình)

**Tình huống:** Service hoạt động bình thường ở môi trường Dev, nhưng lên Prod thì thỉnh thoảng lỗi "Connection Refused" hoặc "404 Not Found" mà không theo quy luật.

* **Vấn đề:** Do hệ thống Microservices thường chạy trên Kubernetes (K8s) với nhiều Pod. Lỗi này có thể do **DNS resolution** không kịp hoặc **Load Balancer** điều hướng request đến một Pod đang trong quá trình khởi động (startup) nhưng chưa sẵn sàng.
* **Cách check:**
* Kiểm tra **Kubernetes Event Log**: xem Pod có bị restart liên tục (CrashLoopBackOff) không.
* Kiểm tra **Readiness/Liveness Probe** xem cấu hình đã chuẩn chưa.
* Kiểm tra **Service Mesh** (như Istio) nếu hệ thống có sử dụng để quản lý lưu lượng, đôi khi do cấu hình routing sai.



---

### 💡 Bài tập giả định để bạn thực hành:

**Tình huống:** "Hệ thống Bán hàng của em báo lỗi `500 Internal Server Error` ngẫu nhiên cho khoảng 0.1% đơn hàng. Em không thể tái hiện được trên môi trường Staging dù đã thử mọi cách. Em sẽ làm gì?"

**Gợi ý trả lời phỏng vấn:**

1. **Thu thập bằng chứng:** "Em sẽ kiểm tra **Log của các service liên quan** trong khoảng thời gian đó qua Centralized Logging (ELK Stack/Splunk), tìm kiếm theo `Correlation ID` (định danh duy nhất cho mỗi request đi qua các service)."
2. **Khoanh vùng:** "Nếu log ở mức application không thấy, em sẽ kiểm tra **Infrastructure log** (Load Balancer, Ingress Controller) xem request có thực sự chạm tới service không, hay bị rớt ở tầng mạng."
3. **Giả thuyết:** "Em nghi ngờ lỗi do **Race Condition** (nhiều request cùng sửa một tài nguyên) hoặc **Timeout ngầm** khi gọi sang một 3rd party API (như cổng thanh toán) bị chậm chạp bất thường."
4. **Giải pháp:** "Em sẽ thêm các log bổ sung về `timestamp` chính xác tới từng milisecond và `input data` của các request lỗi đó để chờ đợi (monitor) đến lần tiếp theo nó xảy ra."
