# Jenkins CI/CD cho Java Project

Tài liệu này hệ thống hóa kiến thức về Jenkins, tập trung vào cách cấu hình để tự động hóa việc build, test và deploy một dự án Java (như Spring Boot).

## 1. Khái niệm ngắn gọn

- **Jenkins:** Là một server tự động hóa mã nguồn mở (Open-source automation server) viết bằng Java, giúp các team thực hiện CI/CD (Continuous Integration / Continuous Delivery).
- **CI (Continuous Integration):** Tích hợp liên tục. Mỗi khi dev push code lên Git, Jenkins sẽ tự động pull code về, compile và chạy Unit Test. Nếu lỗi sẽ báo ngay.
- **CD (Continuous Delivery/Deployment):** Triển khai liên tục. Sau khi CI thành công, tự động đóng gói ứng dụng (thành file `.jar`, `.war` hoặc Docker Image) và đẩy lên server (Dev/Staging/Production).

## 2. Luồng hoạt động (Pipeline Flow)

Luồng chuẩn của một dự án Java trên Jenkins thường đi qua các stage sau:

1. **Checkout:** Kéo mã nguồn mới nhất từ GitHub/GitLab.
2. **Build & Compile:** Sử dụng Maven/Gradle để tải dependencies và biên dịch mã nguồn.
3. **Test:** Chạy Unit Test, Integration Test (và có thể check SonarQube để quét lỗi bảo mật/code smell).
4. **Package:** Đóng gói thành file `*.jar` hoặc `*.war`.
5. **Dockerize (Tùy chọn):** Build Docker Image chứa file jar vừa tạo và push lên Docker Registry.
6. **Deploy:** Kích hoạt script (hoặc gọi SSH, Kubernetes, Ansible) để cập nhật server với bản build mới.

## 3. Cách cấu hình để build project Java

Thay vì click tay trên giao diện web (Freestyle Project), hiện nay chuẩn công nghiệp là dùng **Jenkins Pipeline** bằng cách viết file `Jenkinsfile` đặt trực tiếp trong source code.

### Bước 3.1: Chuẩn bị trên Jenkins Server
Vào `Manage Jenkins` -> `Global Tool Configuration`:
1. **JDK:** Khai báo đường dẫn cài đặt Java (VD: JDK 17). Đặt tên là `jdk-17`.
2. **Maven:** Khai báo đường dẫn Maven. Đặt tên là `maven-3`.

### Bước 3.2: Viết file `Jenkinsfile`
Tạo file `Jenkinsfile` ở thư mục gốc của dự án Java:

```groovy
pipeline {
    agent any

    // Gọi công cụ đã cấu hình trên Jenkins Server
    tools {
        maven 'maven-3'
        jdk 'jdk-17'
    }

    stages {
        stage('Checkout') {
            steps {
                // Lấy code từ branch main
                git branch: 'main', url: 'https://github.com/your-org/your-java-repo.git'
            }
        }

        stage('Build & Test') {
            steps {
                // Chạy lệnh Maven để clean, test và package
                sh 'mvn clean package'
            }
            post {
                success {
                    // Lưu lại báo cáo test nếu thành công
                    junit 'target/surefire-reports/*.xml'
                }
            }
        }

        stage('Archive Artifacts') {
            steps {
                // Lưu lại file JAR vừa build được để tải xuống
                archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
            }
        }
        
        // stage('Deploy') { ... }
    }

    post {
        always {
            echo 'Pipeline đã chạy xong!'
        }
        failure {
            // Gửi email hoặc bắn tin nhắn Slack/Telegram báo build tạch
            echo 'Báo động: Build thất bại. Hãy kiểm tra lại code!'
        }
    }
}
```

## 4. Câu hỏi phỏng vấn hay gặp

**Q1: Phân biệt Declarative Pipeline và Scripted Pipeline trong Jenkins?**
- *Declarative:* Bắt đầu bằng block `pipeline {}`. Cấu trúc rõ ràng, cứng nhắc hơn, dễ đọc, phù hợp cho đa số dự án (Giống ví dụ trên).
- *Scripted:* Bắt đầu bằng `node {}`. Sử dụng code Groovy nguyên bản, tính linh hoạt rất cao, có thể viết vòng lặp `for`, `if/else` phức tạp nhưng khó bảo trì hơn.

**Q2: Làm sao để bảo mật các thông tin nhạy cảm (như DB Password, Token) trong Jenkins?**
- Trả lời: Tuyệt đối không hardcode trong `Jenkinsfile`. Phải sử dụng tính năng **Credentials Plugin** của Jenkins. Lưu secret key trên Jenkins, sau đó trong pipeline gọi ra bằng block `environment { MY_SECRET = credentials('secret-id') }`.

**Q3: Nếu quá trình build Java mất quá nhiều thời gian, em sẽ tối ưu như thế nào?**
- Cấu hình Maven cache: Cache lại thư mục `~/.m2` để không phải tải lại các file `.jar` dependency ở mỗi lần build.
- Chạy Test song song (Parallel execution) thay vì chạy tuần tự.
- Tách các Job: Chỉ chạy Unit Test với mọi commit, còn SonarQube hoặc Integration Test chỉ chạy vào ban đêm (Nightly build).

## 5. Lỗi thường gặp (Troubleshooting)

1. **Lỗi `OutOfMemoryError` (OOM) khi build Maven:**
   - *Nguyên nhân:* Server Jenkins thiếu RAM khi compile các dự án Spring Boot quá nặng.
   - *Cách fix:* Set biến môi trường `MAVEN_OPTS="-Xmx1024m"` trong Jenkinsfile để cấp thêm RAM cho quá trình build.

2. **Lỗi lệch version Java (`UnsupportedClassVersionError`):**
   - *Nguyên nhân:* Code compile bằng Java 17 nhưng server Jenkins mặc định chạy Java 11.
   - *Cách fix:* Định nghĩa rõ block `tools { jdk 'jdk-17' }` trong Jenkinsfile để ép luồng dùng đúng phiên bản.

3. **Mất kết nối Git:**
   - *Nguyên nhân:* Jenkins không có quyền (permission) đọc repo private.
   - *Cách fix:* Cấu hình SSH Key hoặc Personal Access Token (PAT) vào Credentials của Jenkins, sau đó gắn ID credential đó vào cấu hình Git checkout.

## 6. Ghi chú vận hành

- Luôn dọn dẹp không gian đĩa: Các file `*.jar` sinh ra từ Jenkins có thể làm đầy ổ cứng server rất nhanh. Hãy cấu hình "Discard old builds" để tự xóa log và file của các bản build cũ (giữ lại khoảng 5-10 bản gần nhất).
- Sử dụng cơ chế Webhook (Github/GitLab trigger): Đừng để Jenkins chạy bằng cách quét liên tục (poll SCM) gây tốn tài nguyên. Hãy cài đặt Webhook để Github chủ động "ping" Jenkins mỗi khi có code mới.
