# Danh sách Design Pattern theo từng loại

Design Pattern thường được chia thành 3 nhóm chính theo chuẩn `GoF` (`Gang of Four`):

- `Creational Patterns`: nhóm khởi tạo đối tượng
- `Structural Patterns`: nhóm tổ chức cấu trúc lớp và object
- `Behavioral Patterns`: nhóm hành vi và cách các object giao tiếp với nhau

## 1. Creational Patterns

Nhóm này tập trung vào cách tạo object sao cho linh hoạt, tái sử dụng tốt và giảm phụ thuộc vào cách khởi tạo cụ thể.

1. `Singleton`
2. `Factory Method`
3. `Abstract Factory`
4. `Builder`
5. `Prototype`

### Mô tả ngắn

1. `Singleton`: đảm bảo chỉ có một instance duy nhất của một lớp.
2. `Factory Method`: tạo object thông qua method thay vì khởi tạo trực tiếp.
3. `Abstract Factory`: tạo ra họ các object liên quan với nhau.
4. `Builder`: tách quá trình xây dựng object phức tạp ra khỏi biểu diễn cuối cùng.
5. `Prototype`: tạo object mới bằng cách clone từ object mẫu.

## 2. Structural Patterns

Nhóm này tập trung vào cách ghép các class hoặc object lại với nhau để tạo thành cấu trúc lớn hơn nhưng vẫn dễ mở rộng.

1. `Adapter`
2. `Bridge`
3. `Composite`
4. `Decorator`
5. `Facade`
6. `Flyweight`
7. `Proxy`

### Mô tả ngắn

1. `Adapter`: chuyển đổi interface này sang interface khác để tương thích.
2. `Bridge`: tách abstraction khỏi implementation để có thể thay đổi độc lập.
3. `Composite`: biểu diễn cấu trúc cây giữa object đơn và object nhóm.
4. `Decorator`: thêm chức năng cho object một cách linh hoạt mà không sửa class gốc.
5. `Facade`: cung cấp một interface đơn giản cho hệ thống phức tạp.
6. `Flyweight`: chia sẻ object để giảm dùng bộ nhớ.
7. `Proxy`: tạo object đại diện để kiểm soát truy cập tới object thật.

## 3. Behavioral Patterns

Nhóm này mô tả cách object tương tác, trao đổi trách nhiệm và xử lý hành vi trong hệ thống.

1. `Chain of Responsibility`
2. `Command`
3. `Interpreter`
4. `Iterator`
5. `Mediator`
6. `Memento`
7. `Observer`
8. `State`
9. `Strategy`
10. `Template Method`
11. `Visitor`

### Mô tả ngắn

1. `Chain of Responsibility`: chuyển request qua chuỗi handler cho đến khi có nơi xử lý.
2. `Command`: đóng gói request thành object.
3. `Interpreter`: định nghĩa cách diễn giải một ngôn ngữ hoặc biểu thức.
4. `Iterator`: duyệt tuần tự các phần tử mà không lộ cấu trúc bên trong.
5. `Mediator`: gom logic giao tiếp giữa các object về một nơi trung gian.
6. `Memento`: lưu và khôi phục trạng thái object.
7. `Observer`: một object thay đổi thì các object phụ thuộc được thông báo.
8. `State`: thay đổi hành vi khi trạng thái bên trong thay đổi.
9. `Strategy`: đóng gói các thuật toán khác nhau và thay thế linh hoạt.
10. `Template Method`: định nghĩa skeleton của thuật toán, để subclass cài đặt một số bước.
11. `Visitor`: thêm hành vi mới lên cấu trúc object mà không sửa class của phần tử.

## 4. Tổng hợp nhanh

### 4.1 Số lượng theo nhóm

1. `Creational`: 5 pattern
2. `Structural`: 7 pattern
3. `Behavioral`: 11 pattern

Tổng cộng: `23 design patterns` kinh điển theo `GoF`.

## 5. Cách nhớ nhanh khi đi phỏng vấn

1. Nếu câu hỏi liên quan đến `tạo object`, nghĩ đến `Creational`.
2. Nếu câu hỏi liên quan đến `ghép class`, `bọc object`, `đơn giản hóa hệ thống`, nghĩ đến `Structural`.
3. Nếu câu hỏi liên quan đến `luồng xử lý`, `giao tiếp`, `thay đổi hành vi`, nghĩ đến `Behavioral`.
