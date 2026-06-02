# SQL vs NoSQL QA

Tài liệu này dùng để trả lời phỏng vấn và phân tích kiến trúc khi nào nên dùng `SQL`, khi nào nên dùng `NoSQL`, ưu/nhược điểm, bài toán thực tế, và câu hỏi "cái nào nhanh hơn".

## Glossary thuật ngữ

| Thuật ngữ | Giải thích tiếng Việt |
|---|---|
| `SQL` | Ngôn ngữ truy vấn có cấu trúc, thường dùng với database quan hệ như PostgreSQL, MySQL. |
| `NoSQL` | Nhóm database không bắt buộc theo mô hình bảng quan hệ truyền thống. |
| `Relational database` | Database quan hệ, lưu dữ liệu bằng bảng và liên kết giữa các bảng. |
| `Table` | Bảng dữ liệu. Ví dụ bảng `users`, `orders`. |
| `Row` | Một dòng/bản ghi trong bảng. |
| `Column` | Một cột/thuộc tính trong bảng. |
| `Primary key` | Khóa chính, định danh duy nhất cho một record. |
| `Foreign key` | Khóa ngoại, dùng để liên kết record ở bảng này với bảng khác. |
| `Schema` | Cấu trúc dữ liệu: bảng nào, cột nào, kiểu dữ liệu gì, rule gì. |
| `Schema migration` | Quá trình thay đổi cấu trúc database, ví dụ thêm cột, sửa index, tạo bảng mới. |
| `Transaction` | Giao dịch dữ liệu, gom nhiều thao tác thành một đơn vị xử lý. |
| `ACID` | Bộ tính chất đảm bảo transaction đáng tin cậy: atomicity, consistency, isolation, durability. |
| `Atomicity` | Tính nguyên tử: hoặc thành công toàn bộ, hoặc rollback toàn bộ. |
| `Consistency` | Tính nhất quán: dữ liệu không vi phạm rule/ràng buộc sau khi ghi. |
| `Isolation` | Tính cô lập: các transaction chạy đồng thời không làm sai dữ liệu của nhau. |
| `Durability` | Tính bền vững: commit xong thì dữ liệu không mất dù hệ thống restart/crash. |
| `Join` | Phép nối dữ liệu giữa nhiều bảng. |
| `Query` | Câu truy vấn dữ liệu. |
| `Query pattern` | Mẫu truy vấn thường gặp của hệ thống, ví dụ đọc theo `user_id`, lọc theo ngày, tìm theo trạng thái. |
| `Index` | Chỉ mục giúp database tìm dữ liệu nhanh hơn. |
| `Aggregate` | Tổng hợp dữ liệu, ví dụ `COUNT`, `SUM`, `AVG`, `GROUP BY`. |
| `Report` | Báo cáo nghiệp vụ. |
| `BI` | Business Intelligence, hệ thống phân tích/báo cáo dữ liệu cho kinh doanh. |
| `Scale dọc` | Tăng tài nguyên cho một máy, ví dụ thêm CPU/RAM/disk. |
| `Scale ngang` | Tăng số lượng máy/node để chia tải. |
| `Partition` | Phân vùng dữ liệu. |
| `Partition key` | Khóa dùng để quyết định dữ liệu nằm ở phân vùng/node nào. |
| `Sharding` | Chia dữ liệu ra nhiều shard/node để scale ngang. |
| `Strong consistency` | Nhất quán mạnh: đọc sau khi ghi sẽ thấy dữ liệu mới nhất. |
| `Eventual consistency` | Nhất quán cuối cùng: dữ liệu có thể trễ một lúc, nhưng sau đó sẽ đồng bộ về trạng thái đúng. |
| `Denormalization` | Phi chuẩn hóa, cố ý duplicate dữ liệu để đọc nhanh hơn hoặc giảm join. |
| `Duplicate data` | Dữ liệu bị lặp ở nhiều nơi. |
| `Source of truth` | Nguồn dữ liệu chuẩn cuối cùng mà hệ thống tin cậy nhất. |
| `Document database` | Database lưu dữ liệu dạng document, thường giống JSON. Ví dụ MongoDB. |
| `Key-value store` | Database lưu theo cặp khóa-giá trị. Ví dụ Redis. |
| `Wide-column` | Database lưu dữ liệu theo cột rộng, phù hợp dữ liệu lớn và ghi nhiều. Ví dụ Cassandra. |
| `Graph database` | Database lưu node và quan hệ giữa node. Ví dụ Neo4j. |
| `Search engine` | Hệ thống tìm kiếm/index dữ liệu text. Ví dụ Elasticsearch/OpenSearch. |
| `Full-text search` | Tìm kiếm toàn văn, hỗ trợ tìm theo từ khóa trong nội dung text. |
| `CDC` | Change Data Capture, cơ chế bắt thay đổi dữ liệu để đồng bộ sang hệ khác. |
| `ETL` | Extract, Transform, Load: lấy dữ liệu, biến đổi dữ liệu, nạp vào hệ thống khác. |
| `Data warehouse` | Kho dữ liệu phục vụ phân tích/báo cáo lớn. |
| `Throughput` | Lưu lượng xử lý, ví dụ số request/command ghi mỗi giây. |
| `Latency` | Độ trễ, thời gian phản hồi của một request/query. |
| `RPO` | Recovery Point Objective, mức dữ liệu tối đa chấp nhận mất khi sự cố. |
| `RTO` | Recovery Time Objective, thời gian tối đa chấp nhận để khôi phục hệ thống. |

