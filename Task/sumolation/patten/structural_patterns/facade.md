# Facade Pattern

## 1. Định nghĩa

`Facade` là pattern cung cấp một interface đơn giản, thống nhất để làm việc với một hệ thống phức tạp gồm nhiều class con.

## 2. Cách dùng

Ta thường dùng khi:

1. Hệ thống con có nhiều bước xử lý
2. Client không nên biết quá nhiều chi tiết nội bộ
3. Muốn gom một quy trình phức tạp vào một API đơn giản

## 3. Khi nào dùng

Nên dùng khi:

1. Có nhiều service phối hợp với nhau
2. Muốn giảm độ phức tạp cho phía gọi
3. Muốn tạo entry point rõ ràng cho subsystem

## 4. Bài toán ví dụ

Quy trình khởi động máy tính cần:

1. Bật CPU
2. Nạp bộ nhớ
3. Đọc dữ liệu từ ổ cứng

## 5. Code Java mẫu

```java
class Cpu {
    public void start() {
        System.out.println("CPU started");
    }
}

class Memory {
    public void load() {
        System.out.println("Memory loaded");
    }
}

class HardDrive {
    public void read() {
        System.out.println("Hard drive read boot data");
    }
}

class ComputerFacade {
    private final Cpu cpu = new Cpu();
    private final Memory memory = new Memory();
    private final HardDrive hardDrive = new HardDrive();

    public void startComputer() {
        // Facade gom toàn bộ quy trình vào một method dễ dùng
        cpu.start();
        memory.load();
        hardDrive.read();
        System.out.println("Computer started successfully");
    }
}

public class FacadeDemo {
    public static void main(String[] args) {
        ComputerFacade computer = new ComputerFacade();
        computer.startComputer();
    }
}
```

## 6. Giải thích code

1. `Cpu`, `Memory`, `HardDrive` là subsystem.
2. `ComputerFacade` che giấu chi tiết phối hợp giữa các subsystem.
3. Client chỉ cần gọi `startComputer()`.

## 7. Ưu điểm

1. Đơn giản hóa cách dùng hệ thống phức tạp
2. Giảm coupling giữa client và subsystem
3. Dễ chuẩn hóa quy trình gọi

## 8. Nhược điểm

1. Facade có thể trở thành god object nếu ôm quá nhiều việc
2. Có thể che mất khả năng truy cập chi tiết nếu thiết kế quá cứng
