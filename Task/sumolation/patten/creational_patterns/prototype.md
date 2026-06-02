# Prototype Pattern

## 1. Định nghĩa

`Prototype` là pattern tạo object mới bằng cách sao chép từ một object mẫu đã tồn tại, thay vì khởi tạo hoàn toàn từ đầu.

## 2. Cách dùng

Ta thường dùng `Prototype` bằng cách:

1. Tạo một object mẫu
2. Cho class hỗ trợ clone hoặc copy
3. Tạo object mới bằng cách sao chép object mẫu
4. Chỉnh sửa lại một vài thuộc tính riêng nếu cần

## 3. Khi nào dùng

Nên dùng khi:

1. Việc tạo object mới tốn thời gian hoặc tài nguyên
2. Có nhiều object gần giống nhau
3. Muốn clone nhanh từ một cấu hình chuẩn

Cần cẩn thận khi:

1. Object chứa nhiều object con tham chiếu lồng nhau
2. Phân biệt `shallow copy` và `deep copy`

## 4. Bài toán ví dụ

Trong game, cần sinh nhiều `Enemy` từ một mẫu cơ bản, sau đó chỉnh `health` theo từng cấp độ.

## 5. Code Java mẫu

```java
class Enemy implements Cloneable {
    private String type;
    private int health;
    private int attack;

    public Enemy(String type, int health, int attack) {
        this.type = type;
        this.health = health;
        this.attack = attack;
    }

    public void setHealth(int health) {
        this.health = health;
    }

    public void showInfo() {
        System.out.println(
                "Type: " + type + ", health: " + health + ", attack: " + attack
        );
    }

    @Override
    public Enemy clone() {
        try {
            // super.clone() tạo ra bản sao field-by-field
            // Ở đây đủ dùng vì class chỉ chứa kiểu dữ liệu đơn giản
            return (Enemy) super.clone();
        } catch (CloneNotSupportedException e) {
            throw new RuntimeException(e);
        }
    }
}

public class PrototypeDemo {
    public static void main(String[] args) {
        // Object mẫu ban đầu
        Enemy baseEnemy = new Enemy("Orc", 100, 15);

        // Clone từ mẫu thay vì new lại từ đầu
        Enemy enemyLevel1 = baseEnemy.clone();
        enemyLevel1.setHealth(120);

        Enemy enemyLevel2 = baseEnemy.clone();
        enemyLevel2.setHealth(80);

        System.out.println("Base enemy:");
        baseEnemy.showInfo();

        System.out.println("Enemy level 1:");
        enemyLevel1.showInfo();

        System.out.println("Enemy level 2:");
        enemyLevel2.showInfo();
    }
}
```

## 6. Giải thích code

1. `baseEnemy` là prototype gốc.
2. `clone()` tạo bản sao từ object mẫu.
3. Sau khi clone, ta chỉ sửa phần khác biệt như `health`.
4. Cách này hữu ích khi object gốc đã có sẵn cấu hình chung.

## 7. Ưu điểm

1. Tạo object nhanh từ mẫu
2. Giảm chi phí khởi tạo lặp lại
3. Dễ sinh ra nhiều object tương tự nhau

## 8. Nhược điểm

1. Clone có thể phức tạp nếu object lồng nhau
2. Dễ gặp lỗi nếu không xử lý đúng `deep copy`
