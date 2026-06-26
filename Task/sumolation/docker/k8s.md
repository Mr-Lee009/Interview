Dưới đây là một file cấu hình mẫu (gọi là file YAML) để bạn "đặt hàng" cho Kubernetes.

Ví dụ, bạn muốn triển khai ứng dụng **Quản lý dãy trọ** của mình lên cụm Kubernetes với 3 bản sao (Replica) để đảm bảo không bị sập khi nhiều người truy cập cùng lúc.

Bạn hãy lưu nội dung này thành file tên là `boarding-house-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: boarding-house-app
  labels:
    app: boarding-house
spec:
  replicas: 3 # Khai báo trạng thái mong muốn: Luôn duy trì 3 Pod chạy song song
  selector:
    matchLabels:
      app: boarding-house
  template:
    metadata:
      labels:
        app: boarding-house
    spec:
      containers:
      - name: web-service
        image: vimanhtuyen/boarding-house-backend:latest # Docker Image của bạn trên kho
        ports:
        - containerPort: 8080 # Ứng dụng chạy ngầm ở cổng 8080 trong container
        resources:
          limits:
            cpu: "500m"
            memory: "512Mi"
          requests:
            cpu: "200m"
            memory: "256Mi"
---
# Phần bổ sung: Tạo cổng kết nối (Service) để người dùng bên ngoài có thể truy cập vào ứng dụng
apiVersion: v1
kind: Service
metadata:
  name: boarding-house-service
spec:
  type: NodePort
  selector:
    app: boarding-house
  ports:
    - port: 80
      targetPort: 8080
      nodePort: 30001 # Mở cổng 30001 trên máy chủ để truy cập từ ngoài vào

```

---

### Cách vận hành cực kỳ đơn giản:

1. **Ra lệnh tạo/cập nhật hệ thống:**
Bạn chỉ cần mở cửa sổ dòng lệnh (terminal) và gõ:
```bash
kubectl apply -f boarding-house-deployment.yaml

```


*Lúc này, Kubernetes sẽ tự động đọc file, ra lệnh cho các thành phần (Scheduler, Controller, Kubelet) tải Image về và dựng lên đúng 3 Pod.*
2. **Kiểm tra xem hệ thống đã chạy đủ chưa:**
```bash
kubectl get pods

```


*Bạn sẽ thấy 3 Pod có trạng thái `Running` hiện ra.*
3. **Sức mạnh tự phục hồi (Self-healing):**
Nếu có một kẻ xấu hoặc lỗi code làm treo 1 Pod (ví dụ vô tình làm sập 1 Pod), bạn thử dùng lệnh xóa nó đi:
```bash
kubectl delete pod <tên-pod-bất-kỳ>

```


*Ngay lập tức, bộ giám sát (Controller Manager) của K8s sẽ phát hiện thiếu hụt và tự động tạo ra một Pod hoàn toàn mới thay thế. Bạn không cần phải can thiệp thủ công.* Bạn có muốn thử nghiệm cấu hình thêm kết nối tới Database (như MySQL) đi kèm không?