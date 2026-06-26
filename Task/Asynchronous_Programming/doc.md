# Lập Trình Bất Đồng Bộ (Asynchronous Programming)

## 📌 Câu Hỏi Phỏng Vấn Về Asynchronous Programming

### 1. **Khác nhau giữa Synchronous và Asynchronous là gì?**
- **Synchronous**: Một tác vụ phải chờ tác vụ trước hoàn thành rồi mới thực hiện. Chương trình bị **blocking**.
- **Asynchronous**: Tác vụ thực hiện mà không cần chờ tác vụ khác. Sử dụng **callbacks, Futures, hay Reactive Streams**.

### 2. **Callback là gì? Lợi ích và vấn đề của nó?**
- **Callback** là hàm được truyền làm tham số cho hàm khác, sẽ được gọi khi tác vụ bất đồng bộ hoàn thành.
- **Lợi ích**: Đơn giản, linh hoạt.
- **Vấn đề**: **Callback Hell** - Nesting quá sâu, khó đọc và maintain.
  ```java
  asyncTask1(() -> {
    asyncTask2(() -> {
      asyncTask3(() -> {
        // Callback Hell!
      });
    });
  });
  ```

### 3. **Future và CompletableFuture khác gì?**
- **Future**: Đại diện cho kết quả của tác vụ bất đồng bộ. Có thể check `isDone()` hoặc `get()` (blocking).
- **CompletableFuture** (Java 8+): 
  - Có thể manual complete
  - Hỗ trợ chaining: `thenApply()`, `thenAccept()`, `thenCombine()`
  - Hỗ trợ exception handling: `exceptionally()`, `handle()`
  - **Non-blocking** composition

### 4. **Khác nhau giữa Thread Pool vs Event Loop?**
- **Thread Pool**: Sử dụng nhiều threads để xử lý tasks (ExecutorService)
- **Event Loop**: Một thread chính quản lý queue các events, xử lý lần lượt (Node.js style)
- **Java**: Thường dùng Thread Pool (ForkJoinPool, Executor Framework)

### 5. **Reactive Programming là gì?**
- Lập trình dựa trên các **streams dữ liệu** thay vì imperative code.
- Sử dụng **push model** thay vì pull model.
- Libraries: Project Reactor, RxJava, Spring WebFlux.
- Ưu điểm: Scalable, responsive, event-driven.

### 6. **Virtual Threads (Java 19+) giải quyết vấn đề gì?**
- Virtual threads là **lightweight threads** quản lý bởi JVM.
- Giải quyết vấn đề: Tạo hàng triệu threads mà không bị OOM.
- Có thể dùng blocking code nhưng vẫn efficient.
  ```java
  try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
    for (int i = 0; i < 1_000_000; i++) {
      executor.submit(() -> {
        // Blocking code - không sao, virtual thread rất rẻ
      });
    }
  }
  ```

### 7. **Reactive Streams là gì?**
- Spec cho asynchronous stream processing với non-blocking backpressure.
- 4 thành phần: Publisher, Subscriber, Subscription, Processor.
- Giúp xử lý data overflow (backpressure) một cách elegant.

### 8. **CompletableFuture có memory leak hay không?**
- Nếu không properly chain hoặc handle exceptions, có thể leak.
- Phải ensure complete hoặc reject: `complete()`, `completeExceptionally()`.

### 9. **Executor Service nào tốt nhất?**
- `CachedThreadPool`: Tạo thread khi cần, reuse idle threads. Good for short tasks.
- `FixedThreadPool`: Số threads cố định. Good for resource control.
- `SingleThreadExecutor`: 1 thread duy nhất. Good for sequential tasks.
- `ForkJoinPool`: Divide-and-conquer. Good for parallel computing.
- `ScheduledExecutorService`: Cho scheduled tasks.

### 10. **Deadlock vs Livelock là gì?**
- **Deadlock**: 2+ threads chờ nhau, không progress được.
- **Livelock**: 2+ threads thay đổi state liên tục nhưng không progress. Mỗi thread bận rộn nhưng không làm gì productive.
- **Starvation**: Thread bị starve của CPU vì priority thấp.

