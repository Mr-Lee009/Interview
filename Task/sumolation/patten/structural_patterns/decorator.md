# Decorator Pattern

## 1. Định nghĩa

`Decorator` là pattern cho phép thêm chức năng cho object một cách động bằng cách bọc object đó trong một object khác có cùng interface.

## 2. Cách dùng

Ta thường dùng khi:

1. Muốn thêm hành vi mà không sửa class gốc
2. Muốn kết hợp nhiều chức năng theo kiểu xếp chồng
3. Không muốn tạo quá nhiều subclass cho mọi tổ hợp tính năng

## 3. Khi nào dùng

Nên dùng khi:

1. Cần thêm logging, encryption, compression, validation
2. Cần mở rộng hành vi tại runtime

## 4. Bài toán ví dụ

Hệ thống xuất dữ liệu văn bản.  
Có thể thêm `Compression` và `Encryption` trước khi ghi ra ngoài.

## 5. Code Java mẫu

```java
interface DataSource {
    void writeData(String data);
}

class FileDataSource implements DataSource {
    @Override
    public void writeData(String data) {
        System.out.println("Write raw data: " + data);
    }
}

abstract class DataSourceDecorator implements DataSource {
    protected final DataSource wrappee;

    public DataSourceDecorator(DataSource wrappee) {
        this.wrappee = wrappee;
    }
}

class CompressionDecorator extends DataSourceDecorator {
    public CompressionDecorator(DataSource wrappee) {
        super(wrappee);
    }

    @Override
    public void writeData(String data) {
        // Giả lập nén dữ liệu trước khi ghi
        String compressed = "[COMPRESSED]" + data;
        wrappee.writeData(compressed);
    }
}

class EncryptionDecorator extends DataSourceDecorator {
    public EncryptionDecorator(DataSource wrappee) {
        super(wrappee);
    }

    @Override
    public void writeData(String data) {
        // Giả lập mã hóa dữ liệu trước khi ghi
        String encrypted = "[ENCRYPTED]" + data;
        wrappee.writeData(encrypted);
    }
}

public class DecoratorDemo {
    public static void main(String[] args) {
        DataSource source = new FileDataSource();

        // Bọc nhiều lớp decorator để cộng dồn hành vi
        DataSource decoratedSource =
                new EncryptionDecorator(new CompressionDecorator(source));

        decoratedSource.writeData("Important report");
    }
}
```

## 6. Giải thích code

1. `DataSource` là interface chung.
2. `FileDataSource` là object gốc.
3. `DataSourceDecorator` giữ tham chiếu đến object được bọc.
4. `CompressionDecorator` và `EncryptionDecorator` thêm hành vi mới.
5. Có thể xếp nhiều decorator theo thứ tự mong muốn.

## 7. Ưu điểm

1. Thêm chức năng linh hoạt
2. Tuân thủ nguyên tắc open/closed
3. Tránh sinh quá nhiều subclass

## 8. Nhược điểm

1. Nhiều lớp wrapper có thể làm flow khó đọc
2. Debug có thể khó hơn nếu chain dài
