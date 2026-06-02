# State Pattern

## 1. Định nghĩa

`State` là pattern cho phép object thay đổi hành vi của nó khi trạng thái nội bộ thay đổi.

## 2. Cách dùng

1. Tạo interface state chung.
2. Mỗi trạng thái cụ thể có hành vi riêng.
3. Context giữ state hiện tại và ủy quyền xử lý cho state đó.

## 3. Khi nào dùng

Nên dùng khi:

1. Object có nhiều trạng thái
2. Logic if-else theo state quá dài
3. Muốn tách hành vi theo từng trạng thái

## 4. Bài toán ví dụ

Máy nghe nhạc có trạng thái `Playing` và `Paused`.

## 5. Code Java mẫu

```java
interface PlayerState {
    void pressPlay(MusicPlayer player);
}

class PlayingState implements PlayerState {
    @Override
    public void pressPlay(MusicPlayer player) {
        System.out.println("Pause music");
        player.setState(new PausedState());
    }
}

class PausedState implements PlayerState {
    @Override
    public void pressPlay(MusicPlayer player) {
        System.out.println("Play music");
        player.setState(new PlayingState());
    }
}

class MusicPlayer {
    private PlayerState state = new PausedState();

    public void setState(PlayerState state) {
        this.state = state;
    }

    public void pressPlay() {
        // Hành vi phụ thuộc hoàn toàn vào state hiện tại
        state.pressPlay(this);
    }
}

public class StateDemo {
    public static void main(String[] args) {
        MusicPlayer player = new MusicPlayer();
        player.pressPlay();
        player.pressPlay();
    }
}
```

## 6. Giải thích code

1. `MusicPlayer` là context.
2. `PlayingState` và `PausedState` là các state cụ thể.
3. Mỗi lần bấm play, state hiện tại quyết định hành vi tiếp theo.

## 7. Ưu điểm

1. Tránh if-else lớn theo trạng thái
2. Dễ thêm trạng thái mới

## 8. Nhược điểm

1. Tăng số lượng class
