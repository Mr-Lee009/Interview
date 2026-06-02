# Template Method Pattern

## 1. Định nghĩa

`Template Method` là pattern định nghĩa skeleton của một thuật toán trong lớp cha, đồng thời cho phép lớp con cài đặt chi tiết một số bước.

## 2. Cách dùng

1. Tạo abstract class chứa method template.
2. Một số bước là cố định.
3. Một số bước được khai báo abstract để subclass cài đặt.

## 3. Khi nào dùng

Nên dùng khi:

1. Có nhiều quy trình giống nhau về khung chung
2. Chỉ khác một vài bước cụ thể

## 4. Bài toán ví dụ

Quy trình tạo báo cáo luôn gồm:

1. Lấy dữ liệu
2. Xử lý dữ liệu
3. Xuất báo cáo

Khác nhau ở loại báo cáo `PDF` và `Excel`.

## 5. Code Java mẫu

```java
abstract class ReportGenerator {
    public final void generateReport() {
        // Đây là skeleton cố định của thuật toán
        fetchData();
        processData();
        exportReport();
    }

    protected void fetchData() {
        System.out.println("Fetch data from database");
    }

    protected void processData() {
        System.out.println("Process data");
    }

    protected abstract void exportReport();
}

class PdfReportGenerator extends ReportGenerator {
    @Override
    protected void exportReport() {
        System.out.println("Export PDF report");
    }
}

class ExcelReportGenerator extends ReportGenerator {
    @Override
    protected void exportReport() {
        System.out.println("Export Excel report");
    }
}

public class TemplateMethodDemo {
    public static void main(String[] args) {
        ReportGenerator pdf = new PdfReportGenerator();
        pdf.generateReport();

        ReportGenerator excel = new ExcelReportGenerator();
        excel.generateReport();
    }
}
```

## 6. Giải thích code

1. `generateReport()` là template method.
2. `fetchData()` và `processData()` dùng chung.
3. `exportReport()` do subclass quyết định.

## 7. Ưu điểm

1. Tái sử dụng phần khung thuật toán
2. Giữ quy trình nhất quán

## 8. Nhược điểm

1. Phụ thuộc vào kế thừa