## Kết luận nhanh

- Không có câu trả lời tuyệt đối rằng `SQL` hay `NoSQL` luôn nhanh hơn.
- `SQL` thường mạnh khi:
  - Dữ liệu có quan hệ rõ ràng.
  - Cần transaction (giao dịch dữ liệu) chặt chẽ.
  - Cần join (nối bảng), query (truy vấn) linh hoạt, báo cáo.
  - Cần đảm bảo tính đúng đắn dữ liệu cao.
- `NoSQL` thường mạnh khi:
  - Dữ liệu lớn, schema (cấu trúc dữ liệu) thay đổi nhanh.
  - Cần scale ngang (tăng số node/máy để chia tải) mạnh.
  - Query pattern (mẫu truy vấn thường gặp) đơn giản và biết trước.
  - Chấp nhận denormalization (phi chuẩn hóa/duplicate dữ liệu để đọc nhanh) hoặc eventual consistency (nhất quán cuối cùng, có thể trễ đồng bộ).
- Database nhanh hay chậm phụ thuộc vào:
  - Data model (mô hình dữ liệu).
  - Index (chỉ mục).
  - Query pattern (mẫu truy vấn).
  - Khối lượng dữ liệu.
  - Cách scale (mở rộng hệ thống).
  - Consistency requirement (yêu cầu nhất quán dữ liệu).
  - Hardware và network (phần cứng và mạng).

## SQL là gì?

- `SQL database` là database quan hệ.
- Dữ liệu thường được lưu trong table (bảng), row (dòng/bản ghi), column (cột/thuộc tính).
- Các table có thể liên kết qua khóa chính và khóa ngoại.
- Ví dụ:
  - PostgreSQL.
  - MySQL.
  - SQL Server.
  - Oracle.

## NoSQL là gì?

- `NoSQL` là nhóm database không bắt buộc theo mô hình quan hệ truyền thống.
- Có nhiều loại NoSQL:
  - Document database (database lưu document dạng JSON-like): MongoDB, CouchDB.
  - Key-value store (lưu theo cặp khóa-giá trị): Redis, DynamoDB.
  - Wide-column (database dạng cột rộng, tối ưu dữ liệu lớn): Cassandra, HBase.
  - Graph database (database node và quan hệ): Neo4j.
  - Search engine/document index (hệ thống index/tìm kiếm tài liệu): Elasticsearch, OpenSearch.

## Bảng so sánh SQL và NoSQL

