Chào bạn, tiếp tục với góc nhìn của một developer, khi có thêm "vũ khí" là AI (như GitHub Copilot, Cursor, hay Cline), tư duy làm việc của chúng ta buộc phải thay đổi. Bạn không còn là "người thợ gõ code" nữa, mà phải chuyển sang vai trò **Tech Lead chỉ đạo một Junior Dev siêu tốc độ nhưng thỉnh thoảng hơi ngốc**.

Lỗi lớn nhất khi dùng AI là quăng cho nó một cái đề bài to đùng rồi hy vọng nó code đúng từ A-Z. Dưới đây là quy trình 5 bước tôi áp dụng để thực sự x10 hiệu suất, giả sử bạn đang dùng một AI Code Agent tích hợp thẳng vào IDE.

---

### Bước 1: Thiết lập Bối cảnh (Context is King)

AI không có giác quan để hiểu toàn bộ project của bạn nếu bạn không chỉ cho nó. Sai lầm là mở một file trắng và bắt đầu chat.

* **Mở sẵn các file liên quan:** Nếu bạn muốn viết một API mới bằng Django/Flask, hãy mở sẵn file `models.py` (chứa schema DB) và file `serializers.py` lên.
* **Dùng tính năng Tag/Mention:** Các Agent hiện đại cho phép bạn tag file. Ví dụ: *"Hãy viết luồng xử lý cho hàm này, dựa trên cấu trúc dữ liệu trong `@models.py` và chuẩn đầu ra của `@utils.py`"*.
* **Định hướng kiến trúc trước:** Bơm cho AI một đoạn comment định hướng ở đầu file. Ví dụ: `# Sử dụng mô hình CNN, framework PyTorch, tuân thủ nguyên tắc Clean Code và có type hinting.`

### Bước 2: Prompting theo cấu trúc (Thay vì ra lệnh suông)

Đừng nói: *"Viết cho tôi tính năng phân loại dữ liệu"*. Hãy viết prompt cho AI giống như bạn đang viết ticket cho một Junior Dev. Tôi thường dùng cấu trúc 3 phần:

1. **Input:** Dữ liệu đầu vào là gì? (Ví dụ: "Input là một Numpy array chứa dữ liệu time-series từ cảm biến, shape [batch_size, time_steps, features]").
2. **Logic cốt lõi:** Các bước xử lý chính là gì? (Ví dụ: "Lọc nhiễu bằng moving average, sau đó đẩy qua 2 lớp Bi-LSTM").
3. **Output & Constraints:** Kết quả trả về và ràng buộc. (Ví dụ: "Output là list các class dự đoán. Không dùng thư viện X, ưu tiên tốc độ xử lý").

### Bước 3: Chia để trị (Micro-tasking) - Cực kỳ quan trọng

Dù Agent có thông minh đến đâu, việc nhồi nhét quá nhiều logic vào một lần sinh code sẽ dẫn đến "hallucination" (AI bịa code) hoặc hỏng luồng.

* **Tách nhỏ:** Nhớ lại "Bước 3" trong quy trình làm task thông thường tôi nói ở trên. Khi đã chia nhỏ task, hãy giao cho AI làm **từng hàm một**.
* **Từng bước:**
* *Lần 1:* "Tạo khung class và định nghĩa các hàm trống (skeleton) với docstring."
* *Lần 2:* "Implement logic cho hàm A."
* *Lần 3:* "Tối ưu hóa vòng lặp for trong hàm B thành list comprehension hoặc vectorization."



### Bước 4: Tận dụng AI làm "Culi" cho các việc nhàm chán

Đừng dùng AI chỉ để viết logic khó. Hãy để nó gánh 70% thời gian gõ phím vô nghĩa của bạn:

* **Boilerplate Code:** "Tạo Dockerfile và docker-compose cho project Python này."
* **Viết Regex/SQL:** "Viết cho tôi câu SQL gom nhóm dữ liệu theo ngày và tính trung bình (hoặc viết Regex bóc tách số điện thoại), giải thích từng phần."
* **Viết Unit Test:** Bôi đen đoạn code bạn vừa viết (hoặc AI viết) và ra lệnh: "Viết 5 test cases cho hàm này, bao gồm 2 edge cases là mảng rỗng và chứa giá trị NaN."
* **Tạo Git Commit:** Sau khi xong việc, mở diff lên và bảo: "Tóm tắt các thay đổi này thành một Git commit message theo chuẩn Conventional Commits."

### Bước 5: Review cực đoan (Zero-Trust)

Vì AI gõ quá nhanh, bạn rất dễ rơi vào bẫy lười biếng và bấm "Accept/Merge" mù quáng.

* **Đọc từng dòng:** Phải hiểu 100% code AI sinh ra. Nếu có một hàm lạ, bôi đen và hỏi ngược lại: *"Hàm này hoạt động under-the-hood thế nào? Có cách nào ít tốn RAM hơn không?"*
* **Kiểm tra lỗ hổng:** AI hay sinh ra code tiềm ẩn lỗi bảo mật (như SQL Injection nếu nối chuỗi) hoặc lỗi hiệu năng (vòng lặp N+1). Bạn là người chịu trách nhiệm cuối cùng, không phải con AI.

---

Về cơ bản, khi có AI, tốc độ gõ phím không còn quan trọng bằng **tư duy thiết kế hệ thống** và **khả năng đặt câu hỏi chính xác**. Bạn hiện đang sử dụng AI Assistant nào (như Cursor, GitHub Copilot, Tabnine...) cho các project của mình?