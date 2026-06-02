# Proxy Pattern

## 1. Định nghĩa

`Proxy` là pattern tạo một object đại diện đứng trước object thật để kiểm soát việc truy cập tới object đó.

## 2. Cách dùng

Ta thường dùng `Proxy` để:

1. Kiểm tra quyền truy cập
2. Trì hoãn khởi tạo object nặng
3. Ghi log
4. Cache kết quả
5. Gọi object ở xa như remote service

## 3. Khi nào dùng

Nên dùng khi:

1. Cần kiểm soát truy cập trước khi gọi object thật
2. Object thật khởi tạo tốn tài nguyên
3. Muốn thêm logic phụ mà vẫn giữ cùng interface

## 4. Bài toán ví dụ

Hệ thống xem video cần kiểm tra quyền người dùng trước khi truy cập video thật.

## 5. Code Java mẫu

```java
interface VideoService {
    void play(String userRole);
}

class RealVideoService implements VideoService {
    @Override
    public void play(String userRole) {
        System.out.println("Playing premium video for role: " + userRole);
    }
}

class VideoServiceProxy implements VideoService {
    private final RealVideoService realVideoService = new RealVideoService();

    @Override
    public void play(String userRole) {
        // Proxy chặn trước để kiểm tra quyền
        if (!"PREMIUM".equals(userRole)) {
            System.out.println("Access denied");
            return;
        }

        // Nếu hợp lệ mới chuyển tiếp sang object thật
        realVideoService.play(userRole);
    }
}

public class ProxyDemo {
    public static void main(String[] args) {
        VideoService videoService = new VideoServiceProxy();

        videoService.play("FREE");
        videoService.play("PREMIUM");
    }
}
```

## 6. Giải thích code

1. `VideoService` là interface chung.
2. `RealVideoService` xử lý logic thật.
3. `VideoServiceProxy` đứng trước object thật.
4. Proxy có thể kiểm tra điều kiện trước rồi mới forward request.

## 7. Ưu điểm

1. Kiểm soát truy cập tốt
2. Có thể thêm cache, log, lazy load
3. Giữ nguyên interface cho phía client

## 8. Nhược điểm

1. Tăng thêm lớp trung gian
2. Có thể làm flow gọi khó theo dõi hơn nếu proxy quá nhiều trách nhiệm
