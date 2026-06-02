# Memento Pattern

## 1. Định nghĩa

`Memento` là pattern dùng để lưu và phục hồi trạng thái trước đó của object mà không làm lộ chi tiết cài đặt bên trong.

## 2. Cách dùng

1. Object gốc tạo `Memento` chứa state.
2. Caretaker giữ danh sách hoặc bản snapshot.
3. Khi cần, object gốc khôi phục từ memento.

## 3. Khi nào dùng

Nên dùng khi:

1. Cần undo/rollback
2. Muốn snapshot state mà không vi phạm đóng gói

## 4. Bài toán ví dụ

Text editor cần undo nội dung trước đó.

## 5. Code Java mẫu

```java
class EditorMemento {
    private final String content;

    public EditorMemento(String content) {
        this.content = content;
    }

    public String getContent() {
        return content;
    }
}

class Editor {
    private String content;

    public void setContent(String content) {
        this.content = content;
    }

    public String getContent() {
        return content;
    }

    public EditorMemento save() {
        // Tạo snapshot trạng thái hiện tại
        return new EditorMemento(content);
    }

    public void restore(EditorMemento memento) {
        this.content = memento.getContent();
    }
}

public class MementoDemo {
    public static void main(String[] args) {
        Editor editor = new Editor();
        editor.setContent("Version 1");
        EditorMemento backup = editor.save();

        editor.setContent("Version 2");
        System.out.println(editor.getContent());

        editor.restore(backup);
        System.out.println(editor.getContent());
    }
}
```

## 6. Giải thích code

1. `Editor` là originator.
2. `EditorMemento` giữ snapshot state.
3. Caretaker ở đây là biến `backup`.

## 7. Ưu điểm

1. Hỗ trợ undo tốt
2. Không lộ state nội bộ quá nhiều

## 8. Nhược điểm

1. Tốn bộ nhớ nếu snapshot nhiều
