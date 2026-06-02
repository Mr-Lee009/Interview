# Interpreter Pattern

## 1. Định nghĩa

`Interpreter` là pattern định nghĩa cách diễn giải một ngôn ngữ hoặc tập biểu thức đơn giản.

## 2. Cách dùng

1. Mỗi rule của ngôn ngữ được biểu diễn bằng class riêng.
2. Mỗi expression có method `interpret()`.
3. Client tạo cây biểu thức rồi gọi interpret.

## 3. Khi nào dùng

Nên dùng khi:

1. Có ngôn ngữ nhỏ, cú pháp đơn giản
2. Cần diễn giải rule, filter, công thức

Không phù hợp khi ngôn ngữ quá phức tạp.

## 4. Bài toán ví dụ

Diễn giải biểu thức đơn giản: `"A AND B"`.

## 5. Code Java mẫu

```java
interface Expression {
    boolean interpret(Context context);
}

class Context {
    private final boolean a;
    private final boolean b;

    public Context(boolean a, boolean b) {
        this.a = a;
        this.b = b;
    }

    public boolean isA() {
        return a;
    }

    public boolean isB() {
        return b;
    }
}

class VariableAExpression implements Expression {
    @Override
    public boolean interpret(Context context) {
        return context.isA();
    }
}

class VariableBExpression implements Expression {
    @Override
    public boolean interpret(Context context) {
        return context.isB();
    }
}

class AndExpression implements Expression {
    private final Expression left;
    private final Expression right;

    public AndExpression(Expression left, Expression right) {
        this.left = left;
        this.right = right;
    }

    @Override
    public boolean interpret(Context context) {
        // Diễn giải phép AND giữa hai biểu thức con
        return left.interpret(context) && right.interpret(context);
    }
}

public class InterpreterDemo {
    public static void main(String[] args) {
        Expression expression = new AndExpression(
                new VariableAExpression(),
                new VariableBExpression()
        );

        System.out.println(expression.interpret(new Context(true, true)));
        System.out.println(expression.interpret(new Context(true, false)));
    }
}
```

## 6. Giải thích code

1. Mỗi biểu thức là một object.
2. `AndExpression` kết hợp hai biểu thức con.
3. `Context` chứa dữ liệu đầu vào để diễn giải.

## 7. Ưu điểm

1. Dễ mở rộng biểu thức nhỏ
2. Mỗi rule tách thành class rõ ràng

## 8. Nhược điểm

1. Số lượng class tăng nhanh
2. Không phù hợp với grammar lớn
