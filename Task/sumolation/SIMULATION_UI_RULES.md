# Simulation UI Rules

File này là quy chuẩn thiết kế cho các màn hình mô phỏng trong thư mục `Task/sumolation`.

Mục tiêu: sau này khi tạo demo HTML mới, hãy lấy màn hình `AWS/index.html` làm mẫu chính. Demo phải dễ quan sát, có cấu trúc rõ, ưu tiên diagram/flow lớn, và giúp người đọc hiểu nhanh khái niệm phỏng vấn.

## 1. Mục tiêu của màn hình mô phỏng

- Demo không phải landing page.
- Demo phải là màn hình học/ôn trực quan.
- Người mở file phải hiểu được:
  - Chủ đề đang mô phỏng là gì.
  - Thành phần chính gồm những gì.
  - Luồng dữ liệu/luồng xử lý đi qua đâu.
  - Khi nào dùng thành phần đó.
  - Lưu ý vận hành hoặc lỗi thường gặp.
- Demo phải chạy trực tiếp bằng browser nếu chỉ là HTML/CSS/JS thuần.

## 2. File mẫu chuẩn

Lấy file sau làm mẫu layout chính cho các demo flow mới:

```text
Task/sumolation/payment/momo/index.html
```

Lý do dùng file này làm mẫu layout:

- Header full row có mô tả và legend.
- Main row chia `80% / 20%`: diagram lớn và steps nhỏ.
- Footer full row chứa log/rule quan trọng.
- Diagram có scroll ngang/dọc, zoom và khoanh vùng hệ thống.
- Steps có active state và log cập nhật theo step.

File sau vẫn là mẫu tốt cho demo dạng nhiều tab/service:

```text
Task/sumolation/AWS/index.html
```

Các điểm cần kế thừa từ demo dạng tab:

- Có sidebar tab hoặc navigation rõ ràng.
- Mỗi service/chủ đề là một tab riêng nếu có nhiều mục.
- Diagram/flow là phần lớn nhất trên màn hình.
- Có phần giải thích ngắn, không nhồi quá nhiều chữ vào diagram.
- Có trạng thái, tag, use case, điểm mạnh, lưu ý và ví dụ thực tế.
- Có thể phóng to/thu nhỏ diagram nếu sơ đồ có nhiều thành phần.

## 3. Layout chuẩn

### 3.1 Cấu trúc tổng thể

Từ các demo mới trở đi, ưu tiên dùng cấu trúc 3 hàng cố định như sau:

```text
Row 1 - Header full row
  - Title
  - Subtitle/mô tả ngắn demo
  - Badge/tag quan trọng nếu cần
  - Legend/chú thích ký hiệu, màu, nét liền/nét đứt, icon

Row 2 - Main content
  - Diagram/flow panel: chiếm khoảng 80% chiều ngang
  - Steps/checklist panel: chiếm khoảng 20% chiều ngang

Row 3 - Footer full row
  - Log đang chạy
  - Rule quan trọng
  - Ghi chú vận hành
  - Thông tin cần nhớ
```

Mục tiêu của layout này:

- Người xem đọc header là hiểu demo đang mô phỏng gì.
- Người xem nhìn row 2 là thấy ngay luồng xử lý và các bước tương ứng.
- Người xem nhìn footer là biết step hiện tại đang làm gì, rule nào không được quên.
- Không nhồi phần log hoặc note vào cạnh diagram làm biểu đồ bị nhỏ.
- Không để phần steps quá lớn; steps chỉ hỗ trợ việc đọc flow.

CSS pattern khuyến nghị:

```css
.layout {
  display: grid;
  grid-template-columns: minmax(0, 4fr) minmax(260px, 1fr);
  gap: 14px;
}

.footer {
  margin-top: 14px;
}

@media (max-width: 1120px) {
  .layout {
    grid-template-columns: 1fr;
  }
}
```

Tỉ lệ `4fr / 1fr` tương đương khoảng `80% / 20%`. Có thể điều chỉnh nhẹ nếu nội dung steps dài, nhưng diagram vẫn phải là phần lớn nhất.

### 3.2 Sidebar tabs

- Dùng khi demo có nhiều service, nhiều pattern hoặc nhiều case.
- Sidebar/tab là biến thể bổ sung, không thay thế layout 3 hàng ở trên.
- Nếu có sidebar/tab, đặt tab trong header hoặc trong panel phụ gọn; không để sidebar làm diagram bị nhỏ quá.
- Mỗi tab nên có:
  - Mã ngắn: ví dụ `EC2`, `S3`, `RDS`.
  - Tên đầy đủ.
  - Nhóm/chức năng: ví dụ `Compute`, `Storage`, `Database`.