| Tiêu chí | SQL | NoSQL |
|---|---|---|
| Mô hình dữ liệu | Table/row/column (bảng/dòng/cột), quan hệ rõ ràng | Document/key-value/wide-column/graph (tài liệu/khóa-giá trị/cột rộng/đồ thị) |
| Schema | Chặt chẽ, cần định nghĩa trước cấu trúc dữ liệu | Linh hoạt hơn, dễ thay đổi cấu trúc |
| Transaction | Mạnh, thường hỗ trợ ACID tốt | Tùy loại, có thể yếu hơn hoặc giới hạn theo item/document/partition |
| Join | Rất mạnh, dễ nối dữ liệu nhiều bảng | Thường hạn chế hoặc không khuyến khích |
| Query phức tạp | Tốt cho filter (lọc), join (nối), aggregate (tổng hợp), report (báo cáo) | Tốt nếu query pattern (mẫu truy vấn) được thiết kế trước |
| Scale | Scale dọc dễ hơn, scale ngang phức tạp hơn | Thường sinh ra để scale ngang tốt |
| Consistency | Thường strong consistency (nhất quán mạnh) | Có thể strong consistency hoặc eventual consistency tùy hệ |
| Dữ liệu quan hệ | Rất phù hợp | Thường phải denormalize hoặc duplicate data |
| Dữ liệu thay đổi schema nhanh | Có thể khó hơn vì migration (thay đổi cấu trúc DB) | Phù hợp hơn |
| Reporting/BI | Tốt cho báo cáo/phân tích nghiệp vụ | Thường cần ETL sang hệ khác |
| Tốc độ đọc theo key | Tốt nếu có index | Rất tốt với key-value/document lookup |
| Tốc độ ghi lớn | Tốt nhưng cần tuning (tối ưu cấu hình/index/query) | Nhiều NoSQL tối ưu cho write throughput lớn |
| Ví dụ bài toán | Order, payment, user, inventory | Log, event, cache, feed, IoT, catalog linh hoạt |

## Khi nào nên dùng SQL?

### 1. Dữ liệu có quan hệ rõ ràng

- Dùng SQL khi các entity (thực thể nghiệp vụ như user, order, payment) liên kết chặt với nhau.
- Ví dụ:
  - User có nhiều order.
  - Order có nhiều order item.
  - Product thuộc category.
  - Payment gắn với order.

**Vì sao SQL phù hợp**

- Có khóa ngoại để đảm bảo toàn vẹn dữ liệu.
- Join giúp truy vấn quan hệ tự nhiên.
- Transaction (giao dịch dữ liệu) giúp nhiều thay đổi cùng thành công hoặc cùng rollback (hoàn tác).

**Ví dụ thực tế**

- Hệ thống ecommerce:
  - `users`
  - `orders`
  - `order_items`
  - `payments`
  - `shipments`
- Khi tạo đơn hàng:
  - Trừ tồn kho.
  - Tạo order.
  - Tạo order item.
  - Ghi payment pending.
  - Tất cả nên nằm trong transaction (giao dịch dữ liệu) hoặc workflow (luồng xử lý nghiệp vụ) nhất quán.

**Ưu điểm**

- Dữ liệu đúng và nhất quán hơn.
- Query linh hoạt.
- Dễ làm report nghiệp vụ.
- Có chuẩn SQL phổ biến, dễ tuyển người.

**Nhược điểm**

- Schema migration (thay đổi cấu trúc database) cần quản lý kỹ.
- Scale ngang phức tạp hơn NoSQL.
- Join (nối bảng) nhiều trên dữ liệu rất lớn có thể chậm nếu index/model (chỉ mục/mô hình dữ liệu) không tốt.

**Hướng xử lý**

- Thiết kế index (chỉ mục) theo query (truy vấn) thực tế.
- Dùng migration tool (công cụ quản lý thay đổi database) như Flyway/Liquibase.
- Tách read/write nếu cần.
- Dùng read replica (bản sao chỉ đọc) cho report/read-heavy (báo cáo hoặc hệ thống đọc nhiều).
- Với dữ liệu cực lớn, cân nhắc partitioning/sharding (phân vùng/chia dữ liệu ra nhiều shard).

