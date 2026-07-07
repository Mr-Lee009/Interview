# LỘ TRÌNH HỌC REACTJS CHI TIẾT - 30 NGÀY

## 1) Mục tiêu sau 30 ngày

- Hiểu được React từ cơ bản đến trung cấp.
- Tự xây dựng được 3 dự án thực tế:
	- Todo App (cơ bản)
	- Product Dashboard (API + state management)
	- Mini E-commerce Frontend (routing + cart + auth mock)
- Viết component theo hướng tái sử dụng, dễ maintain.
- Biết cách test, optimize và deploy lên Vercel.

---

## 2) Cách học mỗi ngày (khuyến nghị)

- Tổng thời gian: 2-3 giờ/ngày.
- Cấu trúc 1 buổi học:
	- 30 phút: học lý thuyết
	- 60-90 phút: code theo bài
	- 30 phút: tự làm lại không nhìn tài liệu
	- 10 phút: ghi note "hôm nay học được gì"

---

## 3) Chuẩn bị trước khi vào React (Day 0)

- Cài đặt công cụ:
	- Node.js LTS
	- VS Code + extensions (ESLint, Prettier)
	- Git + GitHub
- Ôn nhanh JavaScript cần thiết:
	- let/const, arrow function, destructuring
	- map/filter/reduce
	- Promise, async/await
	- import/export modules

Checklist Day 0:
- Tạo repo GitHub: react-30days
- Tạo folder monorepo học tập: react-30days
- Cấu hình Prettier + ESLint cơ bản

---

## 4) Lộ trình học ReactJS Step by Step theo giai đoạn

## Giai đoạn 1 - Nền tảng (Ngày 1-7)

Mục tiêu:
- Hiểu JSX, component, props, state, event.
- Tạo được app React có cấu trúc rõ ràng.

Bạn phải làm được:
- Viết functional component thuần
- Truyền props 1 chiều
- Quản lý state với useState
- Render list + key
- Form control cơ bản

## Giai đoạn 2 - React core nâng cao (Ngày 8-14)

Mục tiêu:
- Nắm vững lifecycle trong function component thông qua useEffect.
- Biết custom hooks và tối ưu render cơ bản.

Bạn phải làm được:
- Gọi API với fetch/axios
- Xử lý loading/error/data state
- Viết custom hook (vd: useFetch)
- Dùng useMemo/useCallback đúng chỗ

## Giai đoạn 3 - Hệ sinh thái React (Ngày 15-21)

Mục tiêu:
- Học React Router, state management, styling, form nâng cao.

Bạn phải làm được:
- Điều hướng đa trang với React Router
- Dùng Context API hoặc Redux Toolkit căn bản
- Dùng form validation với React Hook Form + Zod/Yup
- Tách module theo feature

## Giai đoạn 4 - Dự án + Production mindset (Ngày 22-30)

Mục tiêu:
- Hoàn thiện dự án theo quy trình gần thực tế.
- Test, optimize và deploy.

Bạn phải làm được:
- Viết test cơ bản (Jest + React Testing Library)
- Optimize (memoization, lazy loading)
- Deploy Vercel
- Viết README rõ ràng cho dự án

---

## 5) Lịch học cụ thể 30 ngày (Day by Day)

## Tuần 1 - React căn bản

### Day 1: React là gì + setup môi trường
- Học:
	- React, Virtual DOM, SPA vs MPA
	- Tạo project với Vite
- Thực hành:
	- npm create vite@latest react-day1 -- --template react
	- Chạy app, đổi title, đổi layout
- Bài tập:
	- Tạo trang profile đơn giản (avatar, tên, mô tả)

### Day 2: JSX và component
- Học:
	- JSX syntax, expression, fragment
	- Functional component
- Thực hành:
	- Tách UI thành Header, Sidebar, Content
- Bài tập:
	- Tạo 5 component card khác nhau

### Day 3: Props và component reusability
- Học:
	- Props, default props, children