- Tab active phải nổi bật rõ.
- Không dùng quá nhiều text trong tab.

### 3.3 Content panel

Mỗi màn hoặc mỗi tab nên có các phần:

- Tên service/chủ đề.
- Mô tả ngắn 1-2 câu.
- Tags ngắn.
- Diagram/flow lớn.
- Steps/bước xử lý ở panel phụ 20%.
- Footer chứa log/rule/note quan trọng.
- Khi nào dùng, điểm mạnh, lưu ý vận hành, ví dụ thực tế: đưa vào footer, tab phụ, hoặc tài liệu `doc.md`/`QA.md` nếu dài.

### 3.4 Header full row

Header phải chiếm full row và chứa đủ ngữ cảnh để người xem không phải đoán:

- Title rõ chủ đề.
- Subtitle mô tả demo đang mô phỏng luồng nào.
- Badge/tag ngắn cho công nghệ hoặc mode chính.
- Legend/chú thích nếu diagram có mũi tên, màu, icon, vùng khoanh, nét liền/nét đứt.

Legend ưu tiên đặt trong header để người xem hiểu ký hiệu trước khi nhìn diagram.

### 3.5 Main row 80/20

Main row gồm 2 phần:

- Diagram/flow panel chiếm khoảng 80% chiều ngang.
- Steps/checklist panel chiếm khoảng 20% chiều ngang.

Diagram panel:

- Có toolbar nếu cần `Play`, `Prev`, `Next`, `Reset`, `Zoom`.
- Có vùng scroll ngang/dọc nếu diagram lớn.
- Có thể khoanh vùng hệ thống, ví dụ `Hệ thống hiện tại`, `Hệ thống MoMo`, `Hệ thống đối tác`, `Database nội bộ`.

Steps panel:

- Hiển thị danh sách bước ngắn, dễ scan.
- Step active phải nổi bật.
- Có thể click step để nhảy tới vị trí tương ứng trong flow.
- Nếu steps dài, panel steps được scroll riêng.

### 3.6 Footer full row

Footer phải chiếm full row và dùng cho thông tin phụ trợ:

- Log step hiện tại.
- Rule quan trọng.
- Cảnh báo vận hành.
- Checklist xác thực.
- Ghi chú như `redirectUrl chỉ để user quay lại`, `IPN mới là nguồn cập nhật trạng thái chuẩn`.

Không đặt footer quá cao khiến main row bị mất không gian. Footer nên ngắn, tập trung vào thông tin cần nhớ.

## 4. Diagram/flow rules

### 4.1 Diagram phải là phần trung tâm

- Diagram phải chiếm nhiều không gian nhất trong content.
- Không để diagram nhỏ hơn phần text giải thích.
- Nếu nhiều thành phần, thêm zoom.
- Nếu zoom lớn, vùng diagram được scroll.

### 4.2 Nên dùng SVG cho flow

- Ưu tiên SVG vì dễ vẽ node, line, arrow, scale.
- Dùng `viewBox` để diagram responsive.
- Dùng `marker` cho mũi tên.
- Dùng class cho node/flow để dễ đổi màu.

Ví dụ pattern:

```html
<svg class="diagram" viewBox="0 0 820 430">
  <defs>
    <marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5">
      <path d="M 0 0 L 10 5 L 0 10 z"></path>
    </marker>
  </defs>
  <g id="diagramLayer"></g>
</svg>
```

### 4.3 Node trong diagram

Mỗi node nên có:

- Icon hoặc badge nhận diện loại thành phần.
- Title: tên thành phần.
- Subtitle: vai trò ngắn.
- Màu viền phân nhóm.

Ví dụ:

```text
ALB
Load balancer
```

Icon rules:

- Không nên chỉ dựa vào màu để phân biệt thành phần.
- Mỗi node nên có một icon/badge nhỏ ở đầu node.
- Icon có thể là:
  - Inline SVG tự vẽ.
  - HTML/CSS shape.
  - Text badge ngắn như `EC2`, `S3`, `DB`, `IAM`, `NET`.
  - Font Awesome nếu file đã import sẵn và demo không cần chạy offline.
- Nếu dùng Font Awesome qua CDN, cần chấp nhận rằng demo phụ thuộc internet.
- Với project này, ưu tiên inline SVG/CSS hoặc text badge để file HTML chạy được offline.
- Màu chỉ là lớp hỗ trợ; icon + label mới là nhận diện chính.

