CQRS (Command Query Responsibility Segregation) là một mẫu thiết kế kiến trúc hệ thống (System Design Pattern) chia tách hoàn toàn hai hoạt động cốt lõi của phần mềm: **Đọc dữ liệu (Query)** và **Ghi/Sửa/Xóa dữ liệu (Command)** thành hai luồng xử lý độc lập.

Hãy tưởng tượng bạn đang điều hành một thư viện. Thay vì dùng một quầy duy nhất cho cả việc mượn/trả sách lẫn hỏi thông tin, CQRS sẽ tách thành hai khu:

* **Khu A (Command):** Chỉ tiếp nhận sách được trả lại hoặc đóng dấu cho mượn. (Thao tác làm thay đổi số lượng sách).
* **Khu B (Query):** Chỉ để tra cứu xem sách nào đang nằm ở kệ nào. (Thao tác chỉ đọc thông tin, không thay đổi số lượng).

### Sự khác biệt giữa CRUD truyền thống và CQRS

Trong kiến trúc **CRUD** (Create, Read, Update, Delete) thông thường, chúng ta sử dụng cùng một Model (đối tượng) và cùng một Database để thực hiện mọi thao tác.

* **Nhược điểm của CRUD khi hệ thống lớn:** Lượng người đọc (Query) luôn áp đảo lượng người ghi (Command). Khi có một chương trình khuyến mãi, hàng ngàn người lao vào xem sản phẩm (Read), nhưng chỉ có vài người nhấn nút "Mua" (Update). Nếu để chung một Database, thao tác Read dồn dập sẽ làm nghẽn kết nối, khiến thao tác Update bị kẹt lại, dẫn đến toàn bộ hệ thống bị chậm.

Với **CQRS**, hệ thống tách đôi trách nhiệm:

* **Command (Luồng Ghi):** Xử lý logic nghiệp vụ phức tạp. Khi tiếp nhận yêu cầu thay đổi dữ liệu (vd: Tạo đơn hàng), hệ thống ghi vào một Write Database (thường là cơ sở dữ liệu quan hệ như PostgreSQL để đảm bảo tính toàn vẹn).
* **Query (Luồng Đọc):** Chỉ tập trung vào việc đọc dữ liệu nhanh nhất có thể. Hệ thống sử dụng một hoặc nhiều Read Database (thường là NoSQL như MongoDB hoặc Elasticsearch, được cấu trúc sẵn để phục vụ việc truy vấn mà không cần các lệnh `JOIN` phức tạp).

### CQRS hoạt động thế nào? (Cơ chế đồng bộ hóa)

Nếu tách hai Database ra, làm sao để dữ liệu bên Đọc được cập nhật khi bên Ghi thay đổi? Đây là lúc CQRS cần sự kết hợp của **Event-Driven Architecture** (Kiến trúc hướng sự kiện).

1. Người dùng nhấn "Mua hàng" (Command).
2. Write Database lưu thông tin đơn hàng thành công.
3. Hệ thống bắn một thông báo (Event) vào Message Broker (Ví dụ: Một tin nhắn ném vào topic `orders` trên Kafka).
4. Luồng Query (Read Model) liên tục lắng nghe Kafka. Khi thấy có sự kiện mới, nó lập tức lấy thông tin đơn hàng đó và cập nhật vào Read Database của mình.

### Ưu điểm tuyệt đối của CQRS

* **Mở rộng quy mô độc lập (Independent Scaling):** Nếu website bị quá tải vì người dùng xem hàng nhiều, bạn chỉ cần mua thêm RAM/CPU hoặc chạy thêm node cho phần Query (Đọc) mà không tốn tiền nâng cấp phần Command (Ghi).
* **Tối ưu hóa Database:** Bạn có thể dùng MySQL cho Write (vì cần độ chính xác cao) và dùng Redis/Elasticsearch cho Read (vì cần tìm kiếm siêu tốc).
* **Mô hình dữ liệu linh hoạt:** Không cần ép các lệnh Select phức tạp vào chung một bảng với các lệnh Insert.

Tuy nhiên, CQRS cũng mang lại một nhược điểm chí mạng là **độ trễ (Eventual Consistency)**. Sẽ luôn có một khoảng thời gian trễ rất nhỏ (mili-giây) từ lúc Write DB cập nhật cho đến khi Read DB nhận được dữ liệu thông qua Kafka. Người dùng có thể vừa tạo đơn hàng thành công, nhưng F5 tải lại trang ngay lập tức lại không thấy đơn hàng đâu (vì hệ thống Read chưa kịp đồng bộ).

Mô hình kiến trúc CQRS này là một bước tiến rất mạnh mẽ, thường xuyên được áp dụng chung với Message Broker để đảm bảo tính linh hoạt. Cấu trúc Kafka phân tán mà bạn đang tìm hiểu ở trên chính là trái tim để duy trì hệ sinh thái này đấy!