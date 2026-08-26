TypeScript sinh ra chính là để giải quyết điểm yếu "không rõ ràng về kiểu dữ liệu" của JavaScript. Bằng cách ép kiểu chặt chẽ, nó giúp bạn bắt lỗi ngay lúc đang gõ code thay vì đợi đến khi chạy ứng dụng mới "vỡ lở".

Dưới đây là cú pháp và danh sách các kiểu dữ liệu từ cơ bản đến nâng cao trong một file `.ts`.

### 1. Cú pháp khai báo cơ bản

Cấu trúc chung để khai báo biến trong TypeScript là đặt dấu hai chấm `:` sau tên biến, tiếp theo là kiểu dữ liệu:

```typescript
let tên_biến: Kiểu_dữ_liệu = Giá_trị;
const hằng_số: Kiểu_dữ_liệu = Giá_trị;

```

### 2. Các kiểu dữ liệu có sẵn (Built-in Types)

#### Nhóm cơ bản (Primitives)

Đây là những kiểu dữ liệu nền tảng nhất:

* **`string`**: Chuỗi văn bản.
* **`number`**: Số (bao gồm cả số nguyên, số thập phân, số âm).
* **`boolean`**: Đúng hoặc sai (`true` / `false`).

```typescript
let fullName: string = "Nguyen Van A";
let age: number = 25;
let isDev: boolean = true;

```

#### Nhóm Mảng và Tập hợp

* **`Array`**: Mảng chứa các phần tử cùng một kiểu. Có 2 cách khai báo:
* Cách 1: `Kiểu[]` (Phổ biến hơn).
* Cách 2: `Array<Kiểu>` (Generic type).


* **`Tuple`**: Một mảng có **số lượng phần tử cố định** và **biết trước kiểu** của từng vị trí (Rất hay dùng khi viết hàm trả về nhiều giá trị).

```typescript
// Array
let scores: number[] = [8, 9, 10];
let roles: Array<string> = ["Admin", "User"];

// Tuple: Phần tử 1 bắt buộc là string, phần tử 2 bắt buộc là number
let httpResponse: [string, number] = ["OK", 200]; 

```

#### Nhóm Đặc biệt

* **`any`**: Tắt tính năng kiểm tra kiểu của TypeScript (Biến thành JavaScript thuần). **Cực kỳ hạn chế dùng** trừ khi bạn đang migrate code từ JS sang TS hoặc không thể biết trước cục data từ API trả về có hình thù gì.
* **`unknown`**: Giống `any` nhưng "an toàn hơn". Bạn có thể gán mọi thứ cho biến `unknown`, nhưng để sử dụng nó, bạn bắt buộc phải check kiểu trước.
* **`void`**: Dùng cho các hàm không trả về (return) bất kỳ giá trị nào.
* **`null` & `undefined**`: Trạng thái không có giá trị hoặc chưa được gán giá trị.

```typescript
let data: any = "Lúc là chuỗi";
data = 123; // Vẫn hợp lệ, TS không báo lỗi

function logMessage(msg: string): void {
  console.log(msg);
  // Không có lệnh return
}

```

### 3. Các kiểu dữ liệu Nâng cao (Advanced Types)

Sức mạnh thực sự của TypeScript nằm ở đây, cho phép bạn tự nhào nặn ra các kiểu dữ liệu phức tạp.

#### Union Type (Kiểu Kết hợp)

Cho phép một biến có thể nhận **một trong nhiều** kiểu khác nhau (dùng dấu `|`).

```typescript
// ID có thể là số hoặc chuỗi
let userId: string | number;
userId = 101; // Hợp lệ
userId = "USER_101"; // Hợp lệ

```

#### Khai báo Object (Interface & Type Alias)

Khi làm việc với các object phức tạp (như payload API gửi lên), bạn hiếm khi định nghĩa trực tiếp mà sẽ tạo ra một bộ "khuôn" (schema) bằng từ khóa `interface` hoặc `type`.

```typescript
// Tạo ra một kiểu dữ liệu mới tên là User
interface User {
  id: number;
  username: string;
  email?: string; // Dấu ? nghĩa là thuộc tính này có cũng được, không có cũng không sao (Optional)
}

// Sử dụng kiểu User vừa tạo
let currentUser: User = {
  id: 1,
  username: "khachhang",
  // Không có email vẫn không báo lỗi vì có dấu ?
};

```

> **Mẹo nhỏ:** TypeScript rất thông minh. Nhờ tính năng **Type Inference (Suy luận kiểu)**, nếu bạn khai báo `let age = 25;` (không ghi `: number`), TS vẫn tự hiểu biến `age` mang kiểu số, và nếu bạn gán chữ vào sẽ lập tức báo lỗi.