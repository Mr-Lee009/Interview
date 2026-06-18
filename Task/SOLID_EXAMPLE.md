Dưới đây là các ví dụ thực tế bằng Java cho từng nguyên lý SOLID. Mỗi nguyên lý tôi sẽ đưa ra 2 đoạn code: **Cách viết sai (Vi phạm)** và **Cách viết đúng (Khắc phục)** để bạn dễ dàng so sánh.

### 1. S - Single Responsibility Principle (Đơn trách nhiệm)

**❌ Cách viết sai:** Class `User` đang ôm đồm quá nhiều việc (vừa chứa dữ liệu, vừa kết nối Database, vừa xử lý logic in ấn).

```java
public class User {
    private String name;
    private String email;

    // Trách nhiệm 1: Quản lý thông tin User
    public String getName() { return name; }
    
    // Trách nhiệm 2: Tương tác với Database
    public void saveToDatabase() {
        System.out.println("Lưu " + name + " vào DB");
    }

    // Trách nhiệm 3: Xử lý hiển thị
    public void printReport() {
        System.out.println("Báo cáo của user: " + name);
    }
}

```

**✅ Cách viết đúng:** Tách ra làm 3 class riêng biệt, mỗi class chỉ làm đúng 1 việc.

```java
// Chỉ chứa dữ liệu
public class User {
    private String name;
    private String email;
}

// Chỉ lo việc tương tác với Database
public class UserRepository {
    public void save(User user) {
        System.out.println("Lưu user vào DB");
    }
}

// Chỉ lo việc hiển thị/in ấn
public class UserReport {
    public void print(User user) {
        System.out.println("In báo cáo user");
    }
}

```

---

### 2. O - Open/Closed Principle (Đóng/Mở)

**❌ Cách viết sai:** Khi muốn thêm phương thức thanh toán Momo, bạn phải chui vào class `PaymentProcessor` để sửa code và thêm nhánh `else if`. Điều này rất dễ gây lỗi cho các code cũ đang chạy ổn định.

```java
public class PaymentProcessor {
    public void process(String paymentType, double amount) {
        if (paymentType.equals("CREDIT_CARD")) {
            System.out.println("Thanh toán bằng thẻ: " + amount);
        } else if (paymentType.equals("PAYPAL")) {
            System.out.println("Thanh toán bằng PayPal: " + amount);
        }
        // NẾU THÊM MOMO, LẠI PHẢI SỬA CLASS NÀY!
    }
}

```

**✅ Cách viết đúng:** Dùng Interface. Muốn thêm phương thức mới (Momo), chỉ cần tạo class mới implement interface đó, class xử lý chính không cần sửa một dòng nào.

```java
public interface PaymentMethod {
    void pay(double amount);
}

public class CreditCardPayment implements PaymentMethod {
    public void pay(double amount) { System.out.println("Quẹt thẻ: " + amount); }
}

public class MomoPayment implements PaymentMethod {
    public void pay(double amount) { System.out.println("Quét mã Momo: " + amount); }
}

// Class này giờ đã "Đóng" với việc sửa đổi, nhưng "Mở" để mở rộng
public class PaymentProcessor {
    public void process(PaymentMethod method, double amount) {
        method.pay(amount);
    }
}

```

---

### 3. L - Liskov Substitution Principle (Thay thế Liskov)

**❌ Cách viết sai:** Cánh cụt kế thừa từ Chim, nhưng gọi hàm `bay()` lại văng ra lỗi. Nếu một hàm nào đó nhận tham số là `Bird` và gọi lệnh bay, chương trình sẽ sập khi truyền vào `Penguin`.

```java
public class Bird {
    public void fly() {
        System.out.println("Đang bay...");
    }
}

public class Penguin extends Bird {
    @Override
    public void fly() {
        throw new RuntimeException("Cánh cụt không biết bay!");
    }
}

```

**✅ Cách viết đúng:** Phân loại lại cấu trúc kế thừa. Hàm `fly()` chỉ nên dành cho những loài chim biết bay.

```java
public class Bird {
    // Chứa các đặc điểm chung của loài chim (ví dụ: đẻ trứng, có lông vũ)
}

public class FlyingBird extends Bird {
    public void fly() {
        System.out.println("Đang bay...");
    }
}

public class Sparrow extends FlyingBird {
    // Chim sẻ dùng được hàm fly() bình thường
}

public class Penguin extends Bird {
    // Chim cánh cụt chỉ kế thừa Bird, không có hàm fly(), tránh được lỗi logic
    public void swim() {
        System.out.println("Đang bơi...");
    }
}

```

---

### 4. I - Interface Segregation Principle (Phân tách Interface)

**❌ Cách viết sai:** Bắt Robot phải làm những việc của con người (ăn uống).

```java
public interface Worker {
    void work();
    void eat();
}

public class HumanWorker implements Worker {
    public void work() { System.out.println("Người đang làm việc"); }
    public void eat() { System.out.println("Người đang ăn trưa"); }
}

public class RobotWorker implements Worker {
    public void work() { System.out.println("Robot đang làm việc"); }
    public void eat() {
        // Vô lý! Robot không biết ăn, nhưng vẫn bị ép phải implement hàm này
        throw new UnsupportedOperationException();
    }
}

```

**✅ Cách viết đúng:** Chia nhỏ Interface ra theo từng tính năng chuyên biệt.

```java
public interface Workable {
    void work();
}

public interface Eatable {
    void eat();
}

public class HumanWorker implements Workable, Eatable {
    public void work() { System.out.println("Người đang làm việc"); }
    public void eat() { System.out.println("Người đang ăn"); }
}

public class RobotWorker implements Workable {
    public void work() { System.out.println("Robot đang làm việc"); }
    // Robot không cần implement Eatable, code gọn gàng, hợp logic.
}

```

---

### 5. D - Dependency Inversion Principle (Đảo ngược Dependency)

**❌ Cách viết sai:** `OrderService` (Module cấp cao) phụ thuộc trực tiếp vào `GmailSender` (Module cấp thấp). Nếu ngày mai sếp yêu cầu đổi sang gửi SMS, bạn phải đập bỏ class `OrderService` đi viết lại.

```java
public class GmailSender {
    public void sendEmail(String msg) {
        System.out.println("Gửi email qua Gmail: " + msg);
    }
}

public class OrderService {
    // Kết dính quá chặt (tight coupling)
    private GmailSender sender = new GmailSender();

    public void checkout() {
        // Logic thanh toán...
        sender.sendEmail("Đơn hàng thành công");
    }
}

```

**✅ Cách viết đúng:** Cả 2 cùng phụ thuộc vào một Interface `MessageSender`. (Đây chính là nền tảng của Dependency Injection trong Spring Boot mà chúng ta cấu hình qua các file).

```java
// Trừu tượng hóa (Interface)
public interface MessageSender {
    void send(String msg);
}

// Module cấp thấp
public class GmailSender implements MessageSender {
    public void send(String msg) { System.out.println("Gửi qua Gmail: " + msg); }
}

public class SmsSender implements MessageSender {
    public void send(String msg) { System.out.println("Gửi qua SMS: " + msg); }
}

// Module cấp cao chỉ làm việc với Interface
public class OrderService {
    private MessageSender sender;

    // Tiêm phụ thuộc qua Constructor (Spring Boot thường làm việc này tự động)
    public OrderService(MessageSender sender) {
        this.sender = sender;
    }

    public void checkout() {
        // Logic thanh toán...
        sender.send("Đơn hàng thành công");
    }
}

```