# Strategy Pattern

## 1. Định nghĩa

`Strategy` là pattern đóng gói các thuật toán khác nhau vào các class riêng, cho phép thay thế linh hoạt tại runtime.

## 2. Cách dùng

1. Tạo interface strategy.
2. Mỗi thuật toán là một implementation riêng.
3. Context nhận strategy từ bên ngoài và gọi nó.

## 3. Khi nào dùng

Nên dùng khi:

1. Có nhiều cách xử lý cho cùng một bài toán
2. Muốn thay đổi thuật toán lúc runtime
3. Muốn loại bỏ if-else chọn thuật toán

## 4. Bài toán ví dụ

Hệ thống thanh toán hỗ trợ `CreditCard` và `PayPal`.

## 5. Code Java mẫu

```java
interface PaymentStrategy {
    void pay(int amount);
}

class CreditCardPayment implements PaymentStrategy {
    @Override
    public void pay(int amount) {
        System.out.println("Paid " + amount + " by credit card");
    }
}

class PayPalPayment implements PaymentStrategy {
    @Override
    public void pay(int amount) {
        System.out.println("Paid " + amount + " by PayPal");
    }
}

class ShoppingCart {
    private PaymentStrategy paymentStrategy;

    public void setPaymentStrategy(PaymentStrategy paymentStrategy) {
        this.paymentStrategy = paymentStrategy;
    }

    public void checkout(int amount) {
        // Context ủy quyền cho strategy hiện tại
        paymentStrategy.pay(amount);
    }
}

public class StrategyDemo {
    public static void main(String[] args) {
        ShoppingCart cart = new ShoppingCart();

        cart.setPaymentStrategy(new CreditCardPayment());
        cart.checkout(100);

        cart.setPaymentStrategy(new PayPalPayment());
        cart.checkout(200);
    }
}
```

## 6. Giải thích code

1. `PaymentStrategy` là abstraction.
2. Mỗi cách thanh toán là một strategy riêng.
3. `ShoppingCart` không cần biết chi tiết thuật toán thanh toán.

## 7. Ưu điểm

1. Dễ thay đổi thuật toán
2. Giảm if-else

## 8. Nhược điểm

1. Client phải biết chọn strategy phù hợp
