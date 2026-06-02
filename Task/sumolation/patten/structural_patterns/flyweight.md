# Flyweight Pattern

## 1. Định nghĩa

`Flyweight` là pattern dùng để chia sẻ phần state chung giữa nhiều object nhỏ nhằm giảm sử dụng bộ nhớ.

## 2. Cách dùng

Ta thường tách state của object thành:

1. `Intrinsic state`: phần dùng chung, có thể chia sẻ
2. `Extrinsic state`: phần riêng, được truyền từ bên ngoài khi dùng

## 3. Khi nào dùng

Nên dùng khi:

1. Có số lượng rất lớn object nhỏ
2. Nhiều object có dữ liệu lặp lại
3. Bộ nhớ là vấn đề đáng quan tâm

## 4. Bài toán ví dụ

Game có rất nhiều cây trên bản đồ.  
Nhiều cây có cùng loại, cùng texture, chỉ khác vị trí.

## 5. Code Java mẫu

```java
import java.util.HashMap;
import java.util.Map;

class TreeType {
    private final String name;
    private final String color;

    public TreeType(String name, String color) {
        this.name = name;
        this.color = color;
    }

    public void draw(int x, int y) {
        System.out.println("Draw " + name + " tree with color " + color
                + " at (" + x + ", " + y + ")");
    }
}

class TreeFactory {
    private static final Map<String, TreeType> CACHE = new HashMap<>();

    public static TreeType getTreeType(String name, String color) {
        String key = name + "-" + color;

        // Nếu đã có object dùng chung thì tái sử dụng
        return CACHE.computeIfAbsent(key, k -> new TreeType(name, color));
    }
}

class Tree {
    private final int x;
    private final int y;
    private final TreeType treeType;

    public Tree(int x, int y, TreeType treeType) {
        this.x = x;
        this.y = y;
        this.treeType = treeType;
    }

    public void draw() {
        // x, y là extrinsic state
        // treeType là intrinsic state được chia sẻ
        treeType.draw(x, y);
    }
}

public class FlyweightDemo {
    public static void main(String[] args) {
        TreeType oakGreen = TreeFactory.getTreeType("Oak", "Green");

        Tree tree1 = new Tree(10, 20, oakGreen);
        Tree tree2 = new Tree(30, 40, oakGreen);

        tree1.draw();
        tree2.draw();
    }
}
```

## 6. Giải thích code

1. `TreeType` chứa state dùng chung như tên cây, màu sắc.
2. `TreeFactory` cache các `TreeType` để tái sử dụng.
3. `Tree` chỉ giữ state riêng như tọa độ.
4. Nhiều `Tree` có thể dùng chung một `TreeType`.

## 7. Ưu điểm

1. Giảm bộ nhớ đáng kể
2. Hiệu quả khi có rất nhiều object tương tự nhau

## 8. Nhược điểm

1. Tăng độ phức tạp trong việc tách state
2. Không đáng dùng nếu số lượng object ít
