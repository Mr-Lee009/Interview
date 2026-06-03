# AWS Interview QA

Tài liệu này gồm 10 câu hỏi AWS thường gặp khi phỏng vấn backend/cloud. Mỗi câu có phần trả lời ngắn, ý chính cần nhấn mạnh, ví dụ thực tế và lưu ý vận hành.

## 1. AWS là gì? Vì sao doanh nghiệp dùng AWS?

**Trả lời ngắn**

- `AWS` là nền tảng cloud computing của Amazon.
- AWS cung cấp hạ tầng và dịch vụ cloud như compute, storage, database, networking, security, monitoring.
- Doanh nghiệp dùng AWS để triển khai hệ thống nhanh hơn, mở rộng dễ hơn, giảm chi phí đầu tư server vật lý và tăng độ sẵn sàng.

**Ý chính khi phỏng vấn**

- AWS không chỉ là server thuê ngoài.
- AWS là hệ sinh thái dịch vụ để xây dựng, vận hành và scale hệ thống.
- Các nhóm dịch vụ chính:
  - `Compute`: EC2, Lambda, ECS, EKS.
  - `Storage`: S3, EBS, EFS.
  - `Database`: RDS, DynamoDB, ElastiCache.
  - `Networking`: VPC, Subnet, Route Table, Load Balancer.
  - `Security`: IAM, KMS, Security Group.
  - `Observability`: CloudWatch, CloudTrail.

**Ví dụ thực tế**

- Một app ecommerce có thể dùng:
  - EC2 hoặc ECS để chạy backend.
  - RDS PostgreSQL để lưu order/payment.
  - S3 để lưu ảnh sản phẩm.
  - CloudFront để CDN ảnh.
  - ALB để load balancing.
  - CloudWatch để monitor log/metric.

**Lưu ý**

- Cloud giúp scale nhanh, nhưng nếu thiết kế sai vẫn có thể tốn tiền và khó vận hành.

## 2. EC2 là gì? Khi nào dùng EC2?

**Trả lời ngắn**

- `EC2` là dịch vụ máy chủ ảo trên AWS.
- Bạn có thể chọn CPU, RAM, disk, OS, network và tự cài application.
- Dùng EC2 khi cần kiểm soát server nhiều hơn, chạy app truyền thống, hoặc migrate hệ thống cũ lên cloud.

**Ý chính khi phỏng vấn**

- EC2 giống virtual machine.
- Bạn chịu trách nhiệm nhiều phần:
  - Cài runtime.
  - Patch OS.
  - Deploy app.
  - Monitor process.
  - Scale bằng Auto Scaling Group nếu cần.

**Ưu điểm**

- Linh hoạt.
- Dễ migrate app cũ.
- Kiểm soát môi trường tốt.

**Nhược điểm**

- Phải vận hành server.
- Cần tự lo update, security patch, capacity.
- Nếu không dùng Auto Scaling, dễ thiếu hoặc dư tài nguyên.

**Ví dụ thực tế**

- Chạy Java Spring Boot trên EC2:
  - EC2 nằm trong private subnet.
  - ALB public nhận request.
  - ALB forward traffic vào EC2.
  - EC2 kết nối RDS trong private subnet.

## 3. S3 là gì? S3 khác EBS như thế nào?

**Trả lời ngắn**

- `S3` là object storage, dùng để lưu file/object như ảnh, video, backup, log.
- `EBS` là block storage, thường gắn vào EC2 như một ổ đĩa.

**So sánh nhanh**

| Tiêu chí | S3 | EBS |
|---|---|---|
| Kiểu lưu trữ | Object storage | Block storage |
| Dùng cho | File, image, backup, log, static asset | Disk cho EC2, database, filesystem |
| Gắn với EC2 | Không cần gắn trực tiếp | Gắn vào một EC2 trong cùng AZ |
| Scale | Gần như tự động | Theo volume size/type |
| Truy cập | Qua API/HTTP | Như ổ đĩa OS |

**Ví dụ thực tế**

- Dùng S3 để lưu ảnh avatar:
  - Backend upload file lên S3.
  - Lưu URL/key vào database.
  - CloudFront cache ảnh để người dùng tải nhanh hơn.

**Lưu ý**