### 2. Cần transaction ACID

- Dùng SQL khi dữ liệu yêu cầu:
  - Atomicity (tính nguyên tử): hoặc thành công hết, hoặc rollback hết.
  - Consistency (tính nhất quán): dữ liệu không vi phạm rule.
  - Isolation (tính cô lập): transaction không làm bẩn nhau.
  - Durability (tính bền vững): commit rồi thì phải bền vững.

**Ví dụ thực tế**

- Chuyển tiền:
  - Trừ tiền tài khoản A.
  - Cộng tiền tài khoản B.
  - Ghi transaction log (nhật ký giao dịch).
  - Không được xảy ra case trừ A nhưng chưa cộng B.

**Ưu điểm**

- Phù hợp dữ liệu tài chính, đơn hàng, inventory.
- Dễ enforce constraint (áp ràng buộc dữ liệu).
- Ít phải tự code logic đảm bảo consistency (tính nhất quán).

**Nhược điểm**

- Transaction mạnh có thể làm giảm throughput (lưu lượng xử lý).
- Lock contention (tranh chấp khóa) nếu nhiều request ghi cùng record (bản ghi).

**Hướng xử lý**

- Giữ transaction ngắn.
- Index đúng cột dùng trong `WHERE`.
- Tránh update nhiều row không cần thiết.
- Dùng optimistic locking (khóa lạc quan, kiểm tra version khi update) cho nghiệp vụ phù hợp.
- Dùng queue/event (hàng đợi/sự kiện) cho tác vụ không cần nằm trong transaction chính.

### 3. Cần query linh hoạt và báo cáo

- SQL tốt khi business thường hỏi dữ liệu theo nhiều chiều khác nhau.
- Ví dụ:
  - Doanh thu theo ngày/tháng.
  - Top sản phẩm bán chạy.
  - Tỷ lệ hủy đơn theo khu vực.
  - Số đơn hàng theo trạng thái.

**Ưu điểm**

- `JOIN`, `GROUP BY`, `HAVING`, window function (hàm phân tích theo cửa sổ) rất mạnh.
- Dễ kết nối BI/reporting tool (công cụ báo cáo/phân tích).
- Dễ viết ad-hoc query (truy vấn phát sinh theo nhu cầu).

**Nhược điểm**

- Query report nặng có thể ảnh hưởng production database.
- Aggregate (tổng hợp dữ liệu) lớn cần tối ưu.

**Hướng xử lý**

- Dùng read replica (bản sao chỉ đọc) cho reporting (báo cáo).
- Tạo materialized view (view lưu sẵn kết quả) hoặc summary table (bảng tổng hợp).
- ETL sang data warehouse (kho dữ liệu phân tích) nếu report lớn.
- Không chạy report nặng trực tiếp trên primary database.

## Khi nào nên dùng NoSQL?

### 1. Dữ liệu schema linh hoạt hoặc thay đổi nhanh

- Dùng NoSQL document (database lưu dữ liệu dạng tài liệu/JSON) khi cấu trúc dữ liệu thay đổi thường xuyên.
- Ví dụ:
  - Product catalog (danh mục sản phẩm) có nhiều loại sản phẩm với thuộc tính khác nhau.
  - Form động.
  - User profile có nhiều field optional.

**Ví dụ thực tế**

- Ecommerce product catalog:
  - Áo có `size`, `color`, `material`.
  - Laptop có `cpu`, `ram`, `storage`.
  - Sách có `author`, `publisher`, `isbn`.
- Nếu ép tất cả vào SQL, table (bảng) có thể rất nhiều nullable column (cột cho phép null) hoặc phải tạo nhiều table phụ.

**Ưu điểm**

- Thêm field mới dễ hơn.
- Document (tài liệu JSON-like) chứa dữ liệu gần với object trong application (đối tượng trong code).
- Đọc một document có thể lấy đủ thông tin cần hiển thị.

**Nhược điểm**

