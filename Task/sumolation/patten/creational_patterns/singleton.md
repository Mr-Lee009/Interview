# Singleton Pattern

## 1. Định nghĩa

`Singleton` là pattern đảm bảo một class chỉ có đúng một instance trong toàn bộ vòng đời ứng dụng, đồng thời cung cấp một điểm truy cập chung tới instance đó.

## 2. Cách dùng

Ta thường dùng `Singleton` bằng cách:

1. Đặt constructor là `private`
2. Giữ một biến `static` chứa instance duy nhất
3. Cung cấp method `getInstance()` để lấy instance

## 3. Khi nào dùng

Nên dùng khi:

1. Cần một đối tượng dùng chung trong toàn hệ thống
2. Muốn kiểm soát chặt việc khởi tạo object
3. Đối tượng đại diện cho tài nguyên toàn cục như:
   - `Config`
   - `Logger`
   - `Cache`
   - `Connection manager`

Không nên lạm dụng khi:

1. Object có state thay đổi liên tục theo request
2. Cần test isolation mạnh
3. Có thể thay bằng dependency injection rõ ràng hơn

## 4. Bài toán ví dụ

Ứng dụng cần một `AppConfig` duy nhất để đọc cấu hình như tên ứng dụng và version.

## 5. Code Java mẫu

```java
final class AppConfig {
    // volatile giúp các thread nhìn thấy giá trị mới nhất của instance
    private static volatile AppConfig instance;

    private final String appName;
    private final String version;

    // private constructor để chặn new từ bên ngoài
    private AppConfig() {
        this.appName = "Interview System";
        this.version = "1.0.0";
    }

    public static AppConfig getInstance() {
        // Kiểm tra lần 1 để tránh synchronized không cần thiết
        if (instance == null) {
            synchronized (AppConfig.class) {
                // Kiểm tra lần 2 để đảm bảo chỉ tạo đúng 1 lần
                if (instance == null) {
                    instance = new AppConfig();
                }
            }
        }
        return instance;
    }

    public String getAppName() {
        return appName;
    }

    public String getVersion() {
        return version;
    }
}

public class SingletonDemo {
    public static void main(String[] args) {
        // Lấy instance từ điểm truy cập chung
        AppConfig config1 = AppConfig.getInstance();
        AppConfig config2 = AppConfig.getInstance();

        System.out.println("App name: " + config1.getAppName());
        System.out.println("Version: " + config1.getVersion());

        // true vì cả hai biến cùng trỏ đến một object duy nhất
        System.out.println(config1 == config2);
    }
}
```

## 6. Giải thích code

1. `private AppConfig()` ngăn code bên ngoài gọi `new AppConfig()`.
2. `instance` là nơi lưu object duy nhất.
3. `getInstance()` là nơi duy nhất tạo hoặc trả về object đó.
4. `synchronized` + `double-check locking` giúp an toàn hơn trong môi trường đa luồng.

## 7. Ưu điểm

1. Kiểm soát số lượng instance
2. Tiết kiệm tài nguyên nếu object đắt đỏ khi khởi tạo
3. Dễ truy cập ở nhiều nơi

## 8. Nhược điểm

1. Dễ biến thành biến toàn cục đội lốt object
2. Tăng coupling nếu bị lạm dụng
3. Có thể làm unit test khó hơn
