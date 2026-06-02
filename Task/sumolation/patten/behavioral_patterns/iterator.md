# Iterator Pattern

## 1. Định nghĩa

`Iterator` là pattern cung cấp cách duyệt qua các phần tử của một collection mà không làm lộ cấu trúc bên trong.

## 2. Cách dùng

1. Tạo iterator có `hasNext()` và `next()`.
2. Collection cung cấp method tạo iterator.

## 3. Khi nào dùng

Nên dùng khi:

1. Muốn ẩn cấu trúc nội bộ của collection
2. Muốn chuẩn hóa cách duyệt dữ liệu

## 4. Bài toán ví dụ

Danh sách tên sinh viên cần được duyệt lần lượt.

## 5. Code Java mẫu

```java
class StudentCollection {
    private final String[] students = {"An", "Binh", "Chi"};

    public StudentIterator iterator() {
        return new StudentIterator();
    }

    class StudentIterator {
        private int index = 0;

        public boolean hasNext() {
            return index < students.length;
        }

        public String next() {
            // Trả phần tử hiện tại rồi tăng con trỏ
            return students[index++];
        }
    }
}

public class IteratorDemo {
    public static void main(String[] args) {
        StudentCollection collection = new StudentCollection();
        StudentCollection.StudentIterator iterator = collection.iterator();

        while (iterator.hasNext()) {
            System.out.println(iterator.next());
        }
    }
}
```

## 6. Giải thích code

1. `StudentCollection` che giấu mảng nội bộ.
2. `StudentIterator` quản lý trạng thái duyệt.

## 7. Ưu điểm

1. Duyệt dữ liệu nhất quán
2. Không lộ chi tiết collection

## 8. Nhược điểm

1. Có thể dư thừa với collection quá đơn giản