- Dễ thiếu chuẩn nếu team không quản lý schema ở application.
- Dữ liệu duplicate (lặp lại ở nhiều nơi) nhiều hơn.
- Update field chung trên nhiều document có thể khó.

**Hướng xử lý**

- Dù NoSQL linh hoạt, vẫn nên có schema convention (quy ước cấu trúc dữ liệu).
- Validate input ở application layer (kiểm tra dữ liệu đầu vào ở tầng ứng dụng).
- Thiết kế document theo màn hình/query cần đọc.
- Có version field (trường phiên bản) nếu schema thay đổi nhiều.

### 2. Cần scale ngang và throughput lớn

- Dùng NoSQL khi cần xử lý lượng ghi/đọc cực lớn và dễ chia dữ liệu theo partition key (khóa phân vùng).
- Ví dụ:
  - Event tracking (ghi nhận hành vi/sự kiện).
  - IoT telemetry (dữ liệu thiết bị gửi về).
  - Clickstream (luồng click của người dùng).
  - Log ingestion (nạp log vào hệ thống).

**Ví dụ thực tế**

- Hệ thống ghi log hành vi người dùng:
  - Mỗi ngày hàng trăm triệu event.
  - Query (truy vấn) chủ yếu theo `user_id`, `event_time`, hoặc `device_id`.
  - Dữ liệu append-only (chỉ ghi thêm), ít update.
- Wide-column (database cột rộng) hoặc event storage (kho lưu sự kiện) có thể phù hợp hơn SQL truyền thống.

**Ưu điểm**

- Scale ngang tốt.
- Ghi dữ liệu lớn hiệu quả.
- Có thể tối ưu theo access pattern (cách truy cập dữ liệu thường gặp) cụ thể.

**Nhược điểm**

- Query linh hoạt kém hơn SQL.
- Join gần như không nên dùng.
- Cần chọn partition key (khóa phân vùng) rất cẩn thận.
- Consistency (tính nhất quán) có thể không mạnh bằng SQL.

**Hướng xử lý**

- Xác định query pattern (mẫu truy vấn) trước khi thiết kế schema.
- Chọn partition key tránh hot partition (phân vùng bị quá tải).
- Chấp nhận denormalization (phi chuẩn hóa/duplicate dữ liệu để đọc nhanh).
- Dùng pipeline ETL (luồng lấy, biến đổi, nạp dữ liệu) để đưa dữ liệu sang warehouse nếu cần phân tích sâu.

### 3. Cần truy xuất cực nhanh theo key

- Dùng key-value NoSQL (database khóa-giá trị) khi cần lấy dữ liệu bằng key đơn giản.
- Ví dụ:
  - Cache session.
  - Token.
  - Rate limit counter (bộ đếm giới hạn số request).
  - Feature flag (cờ bật/tắt tính năng).

**Ví dụ thực tế**

- Redis lưu session:
  - Key: `session:{token}`
  - Value: user id, role, expiry.
  - Query (truy vấn) chỉ là `GET session:{token}`.

**Ưu điểm**

- Rất nhanh cho key lookup.
- Cấu trúc đơn giản.
- Phù hợp cache và state tạm.

**Nhược điểm**

- Không phù hợp query phức tạp.
- Không nên dùng làm source of truth (nguồn dữ liệu chuẩn cuối cùng) duy nhất cho dữ liệu quan trọng nếu không thiết kế persistence/backup (lưu bền vững/sao lưu) kỹ.

**Hướng xử lý**

- Dùng TTL (thời gian sống của key) cho dữ liệu tạm.
- Dữ liệu quan trọng vẫn nên lưu trong database bền vững.
- Dùng Redis làm cache/read model (mô hình dữ liệu phục vụ đọc), không thay thế SQL cho transaction quan trọng.

### 4. Cần tìm kiếm full-text

- Dùng Elasticsearch/OpenSearch khi cần search text mạnh.
- Ví dụ:
  - Search sản phẩm.
  - Search bài viết.
  - Filter (lọc) nhiều điều kiện.
  - Autocomplete (gợi ý tự động khi gõ).

**Ưu điểm**

