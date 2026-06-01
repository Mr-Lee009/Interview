# Trả Lời Ngắn Gọn Cho 10 Câu Hỏi Phỏng Vấn Java Mid-Level

1. `==` so sánh địa chỉ tham chiếu hoặc giá trị primitive, còn `equals()` so sánh nội dung đối tượng. Dùng `==` cho primitive hoặc khi cần kiểm tra cùng một object; dùng `equals()` khi so sánh dữ liệu.

2. `HashMap` lưu dữ liệu theo cặp key-value, dùng `hashCode()` để xác định bucket và `equals()` để so sánh key. Khi collision xảy ra, nhiều phần tử vào cùng bucket và Java xử lý bằng linked list hoặc tree tùy số lượng phần tử.

3. `ArrayList` truy cập phần tử theo index nhanh, nhưng thêm/xóa ở giữa chậm. `LinkedList` thêm/xóa ở đầu hoặc giữa tốt hơn, nhưng truy cập theo index chậm. Chọn `ArrayList` khi đọc nhiều, `LinkedList` khi chèn/xóa nhiều.

4. `Encapsulation` là đóng gói dữ liệu qua `private` và method `getter/setter`. `Inheritance` là lớp con kế thừa lớp cha. `Polymorphism` là cùng một method nhưng hành vi khác nhau khi override. `Abstraction` là ẩn chi tiết triển khai, thường qua abstract class hoặc interface.

5. `Checked exception` bắt buộc phải xử lý hoặc khai báo `throws`, ví dụ `IOException`. `Unchecked exception` là lỗi runtime như `NullPointerException`. Tạo custom exception khi muốn biểu diễn lỗi nghiệp vụ rõ ràng và dễ quản lý hơn.

6. `String` immutable nên an toàn, dễ dùng trong pool và thread-safe. `StringBuilder` mutable, nhanh hơn khi nối chuỗi trong môi trường đơn luồng. `StringBuffer` giống `StringBuilder` nhưng có đồng bộ hóa nên chậm hơn và dùng cho đa luồng.

7. Vòng đời thread thường gồm: `new`, `runnable`, `running`, `blocked/waiting`, và `terminated`. `synchronized` dùng để đồng bộ truy cập tài nguyên chia sẻ, tránh race condition trong môi trường đa luồng.

8. `final` dùng cho biến, method, class để không thay đổi, không override, hoặc không kế thừa. `finally` là khối luôn chạy sau `try-catch` để dọn tài nguyên. `finalize` là method GC từng dùng trước đây để dọn dẹp nhưng hiện không nên dùng nữa.

9. Java 8 nổi bật với `Lambda Expression`, `Stream API`, `Optional`, method reference, và cải tiến Date Time API. `Lambda` giúp code ngắn hơn, còn `Stream API` hỗ trợ xử lý collection theo kiểu khai báo, dễ đọc và dễ tận dụng song song hóa.

10. Có thể tối ưu bằng cách phân trang dữ liệu, dùng index phù hợp trong database, cache dữ liệu hay truy cập, tránh query lặp kiểu N+1, batch insert/update, và profile ứng dụng để tìm đúng điểm nghẽn trước khi tối ưu.