- Thực hành:
	- Tạo component Button dùng lại nhiều nơi
- Bài tập:
	- Tạo danh sách khóa học từ data array truyền qua props

### Day 4: State với useState
- Học:
	- useState, immutable update
- Thực hành:
	- Counter, toggle theme
- Bài tập:
	- App quản lý số lượng sản phẩm (+/-)

### Day 5: Event handling + conditional rendering
- Học:
	- onClick, onChange, onSubmit
	- if/ternary/&& render
- Thực hành:
	- Login UI giả lập (nếu login thì hiện dashboard)
- Bài tập:
	- Show/Hide password + validate rỗng

### Day 6: Render lists + key
- Học:
	- map list, key, filter list
- Thực hành:
	- Danh sách công việc có filter done/all
- Bài tập:
	- Thêm, xóa, đánh dấu hoàn thành task

### Day 7: Mini Project 1 - Todo App
- Mục tiêu:
	- CRUD task với useState
	- Lọc task: all/active/completed
- Đầu ra:
	- Đẩy lên GitHub + README ngắn

## Tuần 2 - Hooks và API

### Day 8: useEffect căn bản
- Học:
	- Side effects, dependency array
- Thực hành:
	- Đồng hồ real-time
- Bài tập:
	- Lưu dark mode vào localStorage

### Day 9: Gọi API
- Học:
	- fetch/axios, loading/error state
- Thực hành:
	- Lấy danh sách users từ API
- Bài tập:
	- Thêm chức năng tìm kiếm user theo tên

### Day 10: useEffect nâng cao
- Học:
	- Cleanup function
	- Tránh gọi API lặp vô hạn
- Thực hành:
	- Debounce search cơ bản
- Bài tập:
	- Tìm kiếm sản phẩm có delay 500ms

### Day 11: useRef + uncontrolled input
- Học:
	- useRef cho DOM và giá trị không re-render
- Thực hành:
	- Auto focus input
- Bài tập:
	- Stopwatch start/stop/reset với ref

### Day 12: Custom Hooks
- Học:
	- Quy tắc đặt tên hook
	- Tách logic lặp lại
- Thực hành:
	- Tạo useLocalStorage
- Bài tập:
	- Tạo useFetch(url)

### Day 13: useMemo + useCallback
- Học:
	- Khi nào cần optimize
- Thực hành:
	- Tối ưu list lớn
- Bài tập:
	- Bench render trước/sau optimize

### Day 14: Mini Project 2 - Product Dashboard
- Mục tiêu:
	- Gọi API products
	- Search + filter + sort
	- Loading/skeleton/error
- Đầu ra:
	- GitHub + image demo

## Tuần 3 - Router, Form, State Management

### Day 15: React Router cơ bản
- Học:
	- BrowserRouter, Routes, Route, Link, NavLink
- Thực hành:
	- Tạo app 3 trang: Home, About, Contact
- Bài tập:
	- Thêm trang NotFound 404

### Day 16: Router nâng cao
- Học:
	- useParams, useNavigate, nested routes
- Thực hành:
	- Trang chi tiết sản phẩm /product/:id
- Bài tập:
	- Breadcrumb đơn giản

### Day 17: Quản lý global state với Context API
- Học:
	- createContext, useContext
- Thực hành:
	- Quản lý auth user và theme
- Bài tập:
	- Tạo cart context (add/remove/update qty)

### Day 18: Redux Toolkit (nếu muốn học bài bản)
- Học:
	- configureStore, createSlice, useSelector/useDispatch
- Thực hành:
	- Counter global state
- Bài tập:
	- Chuyển cart từ Context sang Redux Toolkit

### Day 19: Form nâng cao
- Học:
	- React Hook Form + validate với Zod/Yup
- Thực hành:
	- Form đăng ký có validate
- Bài tập:
	- Validate email, password, confirm password