---

## 🔧 Spring Framework Annotations Cho Async Programming

---

### 📊 Bảng Tóm Tắt Các Annotations

| Annotation | Định Nghĩa | Tác Dụng Chính | Use Case |
|-----------|-----------|---------------|----------|
| **@Async** | Thực hiện method asynchronously trong background thread | Giải phóng thread hiện tại, tăng responsiveness | Gửi email, upload file, long operations |
| **@EnableAsync** | Kích hoạt xử lý @Async | Enable interceptor, quản lý thread pool | Configuration class |
| **@Scheduled** | Chạy method định kỳ theo schedule | Thực hiện periodic tasks tự động | Cleanup, daily reports, health checks |
| **@EnableScheduling** | Kích hoạt xử lý @Scheduled | Enable task scheduler, quản lý scheduled threads | Configuration class |
| **WebClient** | HTTP client non-blocking (reactive) | Thực hiện HTTP calls mà không block thread | Gọi external APIs, scalable |
| **@Bean Executor** | Định nghĩa custom thread pool | Tune performance, resource management | Cấu hình thread pool size |
| **Async Return Types** | void, Future, CompletableFuture, Mono | Trả về kết quả async task | Handle results, exceptions |
| **Exception Handling** | Try-catch, exceptionally(), handle() | Xử lý exceptions từ async tasks | Prevent silent failures, provide fallback |

### 🎯 Quick Reference - Định Nghĩa Nhanh

**@Async (Async Method Executor)**
```
Định Nghĩa: Marker annotation để thực hiện method trên thread riêng biệt
Tác Dụng: Method return ngay, code chạy background → không block caller
Khi nào dùng: Email, file I/O, DB operations nặng
```

**@EnableAsync (Async Enabler)**
```
Định Nghĩa: Kích hoạt post-processor cho @Async
Tác Dụng: Spring tạo proxy, intercept async methods, quản lý thread pool
Khi nào dùng: Trên @Configuration class trong app
```

**@Scheduled (Periodic Task)**
```
Định Nghĩa: Marker annotation để chạy method theo schedule
Tác Dụng: Spring gọi method tự động mỗi X thời gian hoặc cron schedule
Khi nào dùng: Cleanup, reports, sync, health checks
```

**@EnableScheduling (Scheduling Enabler)**
```
Định Nghĩa: Kích hoạt post-processor cho @Scheduled
Tác Dụng: Spring tạo task scheduler, quản lý periodic executions
Khi nào dùng: Trên @Configuration class trong app
```

**WebClient (Reactive HTTP)**
```
Định Nghĩa: Non-blocking HTTP client của Spring WebFlux
Tác Dụng: Gọi API mà không block thread, trả Mono/Flux
Khi nào dùng: Thay cho RestTemplate, cần scalability
```

**@Bean Executor (Thread Pool Config)**
```
Định Nghĩa: Method tạo Executor bean để Spring sử dụng
Tác Dụng: Customize core threads, max threads, queue size
Khi nào dùng: Khi default executor không phù hợp
```

---

### 1. **@Async**

**Định Nghĩa:**
- Annotation của Spring Framework dùng để đánh dấu một method thực hiện **asynchronously** (bất đồng bộ)
- Method được ghi dấu `@Async` sẽ chạy trong một **background thread** riêng biệt, không block luồng gọi

**Tác Dụng:**
- ✅ Giải phóng thread hiện tại, cho phép gọi hàm return ngay mà không phải chờ
- ✅ Tăng responsiveness của ứng dụng
- ✅ Xử lý các tác vụ nặng (gửi email, upload file, ghi log) mà không ảnh hưởng flow chính
- ✅ Improve throughput - xử lý nhiều requests song song

**Ví dụ:**
```java
@Service
public class EmailService {
    @Async
    public void sendEmail(String email, String message) {
        // Thực hiện trong background thread
        Thread.sleep(5000); // Simulate long operation
        System.out.println("Email sent to " + email);
    }
    
    // Gọi async method - return ngay, không chờ
    public void notifyUser(String email) {
        sendEmail(email, "Hello"); // Non-blocking call
        System.out.println("Email scheduled");
    }
}
```