- Full-text search (tìm kiếm toàn văn) tốt.
- Ranking (xếp hạng kết quả), tokenizer (tách từ), fuzzy search (tìm gần đúng), autocomplete (gợi ý tự động).
- Filter và aggregate search (lọc và tổng hợp trên kết quả tìm kiếm) nhanh nếu index đúng.

**Nhược điểm**

- Không nên làm source of truth (nguồn dữ liệu chuẩn) chính.
- Dữ liệu thường sync (đồng bộ) từ SQL/NoSQL khác sang.
- Có độ trễ đồng bộ.

**Hướng xử lý**

- SQL giữ dữ liệu gốc.
- Elasticsearch làm search index (chỉ mục tìm kiếm).
- Dùng event hoặc CDC (Change Data Capture - bắt thay đổi dữ liệu) để sync dữ liệu.
- Có job rebuild index (tác vụ xây lại chỉ mục) khi cần.

### 5. Cần lưu quan hệ dạng graph

- Dùng graph database (database đồ thị) khi quan hệ giữa node (đỉnh/thực thể) quan trọng hơn bản thân record.
- Ví dụ:
  - Social network (mạng xã hội).
  - Recommendation (gợi ý).
  - Fraud detection (phát hiện gian lận).
  - Permission graph (mô hình quyền dạng đồ thị).

**Ưu điểm**

- Truy vấn quan hệ nhiều bước tốt.
- Dễ biểu diễn node-edge (đỉnh và cạnh/quan hệ).
- Tốt cho bài toán đường đi, liên kết, network.

**Nhược điểm**

- Không thay thế SQL cho transaction nghiệp vụ thông thường.
- Cần học query language (ngôn ngữ truy vấn) và mô hình graph.

**Hướng xử lý**

- Dùng graph database cho phần relationship-heavy (nặng về quan hệ nhiều bước).
- Dữ liệu nghiệp vụ chính vẫn có thể nằm ở SQL.
- Đồng bộ graph từ event/domain data (sự kiện/dữ liệu nghiệp vụ).

## SQL hay NoSQL cái nào nhanh hơn?

### Câu trả lời đúng khi phỏng vấn

- Không nên trả lời "NoSQL luôn nhanh hơn SQL" hoặc "SQL luôn tốt hơn NoSQL".
- Cái nhanh hơn là cái được chọn đúng cho query pattern (mẫu truy vấn) và được thiết kế đúng.

### Trường hợp SQL có thể nhanh hơn

- Query cần join (nối) nhiều table (bảng) có index (chỉ mục) tốt.
- Query cần aggregate/report (tổng hợp/báo cáo) phức tạp.
- Dataset (tập dữ liệu) vừa phải, schema rõ.
- Cần filter (lọc) theo nhiều điều kiện linh hoạt.

**Ví dụ**

- Lấy doanh thu theo tháng, theo category, theo khu vực:
  - SQL có thể xử lý tốt bằng join, group by, index, materialized view (view lưu sẵn kết quả).
  - NoSQL nếu không thiết kế trước query này có thể phải scan (quét) nhiều document hoặc dùng pipeline (luồng xử lý) phức tạp.

### Trường hợp NoSQL có thể nhanh hơn

- Lookup (tra cứu) theo key/document id.
- Ghi event/log với throughput (lưu lượng xử lý) rất lớn.
- Read (đọc) một document đã denormalize (phi chuẩn hóa) đầy đủ dữ liệu.
- Cache dữ liệu tạm trong memory (bộ nhớ RAM) như Redis.

**Ví dụ**

- Lấy session theo token:
  - Redis `GET session:{token}` thường nhanh hơn query SQL.
- Lấy product detail document:
  - MongoDB có thể trả về một document (tài liệu JSON-like) đầy đủ nhanh nếu document đã chứa data cần hiển thị.

### Điểm cần nhớ