### Day 20: Styling trong React
- Học:
	- CSS Modules, Tailwind hoặc styled-components
- Thực hành:
	- Chọn 1 hướng styling và thống nhất
- Bài tập:
	- Refactor UI Product Dashboard đẹp hơn

### Day 21: Refactor + Architecture
- Học:
	- Feature-based folder structure
- Thực hành:
	- Tách components/ui, hooks, services, pages
- Bài tập:
	- Viết lại cấu trúc cho dự án tuần 2

## Tuần 4 - Test, Optimize, Deploy + Dự án cuối

### Day 22: Testing cơ bản
- Học:
	- Jest + React Testing Library
- Thực hành:
	- Test render component
- Bài tập:
	- Test button click thay đổi state

### Day 23: Testing với API
- Học:
	- Mock API (msw hoặc mock fetch)
- Thực hành:
	- Test loading/success/error
- Bài tập:
	- Viết 3 test case cho component danh sách

### Day 24: Performance optimization
- Học:
	- React.memo, code splitting, lazy + Suspense
- Thực hành:
	- Tách bundle theo route
- Bài tập:
	- Đo hiệu năng bằng Lighthouse

### Day 25: Error boundary + logging
- Học:
	- ErrorBoundary, xử lý lỗi UI
- Thực hành:
	- Tạo fallback page khi component lỗi
- Bài tập:
	- Simulate lỗi và hiện thông báo thân thiện

### Day 26: Authentication flow frontend
- Học:
	- JWT flow mô phỏng, Protected Route
- Thực hành:
	- Login/logout + route guard
- Bài tập:
	- Tự động redirect nếu chưa login

### Day 27: Mini Project 3 - E-commerce Frontend (Part 1)
- Mục tiêu:
	- Trang list + detail + cart
- Bài tập:
	- Thêm/xóa cập nhật giỏ hàng

### Day 28: Mini Project 3 (Part 2)
- Mục tiêu:
	- Checkout mock + form validate
- Bài tập:
	- Lưu cart vào localStorage

### Day 29: Hoàn thiện portfolio + deploy
- Học:
	- Deploy với Vercel
	- Viết README chuẩn
- Bài tập:
	- Deploy cả 3 dự án

### Day 30: Tổng ôn + Mock interview React
- Tổng kết:
	- Ôn lại toàn bộ hooks
	- Giải thích lifecycle trong function component
	- So sánh Context API vs Redux Toolkit
- Bài tập:
	- Tự trả lời 20 câu hỏi React phổ biến
	- Quay màn hình demo dự án 5-10 phút

---

## 6) Danh sách bài cần học theo thứ tự ưu tiên

1. JavaScript ES6+ vững
2. JSX và Component
3. Props, State, Event
4. useEffect và data fetching
5. Router
6. Context API / Redux Toolkit
7. Form + validation
8. Testing
9. Performance optimization
10. Deploy + project structure

---

## 7) Tiêu chí đánh giá bạn đã học tốt chưa

- Bạn có thể tự tạo app từ số 0 mà không cần copy video.
- Bạn giải thích được vì sao dùng useEffect, useMemo, useCallback.
- Bạn biết tách component và folder theo feature.
- Bạn deploy được app lên Vercel và gửi link cho người khác test.
- Bạn tự tin trả lời câu hỏi phỏng vấn React cơ bản - trung cấp.

---

## 8) Bonus - Kế hoạch học mỗi tuần để không bỏ cuộc

- Chủ nhật mỗi tuần:
	- Review code cả tuần
	- Ghi 5 điều học được
	- Ghi 3 điều chưa rõ để học bù vào tuần sau
- Mỗi ngày commit tối thiểu 1 lần lên GitHub.
- Nếu bạn bận, ưu tiên học theo thứ tự:
	- Hooks -> Router -> State management -> Form -> Test -> Deploy

Chúc bạn hoàn thành 30 ngày học React thật chắc và có sản phẩm thực tế!