Không nên:

- Nhét mô tả dài vào node.
- Để node đè lên nhau.
- Dùng font quá nhỏ.
- Dùng quá nhiều màu gây rối.
- Dùng màu làm tín hiệu duy nhất mà không có icon/label.

Khoảng cách node:

- Các node phải có khoảng cách đủ rộng để mũi tên không dính sát vào box.
- Với SVG flow ngang, nên để khoảng cách giữa cạnh phải node trước và cạnh trái node sau ít nhất `60-90px`.
- Nếu có nhiều node, ưu tiên tăng `viewBox` và cho diagram scroll/zoom thay vì ép node sát nhau.
- Node nên gọn vừa đủ; đừng làm box quá rộng khiến mũi tên bị ngắn và khó nhìn.

### 4.4 Flow line

- Flow chính nên nổi bật hơn flow phụ.
- Flow active hoặc quan trọng có thể dùng animation nhẹ.
- Mũi tên phải rõ chiều đi.
- Không để line cắt ngang text nếu tránh được.
- Mũi tên nên nhỏ và mảnh, không lấn át node.
- Stroke gợi ý:
  - Flow thường: `2px - 2.5px`.
  - Flow active/chính: có thể dùng màu nổi hơn nhưng không nên quá dày.
- Arrow marker nên nhỏ vừa phải, ví dụ `markerWidth="6"` và `markerHeight="6"` trong SVG.
- Nét đứt chỉ dùng khi có ý nghĩa rõ ràng, ví dụ luồng chính, traffic chính hoặc luồng đang active.
- Nét liền dùng cho kết nối phụ, đồng bộ, replication hoặc quan hệ hỗ trợ.
- Không trộn nét đứt/nét liền nếu không có legend giải thích.

### 4.5 Legend cho mũi tên và thành phần

Nếu diagram có nhiều loại line hoặc nhiều màu node, bắt buộc thêm legend gần diagram.

Legend nên giải thích:

- Nét đứt nghĩa là gì.
- Nét liền nghĩa là gì.
- Icon/badge đại diện cho nhóm nào.
- Màu node đại diện cho nhóm nào nếu có dùng màu.

Ví dụ:

```text
Nét đứt cam: luồng chính / traffic chính
Nét liền xám: kết nối phụ / đồng bộ / hỗ trợ
AWS badge: service trung tâm
NET badge: user/network entry
APP badge: application/compute
DB badge: database/data/security
```

Legend nên đặt ngay trên diagram hoặc trong toolbar của diagram, không để người xem phải kéo xuống mới hiểu ký hiệu.

## 5. Zoom rules

Nếu diagram có nhiều thành phần, bắt buộc nên có:

- Nút `+` để phóng to.
- Nút `-` để thu nhỏ.
- Nút `Reset` để về 100%.
- Label phần trăm zoom.

Vùng diagram nên dùng:

```css
.diagram-viewport {
  overflow: auto;
}
```

Không nên zoom bằng cách làm toàn bộ page phình ra. Chỉ zoom vùng diagram.

## 6. Nội dung text rules

### 6.1 Giải thích ngắn

- Mỗi section chỉ nên có ý chính.
- Nếu cần tài liệu dài, viết vào `QA.md` hoặc `doc.md`.
- Demo HTML chỉ nên giúp nhìn nhanh và hiểu flow.

### 6.2 Nên có 3 block nhỏ

Mỗi tab nên có:

- `Điểm mạnh`
- `Lưu ý vận hành`
- `Ví dụ thực tế`

Ba block này giúp màn hình mô phỏng vừa học được khái niệm, vừa biết áp dụng thực tế.

### 6.3 Thuật ngữ tiếng Anh

- Nếu dùng thuật ngữ tiếng Anh, nên có giải thích tiếng Việt cạnh bên nếu thuật ngữ khó.
- Ví dụ:
  - `Load Balancer`: bộ cân bằng tải.
  - `Auto Scaling`: tự tăng/giảm tài nguyên theo tải.
  - `Private subnet`: subnet không public trực tiếp ra internet.

## 7. Visual style rules

### 7.1 Màu sắc

Nên dùng nền sáng, sạch:

- Background: `#f5f7fb` hoặc tương đương.
- Panel: trắng.
- Border: xám nhạt.
- Text chính: xanh đen/xám đậm.
- Muted text: xám.

Màu phân nhóm:

- AWS/main: cam `#ff9900`.
- Compute/app: xanh lá.
- Network/user: xanh dương.
- Database/data: tím.
- Warning/error: đỏ/cam.

