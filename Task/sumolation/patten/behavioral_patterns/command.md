# Command Pattern

## 1. Định nghĩa

`Command` là pattern đóng gói một request hoặc thao tác thành object, từ đó có thể truyền, lưu, xếp hàng hoặc undo.

## 2. Cách dùng

1. Tạo interface `Command`.
2. Mỗi command cụ thể gọi tới receiver tương ứng.
3. Invoker chỉ biết gọi `execute()`.

## 3. Khi nào dùng

Nên dùng khi:

1. Muốn tách người gọi khỏi người thực thi
2. Cần queue job, log thao tác, undo/redo
3. Muốn biểu diễn hành động như một object

## 4. Bài toán ví dụ

Remote điều khiển đèn với lệnh `TurnOn` và `TurnOff`.

## 5. Code Java mẫu

```java
interface Command {
    void execute();
}

class Light {
    public void turnOn() {
        System.out.println("Light is ON");
    }

    public void turnOff() {
        System.out.println("Light is OFF");
    }
}

class TurnOnCommand implements Command {
    private final Light light;

    public TurnOnCommand(Light light) {
        this.light = light;
    }

    @Override
    public void execute() {
        light.turnOn();
    }
}

class TurnOffCommand implements Command {
    private final Light light;

    public TurnOffCommand(Light light) {
        this.light = light;
    }

    @Override
    public void execute() {
        light.turnOff();
    }
}

class RemoteControl {
    public void submit(Command command) {
        // Invoker chỉ gọi execute mà không biết logic bên trong
        command.execute();
    }
}

public class CommandDemo {
    public static void main(String[] args) {
        Light light = new Light();
        RemoteControl remote = new RemoteControl();

        remote.submit(new TurnOnCommand(light));
        remote.submit(new TurnOffCommand(light));
    }
}
```

## 6. Giải thích code

1. `Light` là receiver.
2. `TurnOnCommand` và `TurnOffCommand` đóng gói thao tác.
3. `RemoteControl` là invoker.

## 7. Ưu điểm

1. Tách biệt người gọi và người xử lý
2. Dễ thêm queue, log, undo

## 8. Nhược điểm

1. Tăng số lượng class
