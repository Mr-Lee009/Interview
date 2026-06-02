# Bridge Pattern

## 1. Định nghĩa

`Bridge` là pattern tách phần `abstraction` khỏi phần `implementation` để hai phần này có thể thay đổi độc lập.

## 2. Cách dùng

Ta thường dùng khi:

1. Một abstraction có nhiều biến thể
2. Phần implementation cũng có nhiều biến thể
3. Không muốn số lượng class tăng theo kiểu nhân chéo

## 3. Khi nào dùng

Nên dùng khi:

1. Có nhiều chiều thay đổi độc lập
2. Muốn tránh tạo quá nhiều subclass
3. Muốn thay implementation tại runtime

## 4. Bài toán ví dụ

Ứng dụng có nhiều loại `RemoteControl` và nhiều loại `Device` như `TV`, `Radio`.

## 5. Code Java mẫu

```java
interface Device {
    void turnOn();
    void turnOff();
    void setVolume(int volume);
}

class Tv implements Device {
    @Override
    public void turnOn() {
        System.out.println("TV is on");
    }

    @Override
    public void turnOff() {
        System.out.println("TV is off");
    }

    @Override
    public void setVolume(int volume) {
        System.out.println("TV volume: " + volume);
    }
}

class Radio implements Device {
    @Override
    public void turnOn() {
        System.out.println("Radio is on");
    }

    @Override
    public void turnOff() {
        System.out.println("Radio is off");
    }

    @Override
    public void setVolume(int volume) {
        System.out.println("Radio volume: " + volume);
    }
}

class RemoteControl {
    protected final Device device;

    public RemoteControl(Device device) {
        this.device = device;
    }

    public void togglePower(boolean on) {
        if (on) {
            device.turnOn();
        } else {
            device.turnOff();
        }
    }
}

class AdvancedRemoteControl extends RemoteControl {
    public AdvancedRemoteControl(Device device) {
        super(device);
    }

    public void setVolume(int volume) {
        device.setVolume(volume);
    }
}

public class BridgeDemo {
    public static void main(String[] args) {
        Device tv = new Tv();
        AdvancedRemoteControl remote = new AdvancedRemoteControl(tv);

        remote.togglePower(true);
        remote.setVolume(20);
    }
}
```

## 6. Giải thích code

1. `Device` là phần implementation.
2. `Tv` và `Radio` là các implementation cụ thể.
3. `RemoteControl` là abstraction.
4. `AdvancedRemoteControl` mở rộng abstraction mà không ảnh hưởng tới implementation.
5. Hai chiều thay đổi độc lập: thêm device mới hoặc thêm remote mới.

## 7. Ưu điểm

1. Tránh bùng nổ số lượng subclass
2. Dễ mở rộng theo nhiều chiều
3. Giảm coupling giữa abstraction và implementation

## 8. Nhược điểm

1. Khó hiểu hơn với bài toán nhỏ
2. Tăng số lượng lớp và interface
