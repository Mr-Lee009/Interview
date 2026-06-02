# Composite Pattern

## 1. Định nghĩa

`Composite` là pattern cho phép biểu diễn cấu trúc cây, trong đó client có thể xử lý object đơn lẻ và object nhóm theo cùng một cách.

## 2. Cách dùng

Ta thường dùng khi:

1. Dữ liệu có cấu trúc cây
2. Muốn đối xử thống nhất giữa phần tử lá và nhóm phần tử
3. Muốn gọi cùng một method trên cả object đơn và container

## 3. Khi nào dùng

Nên dùng khi:

1. Biểu diễn menu, thư mục, file, component UI, tổ chức phòng ban
2. Cần duyệt và xử lý đệ quy trên cấu trúc lồng nhau

## 4. Bài toán ví dụ

Mô hình file system gồm `FileItem` và `Folder`.  
Folder có thể chứa cả file lẫn folder con.

## 5. Code Java mẫu

```java
import java.util.ArrayList;
import java.util.List;

interface FileSystemItem {
    void show(String indent);
}

class FileItem implements FileSystemItem {
    private final String name;

    public FileItem(String name) {
        this.name = name;
    }

    @Override
    public void show(String indent) {
        System.out.println(indent + "- File: " + name);
    }
}

class Folder implements FileSystemItem {
    private final String name;
    private final List<FileSystemItem> children = new ArrayList<>();

    public Folder(String name) {
        this.name = name;
    }

    public void add(FileSystemItem item) {
        children.add(item);
    }

    @Override
    public void show(String indent) {
        System.out.println(indent + "+ Folder: " + name);

        // Duyệt tất cả phần tử con bằng cùng một interface
        for (FileSystemItem child : children) {
            child.show(indent + "  ");
        }
    }
}

public class CompositeDemo {
    public static void main(String[] args) {
        Folder root = new Folder("root");
        root.add(new FileItem("readme.txt"));

        Folder images = new Folder("images");
        images.add(new FileItem("logo.png"));
        images.add(new FileItem("banner.jpg"));

        root.add(images);
        root.show("");
    }
}
```

## 6. Giải thích code

1. `FileSystemItem` là component chung.
2. `FileItem` là leaf, không chứa con.
3. `Folder` là composite, có thể chứa nhiều `FileSystemItem`.
4. Client chỉ cần gọi `show()` trên root, phần còn lại xử lý đệ quy.

## 7. Ưu điểm

1. Thống nhất cách xử lý object đơn và object nhóm
2. Dễ mở rộng cấu trúc cây
3. Phù hợp với dữ liệu lồng nhau

## 8. Nhược điểm

1. Có thể khó kiểm soát ràng buộc loại phần tử trong composite
2. Thiết kế dễ trở nên quá tổng quát
