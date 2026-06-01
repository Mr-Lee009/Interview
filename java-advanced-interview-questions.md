# 10 Câu Hỏi Phỏng Vấn Java Nâng Cao

1. Hãy giải thích sự khác nhau giữa `synchronized`, `ReentrantLock` và các class trong `java.util.concurrent`. Trong dự án thực tế, khi nào bạn chọn từng cách?

2. `volatile` giải quyết vấn đề gì trong Java Memory Model? Nó khác gì với `synchronized`, và vì sao `volatile` không đảm bảo thread-safe trong mọi trường hợp?

3. Hãy mô tả một tình huống race condition trong ứng dụng Java backend và cách bạn phát hiện, tái hiện, và xử lý nó.

4. Sự khác nhau giữa lập trình đồng bộ và bất đồng bộ trong Java là gì? Khi nào nên dùng `CompletableFuture` thay vì xử lý tuần tự?

5. Trong một hệ thống có nhiều request cùng cập nhật số dư tài khoản hoặc tồn kho sản phẩm, bạn sẽ thiết kế thế nào để tránh mất dữ liệu hoặc cập nhật sai?

6. `ThreadPoolExecutor` hoạt động như thế nào? Nếu cấu hình pool không hợp lý trong môi trường production thì có thể gây ra những vấn đề gì?

7. Hãy giải thích deadlock, livelock, và starvation. Trong môi trường thực tế, làm sao để phòng tránh các vấn đề này?

8. `ConcurrentHashMap` thread-safe như thế nào? Nó khác gì với việc bọc `HashMap` bằng `Collections.synchronizedMap()`?

9. Khi xây dựng một API gọi nhiều service ngoài như payment, notification, và user profile, bạn sẽ áp dụng timeout, retry, circuit breaker, và logging như thế nào để hệ thống ổn định hơn?

10. Trong ứng dụng Java hiện đại dùng Spring Boot chạy trên môi trường cloud hoặc container, bạn sẽ theo dõi và tối ưu hiệu năng, thread usage, và bottleneck ra sao khi hệ thống có traffic tăng cao?