- Không nên lưu file upload trực tiếp trong EC2 local disk vì mất instance có thể mất file.
- Với file người dùng upload, S3 thường là lựa chọn đúng hơn.

## 4. VPC, Subnet, Route Table là gì?

**Trả lời ngắn**

- `VPC` là mạng riêng ảo trong AWS.
- `Subnet` là phân vùng mạng bên trong VPC.
- `Route Table` quyết định traffic đi đâu.

**Ý chính khi phỏng vấn**

- VPC giúp cô lập network.
- Public subnet thường chứa:
  - Load Balancer.
  - NAT Gateway.
  - Bastion host nếu cần.
- Private subnet thường chứa:
  - EC2 backend.
  - RDS.
  - ElastiCache.

**Ví dụ kiến trúc phổ biến**

- Internet -> ALB ở public subnet.
- ALB -> EC2/ECS ở private subnet.
- EC2/ECS -> RDS ở private subnet.
- EC2 private muốn ra internet update package thì đi qua NAT Gateway.

**Lưu ý**

- RDS không nên để public nếu không có lý do rất rõ.
- Backend service nên nằm private subnet, chỉ expose qua Load Balancer/API Gateway.

## 5. Security Group và Network ACL khác nhau thế nào?

**Trả lời ngắn**

- `Security Group` là firewall cấp instance/resource.
- `Network ACL` là firewall cấp subnet.

**Bảng so sánh**

| Tiêu chí | Security Group | Network ACL |
|---|---|---|
| Cấp áp dụng | EC2, RDS, ALB, ENI | Subnet |
| Stateful/stateless | Stateful | Stateless |
| Rule allow/deny | Chỉ allow | Allow và deny |
| Thứ tự rule | Không quan trọng | Có thứ tự |
| Dùng phổ biến | Rất phổ biến | Ít hơn, dùng thêm lớp bảo vệ subnet |

**Stateful nghĩa là gì?**

- Nếu Security Group cho request đi vào, response đi ra được tự động cho phép.

**Stateless nghĩa là gì?**

- Với NACL, phải cấu hình cả inbound và outbound.

**Ví dụ thực tế**

- ALB Security Group:
  - Allow inbound port 443 từ internet.
- EC2 Security Group:
  - Allow inbound port 8080 chỉ từ ALB Security Group.
- RDS Security Group:
  - Allow inbound port 5432 chỉ từ EC2 Security Group.

## 6. IAM là gì? Làm sao cấp quyền an toàn trên AWS?

**Trả lời ngắn**

- `IAM` là dịch vụ quản lý danh tính và quyền truy cập.
- IAM dùng để quản lý user, group, role, policy.

**Nguyên tắc quan trọng**

- Dùng `least privilege`: chỉ cấp quyền tối thiểu cần thiết.
- Không hardcode access key trong source code.
- Dùng IAM Role cho EC2/ECS/Lambda thay vì lưu credential.
- Bật MFA cho tài khoản quan trọng.

**Ví dụ thực tế**

- Backend cần upload ảnh lên S3:
  - Không lưu AWS access key trong config.
  - Gắn IAM Role cho EC2/ECS Task.
  - Role chỉ được quyền `s3:PutObject`, `s3:GetObject` trên bucket cụ thể.

**Lưu ý**

- IAM sai là một trong các nguyên nhân phổ biến gây lộ dữ liệu.
- Policy quá rộng như `Action: "*", Resource: "*"` chỉ nên dùng tạm khi debug, không dùng production.

## 7. RDS là gì? Khi nào dùng RDS thay vì tự cài database trên EC2?

**Trả lời ngắn**

- `RDS` là managed relational database service.
- AWS quản lý nhiều phần vận hành database như backup, patching, monitoring, Multi-AZ, read replica.

**Khi nên dùng RDS**

- Cần PostgreSQL/MySQL/MariaDB/SQL Server/Oracle.
- Muốn giảm công vận hành database.
- Cần automated backup, snapshot, restore.
- Cần Multi-AZ để tăng availability.

**Ưu điểm**

- Dễ vận hành hơn tự cài DB trên EC2.
- Có backup tự động.
- Có monitoring tích hợp.
- Hỗ trợ read replica.

**Nhược điểm**

- Ít quyền kiểm soát OS/database internals hơn tự cài.
- Có thể tốn chi phí nếu chọn instance/storage sai.
- Một số extension/tuning đặc biệt có thể bị giới hạn.

