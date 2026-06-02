# Builder Pattern

## 1. Định nghĩa

`Builder` là pattern tách quá trình xây dựng object phức tạp ra khỏi object cuối cùng, giúp việc khởi tạo trở nên rõ ràng, dễ đọc và linh hoạt hơn.

## 2. Cách dùng

Ta thường dùng `Builder` khi:

1. Object có nhiều field
2. Có cả field bắt buộc và field tùy chọn
3. Không muốn constructor quá dài hoặc khó đọc

Thông thường:

1. Class chính có constructor `private`
2. Tạo inner class `Builder`
3. `Builder` trả về `this` để hỗ trợ method chaining
4. Gọi `build()` để tạo object cuối cùng

## 3. Khi nào dùng

Nên dùng khi:

1. Object có nhiều tham số
2. Nhiều tham số là optional
3. Muốn code tạo object tự mô tả tốt hơn
4. Muốn tạo object immutable

## 4. Bài toán ví dụ

Tạo đối tượng `Computer` với nhiều cấu hình:

1. `cpu`
2. `ram`
3. `ssd`
4. `wifi`
5. `bluetooth`

## 5. Code Java mẫu

```java
class Computer {
    private final String cpu;
    private final int ram;
    private final int ssd;
    private final boolean wifi;
    private final boolean bluetooth;

    // Constructor private: object chỉ được tạo qua Builder
    private Computer(Builder builder) {
        this.cpu = builder.cpu;
        this.ram = builder.ram;
        this.ssd = builder.ssd;
        this.wifi = builder.wifi;
        this.bluetooth = builder.bluetooth;
    }

    public void printConfig() {
        System.out.println("CPU: " + cpu);
        System.out.println("RAM: " + ram + "GB");
        System.out.println("SSD: " + ssd + "GB");
        System.out.println("Wifi: " + wifi);
        System.out.println("Bluetooth: " + bluetooth);
    }

    public static class Builder {
        // Field bắt buộc
        private final String cpu;
        private final int ram;

        // Field optional có giá trị mặc định
        private int ssd = 256;
        private boolean wifi = true;
        private boolean bluetooth = false;

        public Builder(String cpu, int ram) {
            this.cpu = cpu;
            this.ram = ram;
        }

        public Builder ssd(int ssd) {
            this.ssd = ssd;
            return this; // trả về chính builder để chain method
        }

        public Builder wifi(boolean wifi) {
            this.wifi = wifi;
            return this;
        }

        public Builder bluetooth(boolean bluetooth) {
            this.bluetooth = bluetooth;
            return this;
        }

        public Computer build() {
            // Có thể validate dữ liệu tại đây trước khi tạo object
            return new Computer(this);
        }
    }
}

public class BuilderDemo {
    public static void main(String[] args) {
        Computer computer = new Computer.Builder("Intel i7", 16)
                .ssd(512)
                .wifi(true)
                .bluetooth(true)
                .build();

        computer.printConfig();
    }
}
```

## 6. Giải thích code

1. `Computer` không cho tạo trực tiếp từ ngoài.
2. `Builder` gom toàn bộ bước cấu hình object.
3. Các field bắt buộc được truyền từ đầu.
4. Các field tùy chọn được set dần qua method chaining.
5. `build()` mới là bước tạo object cuối cùng.

## 7. Ưu điểm

1. Code khởi tạo rõ ràng, dễ đọc
2. Tránh constructor nhiều tham số
3. Hỗ trợ object immutable tốt
4. Dễ thêm validate trước khi build

## 8. Nhược điểm

1. Tăng thêm code builder
2. Với object quá đơn giản thì có thể hơi dư thừa
