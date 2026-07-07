Nếu bạn đang chuẩn bị cho vị trí **Java Backend (2-4 năm kinh nghiệm)** thì đây là bộ câu hỏi về **Annotation và Spring Bean** mà mình thường thấy từ Junior → Senior.

---

# Mức 1: Cơ bản

### 1. Annotation là gì?

Kỳ vọng:

> Annotation là metadata gắn lên class, method, field... để cung cấp thông tin cho compiler hoặc framework xử lý.

---

### 2. Annotation có tác dụng gì?

Ví dụ:

```java
@Override
@Component
@Autowired
```

Kỳ vọng:

> Annotation không tự thực hiện logic, nó chỉ cung cấp metadata cho framework hoặc compiler.

---

### 3. Sự khác nhau giữa @Component và @Service?

Kỳ vọng:

```java
@Component
@Service
@Repository
@Controller
```

đều là bean.

Khác nhau chủ yếu ở semantic (ý nghĩa).

---

### 4. Bean là gì?

Kỳ vọng:

> Bean là object được Spring IoC Container quản lý.

---

### 5. Spring quản lý Bean như thế nào?

Kỳ vọng:

> Scan → BeanDefinition → Instantiate → Dependency Injection → Ready.

---

# Mức 2: Hiểu bản chất

### 6. Annotation được lưu ở đâu?

Kỳ vọng:

```text
.class file
```

---

### 7. RetentionPolicy là gì?

```java
SOURCE
CLASS
RUNTIME
```

Hỏi tiếp:

> Tại sao @Autowired phải dùng RUNTIME?

Đáp:

> Vì Spring cần đọc annotation lúc runtime.

---

### 8. @Target dùng để làm gì?

Ví dụ:

```java
@Target(ElementType.FIELD)
```

---

### 9. Spring đọc Annotation bằng cách nào?

Kỳ vọng:

> Reflection.

Ví dụ:

```java
field.getAnnotation(...)
```

---

### 10. BeanDefinition là gì?

Đây là câu nhiều người 2-3 năm kinh nghiệm không trả lời được.

Kỳ vọng:

> Metadata mô tả bean trước khi bean được tạo.

Ví dụ:

```text
Bean Name
Bean Class
Scope
Lazy
DependsOn
```

---

# Mức 3: Bean Lifecycle

### 11. Mô tả vòng đời Bean

Kỳ vọng:

```text
Scan
↓
BeanDefinition
↓
Instantiate
↓
Populate Properties
↓
@PostConstruct
↓
BeanPostProcessor
↓
Ready
↓
@PreDestroy
```

---

### 12. @PostConstruct chạy khi nào?

Sau:

```java
@Autowired
```

Trước:

```java
Bean Ready
```

---

### 13. @PreDestroy chạy khi nào?

Khi:

```java
ApplicationContext.close()
```

---

### 14. BeanPostProcessor là gì?

Đây là câu Senior rất thích hỏi.

Kỳ vọng:

> Hook cho phép can thiệp trước và sau khi bean khởi tạo.

Ví dụ:

```java
postProcessBeforeInitialization()
postProcessAfterInitialization()
```

---

### 15. AOP Proxy được tạo ở giai đoạn nào?

Đáp:

```text
postProcessAfterInitialization
```

---

# Mức 4: Dependency Injection

### 16. @Autowired hoạt động như thế nào?

Kỳ vọng:

Spring:

```java
Reflection
```

↓

Tìm bean phù hợp

↓

Inject vào field

---

### 17. Constructor Injection và Field Injection khác nhau thế nào?

Nên trả lời:

Ưu tiên:

```java
Constructor Injection
```

vì:

* Immutable
* Test dễ
* Tránh NullPointerException

---

### 18. Nếu có 2 Bean cùng type thì sao?

Ví dụ:

```java
@Service
class A implements Payment {}

@Service
class B implements Payment {}
```

```java
@Autowired
Payment payment;
```

Lỗi:

```text
NoUniqueBeanDefinitionException
```

---

### 19. Cách giải quyết?

```java
@Qualifier
```

hoặc:

```java
@Primary
```

---

# Mức 5: Scope

### 20. Bean mặc định là scope gì?

```java
singleton
```

---

### 21. Các scope của Spring?

```java
singleton
prototype
request
session
application
```

---

### 22. Singleton trong Spring có phải Singleton Design Pattern không?

Đây là câu cực hay.

Đáp:

Không hoàn toàn.

Singleton Pattern:

```text
1 instance / JVM
```

Spring Singleton:

```text
1 instance / ApplicationContext
```

---

# Mức 6: Annotation nâng cao

### 23. Tự tạo annotation như thế nào?

```java
@Target
@Retention
public @interface MyAnnotation {
}
```

---

### 24. Annotation có method được không?

Ví dụ:

```java
public @interface Retry {

    int retryCount() default 3;
}
```

---

### 25. Annotation có kế thừa được không?

Không.

Annotation không hỗ trợ inheritance như class.

---

### 26. Meta Annotation là gì?

Ví dụ:

```java
@Service
```

bên trong thực chất có:

```java
@Component
```

Đây gọi là Meta Annotation.

---

### 27. Spring tìm được @Service vì sao?

Do:

```java
@Component
```

nằm trong @Service.

---

# Mức 7: Senior

### 28. @Transactional hoạt động như thế nào?

Kỳ vọng:

```text
Bean
↓
AOP Proxy
↓
Transaction Interceptor
↓
Method Execute
```

---

### 29. Tại sao gọi nội bộ không chạy @Transactional?

Ví dụ:

```java
@Service
class UserService {

    @Transactional
    public void transfer(){}

    public void test(){
        transfer();
    }
}
```

Đáp:

Vì không đi qua Proxy.

---

### 30. Spring có đọc Annotation mỗi lần gọi API không?

Đáp:

Không.

Khi startup Spring scan một lần và cache metadata.

---

### 31. BeanFactory và ApplicationContext khác nhau thế nào?

Đây là câu Senior rất hay hỏi.

Kỳ vọng:

```text
BeanFactory
    ↓
ApplicationContext
```

ApplicationContext:

* AOP
* Event
* Internationalization
* BeanPostProcessor

---

### 32. Làm sao tự tạo annotation @XssEncode?

Kỳ vọng:

```java
@Retention(RUNTIME)
@Target(FIELD)
@JsonSerialize(using = XssSerializer.class)
public @interface XssEncode {
}
```

và dùng Jackson Serializer hoặc Aspect để xử lý.

---

## Nếu phỏng vấn Java Backend 3 năm kinh nghiệm

Mình đánh giá:

* Trả lời tốt câu 1 → 15: Mid-level.
* Trả lời tốt câu 16 → 27: Strong Mid-level.
* Trả lời tốt câu 28 → 32: Có tư duy Senior, hiểu Spring bên dưới chứ không chỉ dùng annotation.

Đặc biệt câu **"Tại sao self-invocation làm @Transactional mất tác dụng?"**, **"BeanDefinition là gì?"** và **"BeanPostProcessor dùng để làm gì?"** là những câu phân loại ứng viên rất hiệu quả.
