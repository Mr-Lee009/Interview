# Chain of Responsibility Pattern

## 1. Định nghĩa

`Chain of Responsibility` là pattern cho phép truyền một request qua chuỗi các handler. Mỗi handler có thể xử lý request hoặc chuyển tiếp cho handler tiếp theo.

## 2. Cách dùng

1. Tạo abstract handler có tham chiếu tới handler kế tiếp.
2. Mỗi handler cụ thể kiểm tra xem mình có xử lý được hay không.
3. Nếu không xử lý, request được chuyển tiếp xuống dưới.

## 3. Khi nào dùng

Nên dùng khi:

1. Có nhiều bước kiểm tra tuần tự
2. Không muốn client biết chính xác ai sẽ xử lý request
3. Muốn thay đổi thứ tự hoặc thêm bớt handler dễ dàng

## 4. Bài toán ví dụ

Quy trình phê duyệt nghỉ phép đi qua `TeamLead`, `Manager`, `Director`.

## 5. Code Java mẫu

```java
abstract class Approver {
    protected Approver next;

    public void setNext(Approver next) {
        this.next = next;
    }

    public abstract void approve(int days);
}

class TeamLead extends Approver {
    @Override
    public void approve(int days) {
        if (days <= 2) {
            System.out.println("TeamLead approved " + days + " days");
        } else if (next != null) {
            next.approve(days);
        }
    }
}

class Manager extends Approver {
    @Override
    public void approve(int days) {
        if (days <= 5) {
            System.out.println("Manager approved " + days + " days");
        } else if (next != null) {
            next.approve(days);
        }
    }
}

class Director extends Approver {
    @Override
    public void approve(int days) {
        System.out.println("Director approved " + days + " days");
    }
}

public class ChainOfResponsibilityDemo {
    public static void main(String[] args) {
        Approver teamLead = new TeamLead();
        Approver manager = new Manager();
        Approver director = new Director();

        // Tạo chuỗi xử lý
        teamLead.setNext(manager);
        manager.setNext(director);

        teamLead.approve(1);
        teamLead.approve(4);
        teamLead.approve(10);
    }
}
```

## 6. Giải thích code

1. `Approver` là handler chung.
2. Mỗi cấp duyệt có logic xử lý riêng.
3. Nếu không đủ quyền thì chuyển request cho cấp kế tiếp.

## 7. Ưu điểm

1. Giảm coupling giữa sender và receiver
2. Dễ mở rộng chuỗi xử lý

## 8. Nhược điểm

1. Khó debug nếu chuỗi dài
2. Có thể không rõ request dừng ở đâu nếu cấu hình sai