Không nên:

- Dùng nền quá tối cho toàn page nếu nội dung nhiều chữ.
- Dùng quá nhiều gradient.
- Dùng màu một tông duy nhất cho toàn màn hình.

### 7.2 Border radius

- Card, tab, node nên dùng `border-radius: 8px`.
- Không dùng bo góc quá lớn cho UI kỹ thuật.

### 7.3 Typography

- Font mặc định có thể dùng `"Segoe UI", Arial, sans-serif`.
- Title lớn vừa phải.
- Node text phải đọc được.
- Không scale font theo viewport quá mạnh.

## 8. Responsive rules

Demo phải xem được trên laptop và màn hình nhỏ.

Desktop:

- Sidebar trái, content phải.
- Diagram lớn.

Tablet/mobile:

- Sidebar chuyển thành grid hoặc stack.
- Content xếp dọc.
- Diagram vẫn có thể scroll/zoom.

CSS pattern:

```css
@media (max-width: 1080px) {
  .app {
    grid-template-columns: 1fr;
  }

  .tabs {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}
```

## 9. JavaScript rules

### 9.1 Data-driven UI

Nếu có nhiều tab, nên khai báo data array:

```js
const services = [
  {
    key: "ec2",
    short: "EC2",
    name: "EC2",
    group: "Compute",
    summary: "...",
    tags: ["Virtual machine"],
    useCases: ["..."],
    nodes: [...],
    flows: [...]
  }
];
```

Sau đó render UI từ data.

Lợi ích:

- Dễ thêm tab mới.
- Không copy HTML lặp lại.
- Dễ sửa nội dung.

### 9.2 Không phụ thuộc thư viện ngoài nếu không cần

- Demo nên chạy offline nếu có thể.
- Không bắt buộc CDN.
- Không cần framework nếu HTML/CSS/JS thuần đủ.

## 10. Checklist trước khi hoàn thành demo

Trước khi kết thúc một màn hình mô phỏng, kiểm tra:

- Có title và subtitle rõ chưa?
- Header có chiếm full row và chứa đủ mô tả + legend/chú thích chưa?
- Main row có chia khoảng `80% diagram / 20% steps` chưa?
- Footer có chiếm full row và chứa log/rule/note quan trọng chưa?
- Có tab/sidebar nếu nhiều mục chưa?
- Diagram có đủ lớn không?
- Diagram có zoom nếu nhiều thành phần không?
- Diagram có scroll ngang/dọc nếu canvas lớn hơn khung nhìn không?
- Nếu có nhiều hệ thống, đã khoanh vùng và ghi rõ tên từng hệ thống chưa?
- Node có bị đè nhau không?
- Khoảng cách giữa các node có đủ rộng để nhìn mũi tên không?
- Mũi tên có quá dày hoặc quá to không?
- Node có icon/badge nhận diện không, hay chỉ dựa vào màu?
- Có legend giải thích nét đứt/nét liền, icon/badge và màu node không?
- Text có quá dài trong node không?
- Có phần "Khi nào dùng" không?
- Có "Điểm mạnh / Lưu ý / Ví dụ thực tế" không?
- Mobile/tablet có layout ổn không?
- File đã được thêm vào `menu.md` chưa?
- Nếu có tài liệu dài, đã trỏ sang `QA.md` hoặc `doc.md` chưa?

## 11. Quy ước đặt file

Mỗi chủ đề nên có:

```text
topic/
  doc.md
  QA.md
  index.html
```

Trong đó:

- `doc.md`: ghi chú tổng quan.
- `QA.md`: câu hỏi và trả lời phỏng vấn.
- `index.html`: demo mô phỏng trực quan chính.

Nếu có nhiều demo:

```text
topic/
  index.html
  demo-cache.html
  demo-flow.html
```

Nhớ cập nhật `Task/sumolation/menu.md`.

## 12. Rule quan trọng nhất

Mỗi demo phải trả lời được câu hỏi:

```text
Người xem nhìn vào có hiểu luồng xử lý nhanh hơn so với chỉ đọc chữ không?
```

Nếu câu trả lời là không, demo đang bị sai hướng.

Ưu tiên:

- Flow rõ.
- Thành phần rõ.
- Tương tác vừa đủ.
- Text ngắn.
- Ví dụ thực tế.

Không ưu tiên:

- Trang trí nhiều.
- Animation phức tạp nhưng không giúp hiểu.
- Nhồi toàn bộ nội dung QA vào HTML.