**Ví dụ thực tế**

- App gọi món:
  - RDS PostgreSQL lưu order, payment, menu.
  - Enable Multi-AZ cho production.
  - Dùng automated backup 7-30 ngày.
  - Dùng read replica nếu report đọc nhiều.

## 8. Load Balancer và Auto Scaling dùng để làm gì?

**Trả lời ngắn**

- `Load Balancer` phân phối traffic vào nhiều server/service.
- `Auto Scaling` tự tăng/giảm số instance/task theo tải.

**Các loại Load Balancer thường gặp**

- `ALB`: Application Load Balancer, dùng cho HTTP/HTTPS.
- `NLB`: Network Load Balancer, dùng cho TCP/UDP, hiệu năng cao.

**Ví dụ thực tế**

- Backend chạy trên nhiều EC2:
  - ALB nhận request HTTPS.
  - ALB route request vào target group.
  - Auto Scaling Group tăng EC2 khi CPU/request tăng.
  - Khi EC2 lỗi, ALB ngừng gửi traffic vào instance đó.

**Ưu điểm**

- Tăng high availability.
- Scale theo tải.
- Giảm downtime khi một instance lỗi.

**Lưu ý**

- App nên stateless để scale dễ.
- Session nên lưu ngoài instance, ví dụ Redis hoặc database.

## 9. CloudWatch và CloudTrail khác nhau thế nào?

**Trả lời ngắn**

- `CloudWatch` dùng cho metric, log, alarm, dashboard.
- `CloudTrail` dùng để audit API call trong AWS account.

**So sánh**

| Tiêu chí | CloudWatch | CloudTrail |
|---|---|---|
| Mục đích | Monitoring hệ thống/app | Audit hành động trên AWS |
| Dữ liệu | Metric, log, alarm | Ai gọi API gì, lúc nào, từ đâu |
| Ví dụ | CPU EC2 cao, Lambda error, app log | Ai xóa S3 bucket, ai sửa IAM policy |

**Ví dụ thực tế**

- CloudWatch:
  - Alert khi CPU EC2 > 80%.
  - Alert khi RDS free storage thấp.
  - Xem log lỗi backend.
- CloudTrail:
  - Kiểm tra ai đã thay đổi Security Group.
  - Kiểm tra ai tạo access key.

**Lưu ý**

- Production nên bật CloudTrail.
- Log quan trọng nên có retention policy rõ ràng.

## 10. Lambda là gì? Khi nào dùng serverless?

**Trả lời ngắn**

- `Lambda` là dịch vụ serverless compute.
- Bạn chỉ viết function, AWS lo server/runtime scale.
- Lambda chạy theo event như HTTP request, S3 upload, SQS message, EventBridge schedule.

**Khi nên dùng Lambda**

- Job ngắn.
- Event-driven workflow.
- Xử lý file upload.
- Cron job đơn giản.
- API nhỏ qua API Gateway.

**Ưu điểm**

- Không cần quản lý server.
- Scale tự động.
- Trả tiền theo thời gian chạy/request.
- Rất hợp với event-driven architecture.

**Nhược điểm**

- Cold start.
- Có timeout giới hạn.
- Không phù hợp job chạy quá lâu.
- Debug local và observability cần setup tốt.

**Ví dụ thực tế**

- Người dùng upload ảnh món ăn lên S3.
- S3 trigger Lambda.
- Lambda resize ảnh.
- Lambda lưu ảnh resize lại vào S3.
- Backend dùng ảnh resized để hiển thị nhanh hơn.

## Câu trả lời mẫu tổng hợp khi phỏng vấn

- "Em sẽ thiết kế AWS theo hướng private by default: backend và database ở private subnet, chỉ expose qua ALB hoặc API Gateway."
- "Với database quan hệ, em ưu tiên RDS thay vì tự cài DB trên EC2 để giảm chi phí vận hành backup, patching và failover."
- "Với file upload như ảnh sản phẩm, em dùng S3 và CloudFront thay vì lưu trong EC2."
- "Về security, em dùng IAM Role thay vì hardcode access key, cấp quyền theo least privilege."
- "Về monitoring, em dùng CloudWatch cho metric/log/alarm và CloudTrail để audit thay đổi trong AWS account."
