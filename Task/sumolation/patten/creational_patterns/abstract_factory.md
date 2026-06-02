# Abstract Factory Pattern

## 1. Định nghĩa

`Abstract Factory` là pattern cung cấp một interface để tạo ra một họ các object liên quan với nhau mà không cần chỉ rõ class cụ thể.

## 2. Cách dùng

Ta thường dùng theo cấu trúc:

1. Định nghĩa nhiều loại product như `Button`, `Checkbox`
2. Tạo các implementation theo từng họ như `Light`, `Dark`
3. Tạo một factory abstract để sinh ra cả họ object
4. Truyền factory phù hợp vào client

## 3. Khi nào dùng

Nên dùng khi:

1. Có nhiều object đi theo bộ với nhau
2. Muốn đảm bảo các object trong cùng họ tương thích
3. Muốn đổi nguyên cả theme, cả platform, cả bộ driver mà không sửa code client

## 4. Bài toán ví dụ

Ứng dụng giao diện hỗ trợ `Light Theme` và `Dark Theme`.  
Mỗi theme cần tạo đồng bộ:

1. `Button`
2. `Checkbox`

## 5. Code Java mẫu

```java
interface Button {
    void render();
}

interface Checkbox {
    void render();
}

class LightButton implements Button {
    @Override
    public void render() {
        System.out.println("Render light button");
    }
}

class DarkButton implements Button {
    @Override
    public void render() {
        System.out.println("Render dark button");
    }
}

class LightCheckbox implements Checkbox {
    @Override
    public void render() {
        System.out.println("Render light checkbox");
    }
}

class DarkCheckbox implements Checkbox {
    @Override
    public void render() {
        System.out.println("Render dark checkbox");
    }
}

interface UiFactory {
    // Factory tạo button thuộc cùng một họ
    Button createButton();

    // Factory tạo checkbox thuộc cùng một họ
    Checkbox createCheckbox();
}

class LightThemeFactory implements UiFactory {
    @Override
    public Button createButton() {
        return new LightButton();
    }

    @Override
    public Checkbox createCheckbox() {
        return new LightCheckbox();
    }
}

class DarkThemeFactory implements UiFactory {
    @Override
    public Button createButton() {
        return new DarkButton();
    }

    @Override
    public Checkbox createCheckbox() {
        return new DarkCheckbox();
    }
}

class Screen {
    private final Button button;
    private final Checkbox checkbox;

    public Screen(UiFactory factory) {
        // Screen không biết class cụ thể nào đang được tạo
        this.button = factory.createButton();
        this.checkbox = factory.createCheckbox();
    }

    public void render() {
        button.render();
        checkbox.render();
    }
}

public class AbstractFactoryDemo {
    public static void main(String[] args) {
        // Chỉ cần đổi factory là đổi nguyên bộ component
        UiFactory factory = new DarkThemeFactory();
        Screen screen = new Screen(factory);
        screen.render();
    }
}
```

## 6. Giải thích code

1. `Button` và `Checkbox` là các product type.
2. `LightButton`, `DarkButton`, `LightCheckbox`, `DarkCheckbox` là các product cụ thể.
3. `UiFactory` định nghĩa cách tạo một bộ object liên quan.
4. `LightThemeFactory` và `DarkThemeFactory` tạo các object đồng nhất theo từng theme.
5. `Screen` chỉ phụ thuộc vào `UiFactory`, không phụ thuộc class cụ thể.

## 7. Ưu điểm

1. Dễ đổi cả họ object
2. Đảm bảo các object đi với nhau đúng bộ
3. Client ít phụ thuộc vào lớp cụ thể

## 8. Nhược điểm

1. Nếu thêm một loại product mới như `Textbox`, phải sửa tất cả factory
2. Cấu trúc class nhiều hơn so với cách viết trực tiếp
