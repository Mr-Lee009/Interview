# Factory Method Pattern

## 1. Định nghĩa

`Factory Method` là pattern định nghĩa một method dùng để tạo object, nhưng việc tạo ra class cụ thể nào sẽ do lớp con hoặc factory cụ thể quyết định.

## 2. Cách dùng

Ta thường dùng pattern này khi:

1. Khai báo một interface hoặc abstract class cho product
2. Tạo các class triển khai product
3. Tạo một creator abstract chứa `factory method`
4. Để các creator cụ thể override method đó

## 3. Khi nào dùng

Nên dùng khi:

1. Client không nên phụ thuộc trực tiếp vào class cụ thể
2. Cần chọn loại object theo cấu hình hoặc runtime
3. Muốn mở rộng thêm loại object mà không sửa logic client

## 4. Bài toán ví dụ

Hệ thống gửi thông báo có thể chọn `Email` hoặc `SMS`.

## 5. Code Java mẫu

```java
interface Notification {
    void send(String message);
}

class EmailNotification implements Notification {
    @Override
    public void send(String message) {
        System.out.println("Send email: " + message);
    }
}

class SmsNotification implements Notification {
    @Override
    public void send(String message) {
        System.out.println("Send SMS: " + message);
    }
}

abstract class NotificationCreator {
    // Factory method: lớp con sẽ quyết định tạo object cụ thể nào
    public abstract Notification createNotification();

    public void notifyUser(String message) {
        // Client chỉ làm việc với abstraction
        Notification notification = createNotification();
        notification.send(message);
    }
}

class EmailNotificationCreator extends NotificationCreator {
    @Override
    public Notification createNotification() {
        // Chọn loại object email
        return new EmailNotification();
    }
}

class SmsNotificationCreator extends NotificationCreator {
    @Override
    public Notification createNotification() {
        // Chọn loại object sms
        return new SmsNotification();
    }
}

public class FactoryMethodDemo {
    public static void main(String[] args) {
        NotificationCreator creator = new EmailNotificationCreator();
        creator.notifyUser("Welcome to the system");

        creator = new SmsNotificationCreator();
        creator.notifyUser("OTP: 123456");
    }
}
```

## 6. Giải thích code

1. `Notification` là product chung.
2. `EmailNotification` và `SmsNotification` là product cụ thể.
3. `NotificationCreator` khai báo `createNotification()`.
4. Mỗi creator con tự quyết định object nào sẽ được tạo.
5. Client không cần gọi trực tiếp `new EmailNotification()` hay `new SmsNotification()`.

## 7. Ưu điểm

1. Giảm phụ thuộc vào class cụ thể
2. Dễ mở rộng thêm product mới
3. Tách logic tạo object khỏi logic sử dụng object

## 8. Nhược điểm

1. Số lượng class tăng lên
2. Có thể hơi nặng với bài toán quá đơn giản
