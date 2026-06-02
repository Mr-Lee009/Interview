# Mediator Pattern

## 1. Định nghĩa

`Mediator` là pattern gom logic giao tiếp giữa nhiều object vào một object trung gian, tránh để các object gọi trực tiếp lẫn nhau.

## 2. Cách dùng

1. Tạo mediator interface hoặc class trung gian.
2. Các colleague gửi sự kiện cho mediator.
3. Mediator quyết định ai cần phản ứng.

## 3. Khi nào dùng

Nên dùng khi:

1. Nhiều object phụ thuộc chéo nhau
2. Muốn giảm coupling giữa các object
3. Muốn tập trung điều phối giao tiếp

## 4. Bài toán ví dụ

Phòng chat, nơi user gửi tin nhắn qua `ChatRoom`.

## 5. Code Java mẫu

```java
class ChatRoom {
    public void showMessage(String user, String message) {
        // Mediator chịu trách nhiệm điều phối và hiển thị
        System.out.println(user + ": " + message);
    }
}

class User {
    private final String name;
    private final ChatRoom chatRoom;

    public User(String name, ChatRoom chatRoom) {
        this.name = name;
        this.chatRoom = chatRoom;
    }

    public void send(String message) {
        // User không gửi trực tiếp cho user khác
        chatRoom.showMessage(name, message);
    }
}

public class MediatorDemo {
    public static void main(String[] args) {
        ChatRoom chatRoom = new ChatRoom();

        User user1 = new User("An", chatRoom);
        User user2 = new User("Binh", chatRoom);

        user1.send("Hello");
        user2.send("Hi");
    }
}
```

## 6. Giải thích code

1. `ChatRoom` là mediator.
2. `User` chỉ biết nói chuyện với mediator.
3. Các user không phụ thuộc trực tiếp vào nhau.

## 7. Ưu điểm

1. Giảm phụ thuộc chéo
2. Dễ quản lý giao tiếp

## 8. Nhược điểm

1. Mediator có thể trở nên quá lớn