- SQL nhanh nếu query được index (đánh chỉ mục) tốt và dữ liệu quan hệ.
- NoSQL nhanh nếu access pattern (cách truy cập dữ liệu) đơn giản, được denormalize đúng và partition tốt.
- SQL chậm nếu query join/aggregate (nối bảng/tổng hợp) lớn không có index.
- NoSQL chậm nếu query không theo partition/index hoặc phải scan nhiều record.

## Bài toán thực tế nên chọn gì?

| Bài toán | Nên dùng | Lý do |
|---|---|---|
| Order, payment, invoice | SQL | Cần transaction (giao dịch), consistency (nhất quán), constraint (ràng buộc) |
| Banking, wallet, balance | SQL | Không được sai lệch dữ liệu |
| Inventory | SQL hoặc SQL + cache | Cần kiểm soát tồn kho chính xác |
| Product catalog schema linh hoạt | NoSQL document hoặc SQL + JSONB | Thuộc tính sản phẩm thay đổi theo loại |
| User profile nhiều field optional | NoSQL document hoặc SQL | Tùy mức quan hệ và query |
| Session/token | NoSQL key-value, Redis | Lookup theo key, TTL (thời gian sống) |
| Cache API response | Redis/Memcached | Truy xuất nhanh, dữ liệu tạm |
| Event tracking/clickstream | NoSQL wide-column/event store | Ghi lớn, append-only (chỉ ghi thêm) |
| Log search | Elasticsearch/OpenSearch | Full-text search (tìm toàn văn) và filter log |
| Reporting tài chính | SQL/Data warehouse | Aggregate, accuracy, BI (tổng hợp, độ chính xác, báo cáo) |
| Chat message | NoSQL hoặc SQL tùy scale | Query theo conversation/time, ghi nhiều |
| Social graph/friend relation | Graph DB hoặc SQL tùy độ phức tạp | Quan hệ nhiều bước |
| Recommendation | Graph/NoSQL + analytics | Cần xử lý relationship/event lớn |

## Ví dụ thiết kế hệ thống ecommerce thực tế

### Nên dùng nhiều loại database cùng lúc

- SQL:
  - `users`
  - `orders`
  - `payments`
  - `inventory`
  - `invoices`
- Redis:
  - session.
  - cache product hot (cache sản phẩm truy cập nhiều).
  - rate limit (giới hạn số request).
  - distributed lock (khóa phân tán) ngắn hạn.
- MongoDB hoặc PostgreSQL JSONB:
  - product attributes (thuộc tính sản phẩm) linh hoạt.
- Elasticsearch:
  - search product (tìm kiếm sản phẩm).
  - autocomplete (gợi ý khi gõ).
  - filter theo keyword/category/price (lọc theo từ khóa/danh mục/giá).
- Kafka/event store:
  - tracking user behavior (theo dõi hành vi người dùng).
  - async update search index (cập nhật chỉ mục tìm kiếm bất đồng bộ).
  - analytics pipeline (luồng xử lý phân tích dữ liệu).

### Vì sao không dùng một database cho tất cả?

- SQL tốt cho transaction (giao dịch dữ liệu) nhưng không phải lựa chọn tốt nhất cho full-text search (tìm kiếm toàn văn).
- Redis rất nhanh nhưng không phù hợp làm database chính cho order/payment.
- Elasticsearch search tốt nhưng không nên làm source of truth (nguồn dữ liệu chuẩn).
- NoSQL document linh hoạt nhưng không tốt bằng SQL cho transaction nhiều bảng.

## Cách quyết định chọn SQL hay NoSQL

### Câu hỏi cần hỏi trước khi chọn

- Dữ liệu có quan hệ chặt không?
- Có cần transaction ACID không?
- Query pattern đã biết trước hay thay đổi liên tục?
- Cần join/report nhiều không?
- Cần scale ngang đến mức nào?
- Dữ liệu có schema (cấu trúc dữ liệu) ổn định hay thay đổi nhanh?
- RPO/RTO và consistency requirement (yêu cầu mất dữ liệu/khôi phục/nhất quán) là gì?
- Dữ liệu có phải source of truth (nguồn dữ liệu chuẩn) không?
- Team có kinh nghiệm vận hành loại database đó không?

