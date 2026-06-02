# Visitor Pattern

## 1. Định nghĩa

`Visitor` là pattern cho phép thêm hành vi mới vào một cấu trúc object mà không cần sửa các class phần tử.

## 2. Cách dùng

1. Các element có method `accept(visitor)`.
2. Visitor khai báo các method `visit()` cho từng loại element.
3. Hành vi mới được thêm bằng visitor mới.

## 3. Khi nào dùng

Nên dùng khi:

1. Cấu trúc object ổn định
2. Cần thêm nhiều hành vi mới lên cấu trúc đó

## 4. Bài toán ví dụ

Hệ thống tài liệu có `TextFile` và `ImageFile`.  
Cần thêm hành vi export mà không sửa class file.

## 5. Code Java mẫu

```java
interface FileElement {
    void accept(FileVisitor visitor);
}

class TextFile implements FileElement {
    @Override
    public void accept(FileVisitor visitor) {
        visitor.visit(this);
    }
}

class ImageFile implements FileElement {
    @Override
    public void accept(FileVisitor visitor) {
        visitor.visit(this);
    }
}

interface FileVisitor {
    void visit(TextFile textFile);
    void visit(ImageFile imageFile);
}

class ExportVisitor implements FileVisitor {
    @Override
    public void visit(TextFile textFile) {
        System.out.println("Export text file");
    }

    @Override
    public void visit(ImageFile imageFile) {
        System.out.println("Export image file");
    }
}

public class VisitorDemo {
    public static void main(String[] args) {
        FileElement[] files = {new TextFile(), new ImageFile()};
        FileVisitor visitor = new ExportVisitor();

        for (FileElement file : files) {
            // Double dispatch: element chọn đúng method visit tương ứng
            file.accept(visitor);
        }
    }
}
```

## 6. Giải thích code

1. `TextFile` và `ImageFile` là các element.
2. `ExportVisitor` là hành vi mới.
3. Muốn thêm hành vi khác như `CompressVisitor`, chỉ cần tạo visitor mới.

## 7. Ưu điểm

1. Dễ thêm hành vi mới
2. Không phải sửa class element nhiều lần

## 8. Nhược điểm

1. Thêm element mới sẽ phải sửa tất cả visitor