**⚠️ Lưu ý:**
- Phải enable với `@EnableAsync` trên config class
- Method phải **public** (protected/private không hoạt động)
- **Self-invocation không hoạt động** - nếu gọi từ chính class sẽ là synchronous
- Return type: `void`, `Future<T>`, hoặc `CompletableFuture<T>`
- **Nên trả về Future/CompletableFuture** nếu cần handle kết quả hoặc exception

### 2. **@EnableAsync**

**Định Nghĩa:**
- Annotation để **kích hoạt xử lý @Async** trong Spring Application Context
- Nó thực hiện post-processing trên tất cả các method được ghi dấu `@Async`

**Tác Dụng:**
- ✅ Enable interceptor cho `@Async` methods
- ✅ Cho phép Spring quản lý thread pool tự động
- ✅ Tạo proxy object để intercept async method calls
- ✅ Cấu hình executor mặc định hoặc custom executor

**Ví dụ:**
```java
@Configuration
@EnableAsync
public class AsyncConfig {
    // Custom Executor - quan trọng để tune performance
    @Bean
    public Executor taskExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(5);      // Min threads luôn chạy
        executor.setMaxPoolSize(10);      // Max threads nếu queue full
        executor.setQueueCapacity(100);   // Queue size trước khi reject
        executor.setThreadNamePrefix("async-");
        executor.setRejectedExecutionHandler(
            new ThreadPoolTaskExecutor.CallerRunsPolicy() // Fallback strategy
        );
        executor.initialize();
        return executor;
    }
}
```

**⚠️ Lưu ý:**
- Phải annotate configuration class (không phải @Component/Service)
- **Mặc định** nếu không config Executor sẽ dùng SimpleAsyncTaskExecutor (tạo thread mới mỗi lần - không tốt)
- Nên custom Executor để control thread pool size
- Có thể specify executor name: `@Async("executorName")`

### 3. **@Scheduled**

**Định Nghĩa:**
- Annotation để đánh dấu method thực hiện **định kỳ theo lịch trình** (periodic execution)
- Được Spring gọi tự động theo schedule mà không cần external trigger

**Tác Dụng:**
- ✅ Chạy task định kỳ mà không cần cron job bên ngoài
- ✅ Thay thế cho quartz scheduler trong các trường hợp đơn giản
- ✅ Xử lý tasks như: cleanup, report generation, data sync, health check
- ✅ Reduce external dependency (no need separate scheduler)

**Ví dụ:**
```java
@Service
public class ScheduledTasks {
    // Chạy mỗi 5 giây (5000ms)
    // fixedDelay = delay từ kết thúc execution này đến bắt đầu next
    @Scheduled(fixedDelay = 5000)
    public void cleanupTask() {
        System.out.println("Cleanup executed at: " + System.currentTimeMillis());
    }
    
    // Chạy mỗi ngày lúc 2 sáng
    // CRON format: second, minute, hour, day, month, day-of-week
    @Scheduled(cron = "0 0 2 * * *")
    public void dailyReportTask() {
        System.out.println("Daily report generated");
    }
    
    // Chạy lần đầu sau 10s, rồi cứ 5s chạy 1 lần (regardless execution time)
    // fixedRate = chạy mỗi X ms, bất kể task mất bao lâu
    @Scheduled(initialDelay = 10000, fixedRate = 5000)
    public void syncDataTask() {
        System.out.println("Data sync executed");
    }
}
```

**⚠️ Lưu ý:**
- Phải enable với `@EnableScheduling`
- `fixedDelay`: Delay **sau khi task kết thúc** → next execution
- `fixedRate`: Chạy mỗi X ms **bất kể execution time** (có thể overlap nếu task lâu)
- `cron`: CRON expression (giống Linux cron) - linh hoạt nhất
- `initialDelay`: Delay trước lần chạy đầu tiên
- **Mặc định chạy trên single thread** - nếu task lâu sẽ delay scheduled tasks khác