### Rule of thumb

- Nếu chưa rõ chọn gì, bắt đầu với SQL là lựa chọn an toàn cho business data.
- Dùng NoSQL khi có lý do rõ ràng:
  - Scale ngang rất lớn.
  - Schema cực kỳ linh hoạt.
  - Query theo key/document đơn giản.
  - Search/graph/log/event (tìm kiếm/đồ thị/log/sự kiện) chuyên biệt.
- Đừng chọn NoSQL chỉ vì nghĩ nó "nhanh hơn".
- Đừng dùng SQL cho mọi thứ nếu bài toán cần search, cache, event ingestion cực lớn.

## Ưu và nhược điểm tổng hợp

### SQL

**Ưu điểm**

- ACID transaction (giao dịch ACID) mạnh.
- Quan hệ dữ liệu rõ ràng.
- Join và query (nối bảng và truy vấn) linh hoạt.
- Constraint (ràng buộc dữ liệu) giúp bảo vệ dữ liệu.
- Phù hợp nghiệp vụ quan trọng.
- Dễ làm report và BI.

**Nhược điểm**

- Schema migration (thay đổi cấu trúc database) cần kiểm soát.
- Scale ngang khó hơn.
- Query phức tạp có thể chậm nếu index kém.
- Transaction/lock (giao dịch/khóa dữ liệu) có thể gây bottleneck (điểm nghẽn) khi ghi nhiều.

**Hướng xử lý**

- Thiết kế schema rõ.
- Index theo query thực tế.
- Dùng migration tool.
- Dùng read replica, partition, materialized view (bản sao đọc, phân vùng, view lưu sẵn kết quả).
- Tách workload report khỏi primary (khối lượng báo cáo khỏi database chính).

### NoSQL

**Ưu điểm**

- Schema linh hoạt.
- Scale ngang tốt với nhiều loại NoSQL.
- Tối ưu tốt cho access pattern (cách truy cập dữ liệu) cụ thể.
- Key lookup/document lookup (tra cứu theo key/document) rất nhanh.
- Phù hợp dữ liệu lớn, event/log/cache/search/graph.

**Nhược điểm**

- Không phải loại nào cũng hỗ trợ transaction (giao dịch dữ liệu) mạnh.
- Query linh hoạt kém hơn SQL nếu không thiết kế trước.
- Dễ duplicate data (lặp dữ liệu).
- Consistency (tính nhất quán) có thể phức tạp.
- Cần hiểu rõ partition key, index, data model (khóa phân vùng, chỉ mục, mô hình dữ liệu).

**Hướng xử lý**

- Thiết kế theo query pattern (mẫu truy vấn).
- Denormalize (phi chuẩn hóa/duplicate dữ liệu) có kiểm soát.
- Chọn partition key (khóa phân vùng) cẩn thận.
- Có schema validation (kiểm tra cấu trúc dữ liệu) ở application.
- Không dùng làm source of truth cho dữ liệu cần ACID nếu database đó không phù hợp.

## Câu trả lời mẫu khi đi phỏng vấn

- "Em sẽ chọn SQL nếu dữ liệu có quan hệ rõ ràng, cần transaction (giao dịch) và consistency (nhất quán) mạnh, ví dụ order, payment, inventory."
- "Em sẽ chọn NoSQL nếu bài toán cần scale ngang (tăng node để chia tải) lớn, schema (cấu trúc dữ liệu) linh hoạt, hoặc access pattern (cách truy cập dữ liệu) đơn giản như key-value/session/cache/event log."
- "Về tốc độ, không thể nói SQL hay NoSQL luôn nhanh hơn. SQL nhanh cho query quan hệ và report nếu index tốt. NoSQL nhanh cho key lookup, document lookup hoặc write throughput lớn nếu thiết kế đúng partition/index."
- "Trong hệ thống thực tế, thường không chọn một loại database cho tất cả. Ví dụ ecommerce có thể dùng SQL cho order/payment, Redis cho cache/session, Elasticsearch cho search, và Kafka/event store cho tracking."
