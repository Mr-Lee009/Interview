# Adapter Pattern

## 1. Định nghĩa

`Adapter` là pattern dùng để chuyển đổi interface của một class hiện có thành interface mà client đang mong muốn.

## 2. Cách dùng

Ta thường dùng `Adapter` khi:

1. Có một class cũ hoặc thư viện ngoài không đúng interface cần dùng
2. Không muốn sửa trực tiếp class gốc
3. Cần một lớp trung gian để map lời gọi giữa 2 interface

## 3. Khi nào dùng

Nên dùng khi:

1. Tích hợp hệ thống cũ vào hệ thống mới
2. Dùng thư viện bên thứ ba có API không khớp
3. Muốn tái sử dụng class có sẵn nhưng interface không tương thích

## 4. Bài toán ví dụ

Hệ thống hiện tại chỉ làm việc với `PaymentProcessor`, nhưng cổng thanh toán cũ lại cung cấp class `LegacyPayGateway`.

## 5. Code Java mẫu

```java
interface PaymentProcessor {
    void pay(double amount);
}

class LegacyPayGateway {
    // API cũ dùng tên method khác và định dạng dữ liệu khác
    public void makePayment(String value) {
        System.out.println("Legacy gateway paid: " + value);
    }
}

class LegacyPayAdapter implements PaymentProcessor {
    private final LegacyPayGateway legacyPayGateway;

    public LegacyPayAdapter(LegacyPayGateway legacyPayGateway) {
        this.legacyPayGateway = legacyPayGateway;
    }

    @Override
    public void pay(double amount) {
        // Adapter chuyển lời gọi mới sang API cũ
        legacyPayGateway.makePayment(String.format("%.2f", amount));
    }
}

public class AdapterDemo {
    public static void main(String[] args) {
        PaymentProcessor processor = new LegacyPayAdapter(new LegacyPayGateway());
        processor.pay(150.75);
    }
}
```

## 6. Giải thích code

1. `PaymentProcessor` là interface hệ thống mới cần.
2. `LegacyPayGateway` là class cũ không tương thích.
3. `LegacyPayAdapter` đóng vai trò cầu nối giữa hai bên.
4. Client chỉ dùng `PaymentProcessor`, không cần biết gateway cũ hoạt động ra sao.

## 7. Ưu điểm

1. Tái sử dụng được code cũ
2. Không phải sửa logic client
3. Tách biệt phần tích hợp khỏi business logic

## 8. Nhược điểm

1. Tăng thêm một lớp trung gian
2. Nếu map dữ liệu phức tạp thì adapter cũng phức tạp theo