### 4. **@EnableScheduling**

**Định Nghĩa:**
- Annotation kích hoạt **scheduled task processing** trong Spring
- Tương tự `@EnableAsync`, nó thực hiện post-processing trên `@Scheduled` methods

**Tác Dụng:**
- ✅ Enable interceptor cho `@Scheduled` methods
- ✅ Khởi tạo TaskScheduler để quản lý scheduled tasks
- ✅ Cho phép cấu hình thread pool size cho scheduled tasks
- ✅ Ensure scheduled methods được gọi đúng thời điểm

**Ví dụ:**
```java
@Configuration
@EnableScheduling
public class SchedulingConfig {
    // Custom TaskScheduler - quan trọng!
    @Bean
    public TaskScheduler taskScheduler() {
        ThreadPoolTaskScheduler scheduler = new ThreadPoolTaskScheduler();
        scheduler.setPoolSize(5);              // Số threads quản lý scheduled tasks
        scheduler.setThreadNamePrefix("scheduled-");
        scheduler.setAwaitTerminationSeconds(60);     // Graceful shutdown
        scheduler.setWaitForTasksToCompleteOnShutdown(true);
        scheduler.initialize();
        return scheduler;
    }
}
```

**⚠️ Lưu ý:**
- **Mặc định** (nếu không config) sẽ dùng single-threaded scheduler - KHÔNG TỐT cho nhiều tasks
- **Bắt buộc** configure TaskScheduler nếu có nhiều `@Scheduled` methods
- Số thread phải đủ để handle tất cả scheduled tasks cùng lúc
- Nếu scheduler thread bận, scheduled tasks sẽ delay
- Khác với `@EnableAsync` - cái này cho periodic execution, cái kia cho on-demand async

### 5. **WebClient & RestTemplate (Reactive)**

**Định Nghĩa:**
- **WebClient**: HTTP client non-blocking (reactive) của Spring WebFlux
- **RestTemplate**: Traditional blocking HTTP client (deprecated in Spring 6.0)

**Tác Dụng:**
- ✅ **WebClient**: Thực hiện HTTP calls mà không block thread - scalable với ít threads
- ✅ Support Mono/Flux (reactive streams)
- ✅ Xử lý backpressure tự động
- ✅ Tích hợp tốt với Spring WebFlux applications

**Async HTTP calls trong Spring WebFlux.**

```java
@Service
public class ApiService {
    private final WebClient webClient;
    
    public ApiService(WebClient webClient) {
        this.webClient = webClient;
    }
    
    // Reactive - Non-blocking
    public Mono<ResponseDto> getDataAsync(String id) {
        return webClient.get()
            .uri("/api/data/{id}", id)
            .retrieve()
            .bodyToMono(ResponseDto.class);
    }
    
    // Return CompletableFuture
    public CompletableFuture<ResponseDto> getDataAsyncFuture(String id) {
        return webClient.get()
            .uri("/api/data/{id}", id)
            .retrieve()
            .bodyToMono(ResponseDto.class)
            .toFuture();
    }
}
```

### 6. **@Bean với Executor**

**Định Nghĩa:**
- `@Bean` annotated method trả về Executor instance để Spring quản lý
- Cấu hình custom thread pool cho async/scheduled tasks

**Tác Dụng:**
- ✅ **Customize thread pool size** - core threads, max threads, queue capacity
- ✅ **Tune performance** - decide how many threads needed
- ✅ **Resource management** - prevent thread leak, graceful shutdown
- ✅ **Multiple executors** - riêng cho async, scheduled, hay other tasks
- ✅ **Exception handling** - configure rejection policy

**Custom async executor configuration.**

