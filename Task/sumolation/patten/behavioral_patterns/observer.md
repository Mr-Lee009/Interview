# Observer Pattern

## 1. Định nghĩa

`Observer` là pattern định nghĩa quan hệ một-nhiều, khi object nguồn thay đổi thì tất cả observer đăng ký sẽ được thông báo tự động.

## 2. Cách dùng

1. Subject lưu danh sách observer.
2. Observer đăng ký hoặc hủy đăng ký.
3. Khi state thay đổi, subject gọi notify.

## 3. Khi nào dùng

Nên dùng khi:

1. Cần cơ chế event hoặc publish-subscribe đơn giản
2. Nhiều thành phần cần phản ứng theo state của một nguồn

## 4. Bài toán ví dụ

Kênh YouTube đăng video mới và gửi thông báo cho subscriber.

## 5. Code Java mẫu

```java
import java.util.ArrayList;
import java.util.List;

interface Subscriber {
    void update(String videoTitle);
}

class UserSubscriber implements Subscriber {
    private final String name;

    public UserSubscriber(String name) {
        this.name = name;
    }

    @Override
    public void update(String videoTitle) {
        System.out.println(name + " received notification: " + videoTitle);
    }
}

class YouTubeChannel {
    private final List<Subscriber> subscribers = new ArrayList<>();

    public void subscribe(Subscriber subscriber) {
        subscribers.add(subscriber);
    }

    public void uploadVideo(String title) {
        System.out.println("New video uploaded: " + title);

        // Notify toàn bộ observer đã đăng ký
        for (Subscriber subscriber : subscribers) {
            subscriber.update(title);
        }
    }
}

public class ObserverDemo {
    public static void main(String[] args) {
        YouTubeChannel channel = new YouTubeChannel();
        channel.subscribe(new UserSubscriber("An"));
        channel.subscribe(new UserSubscriber("Binh"));

        channel.uploadVideo("Design Patterns in Java");
    }
}
```

## 6. Giải thích code

1. `YouTubeChannel` là subject.
2. `UserSubscriber` là observer.
3. Khi upload video, subject notify tất cả observer.

## 7. Ưu điểm

1. Tự động đồng bộ trạng thái
2. Hỗ trợ event-driven design

## 8. Nhược điểm

1. Có thể khó theo dõi luồng notify nếu hệ thống lớn