```java
@Configuration
public class ExecutorConfig {
    @Bean(name = "asyncExecutor")
    public Executor asyncExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(10);
        executor.setMaxPoolSize(20);
        executor.setQueueCapacity(500);
        executor.setThreadNamePrefix("custom-async-");
        executor.setWaitForTasksToCompleteOnShutdown(true);
        executor.setAwaitTerminationSeconds(60);
        executor.initialize();
        return executor;
    }
    
    @Bean(name = "scheduledExecutor")
    public TaskScheduler scheduledExecutor() {
        ThreadPoolTaskScheduler scheduler = new ThreadPoolTaskScheduler();
        scheduler.setPoolSize(5);
        scheduler.setThreadNamePrefix("custom-scheduled-");
        scheduler.setWaitForTasksToCompleteOnShutdown(true);
        scheduler.setAwaitTerminationSeconds(60);
        scheduler.initialize();
        return scheduler;
    }
}
```

### 7. **Async + Return Types**

**Định Nghĩa:**
- Các return type khác nhau cho `@Async` methods tùy theo use case

**Tác Dụng:**
- ✅ `void`: Fire-and-forget - không cần lấy kết quả
- ✅ `Future<T>`: Legacy way - có thể `.get()` để chờ kết quả (blocking)
- ✅ `CompletableFuture<T>`: Modern way - compose, chain multiple async calls
- ✅ `Mono<T>`: Reactive - non-blocking composition, integration với WebFlux

**Return Types Comparison:**

```java
@Service
public class AsyncService {
    @Async
    public void asyncVoid() {
        // No return
    }
    
    @Async
    public Future<String> asyncFuture() {
        return new AsyncResult<>("Result");
    }
    
    @Async
    public CompletableFuture<String> asyncCompletable() {
        return CompletableFuture.completedFuture("Result");
    }
    
    @Async
    public Mono<String> asyncReactive() {
        return Mono.just("Result");
    }
}
```

### 8. **Exception Handling trong Async**

**Định Nghĩa:**
- Cách xử lý exceptions trong asynchronous method execution
- Khác với try-catch thường, vì exception xảy ra trên background thread

**Tác Dụng:**
- ✅ Prevent silent failures - exceptions được handle & logged
- ✅ Provide fallback values - use `exceptionally()`, `handle()`, `onErrorReturn()`
- ✅ Implement retry logic - `retry()`, `retryWhen()`
- ✅ Custom error handling - define what to do when async task fails

**Exception Handling Patterns:**

```java
@Service
public class AsyncExceptionService {
    @Async
    public CompletableFuture<String> asyncWithException() {
        return CompletableFuture.supplyAsync(() -> {
            if (Math.random() > 0.5) {
                throw new RuntimeException("Random error");
            }
            return "Success";
        }).exceptionally(ex -> {
            System.err.println("Error: " + ex.getMessage());
            return "Default value";
        });
    }
    
    @Async
    public Future<String> asyncWithExceptionHandler() {
        try {
            // Long operation
            Thread.sleep(1000);
            return new AsyncResult<>("Success");
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            return new AsyncResult<>("Error: " + e.getMessage());
        }
    }
}
```

---

## 📊 So Sánh Các Cách Tiếp Cận

| Approach | Use Case | Pros | Cons |
|----------|----------|------|------|
| **Thread** | Simple tasks | Direct, familiar | Resource heavy |
| **ExecutorService** | Task batching | Reuse threads, control | Manual management |
| **@Async** | Spring beans | Simple, decorator-based | Limited control |
| **CompletableFuture** | Complex workflows | Chainable, flexible | Complex API |
| **Reactive (Mono/Flux)** | Stream processing | Backpressure, scalable | Steep learning curve |
| **Virtual Threads** | High concurrency | Simple + efficient | Java 19+ only |

---

## 🎯 Best Practices

1. **Luôn configure Executor**: Đừng rely on default
2. **Handle exceptions**: Luôn catch và log exceptions
3. **Set timeouts**: Tránh hanging requests
4. **Monitor threads**: Check pool metrics
5. **Graceful shutdown**: `setWaitForTasksToCompleteOnShutdown(true)`
6. **Avoid self-invocation**: Gọi `@Async` method từ service khác
7. **Use appropriate tool**: Virtual Threads > Thread Pool > Reactive (tùy use case)
