### **Tài liệu Yêu cầu Tính năng - Ứng dụng Lịch làm việc Nhân viên**

**Tổng quan:** Mục tiêu của dự án là xây dựng một ứng dụng di động cho phép nhân viên và quản lý tại các cửa hàng có thể xem lịch làm việc hàng ngày một cách trực quan và hiệu quả.

---

#### **1. Tên Tính năng: Hiển thị Lịch làm việc động**

*   **Mục tiêu người dùng:** Với vai trò là một nhân viên hoặc quản lý, tôi muốn xem một lịch trình trực quan, được cập nhật theo thời gian thực để có thể nắm bắt công việc trong ngày của tất cả mọi người.

*   **Mô tả chi tiết:**
    *   Màn hình chính của ứng dụng phải hiển thị một bảng lưới biểu diễn dòng thời gian công việc.
    *   Dữ liệu cho bảng này (ví dụ: tên cửa hàng, danh sách nhân viên, nhiệm vụ, v.v.) phải được lấy từ một hệ thống máy chủ từ xa. Trong quá trình tải dữ liệu, một chỉ báo tải (loading indicator) phải được hiển thị.
    *   Bảng lưới được cấu trúc với các hàng là tên của từng nhân viên và các cột là dòng thời gian trong ngày. Dòng thời gian này phải kéo dài từ 5:00 sáng đến nửa đêm (24:00) và được chia nhỏ thành các cột con tương ứng với từng khoảng 15 phút.
    *   Các nhiệm vụ phải được hiển thị dưới dạng các khối màu bên trong lưới, đặt chính xác vào đúng hàng nhân viên và đúng khung giờ bắt đầu.
    *   Mỗi "loại công việc" (ví dụ: Bán hàng, Kiểm kho) sẽ có một màu sắc được định nghĩa trước. Các khối nhiệm vụ trên lưới phải hiển thị đúng màu sắc tương ứng với loại công việc của nó.

*   **Yêu cầu nghiệm thu:**
    *   ✅ Khi đang tải dữ liệu, ứng dụng phải hiển thị một vòng xoay tải.
    *   ✅ Tên cửa hàng được hiển thị chính xác trên giao diện.
    *   ✅ Bảng lưới hiển thị đúng danh sách các nhân viên có lịch làm việc trong ngày.
    *   ✅ Các khối nhiệm vụ được đặt đúng nhân viên và đúng thời điểm bắt đầu.
    *   ✅ Màu của khối nhiệm vụ phải khớp với màu đã quy định cho loại công việc đó.

---

#### **2. Tên Tính năng: Điều hướng Bảng biểu Linh hoạt (Fixed Header/Column)**

*   **Mục tiêu người dùng:** Khi xem một bảng lịch trình lớn, tôi muốn luôn biết mình đang xem lịch của nhân viên nào và vào lúc mấy giờ, ngay cả khi tôi cuộn bảng đi xa.

*   **Mô tả chi tiết:**
    *   Người dùng phải có thể cuộn bảng lịch trình theo cả chiều ngang, chiều dọc và đường chéo một cách mượt mà.
    *   **Khi cuộn dọc (lên/xuống):** Hàng tiêu đề trên cùng (chứa các mốc giờ) phải được giữ cố định ở phía trên màn hình.
    *   **Khi cuộn ngang (trái/phải):** Cột đầu tiên bên trái (chứa tên các nhân viên) phải được giữ cố định ở phía bên trái màn hình.
    *   Ô góc trên cùng bên trái (tiêu đề của cột nhân viên) phải luôn cố định.

*   **Yêu cầu nghiệm thu:**
    *   ✅ Cuộn bảng lên/xuống, hàng chứa các mốc giờ không di chuyển.
    *   ✅ Cuộn bảng trái/phải, cột chứa tên nhân viên không di chuyển.
    *   ✅ Thao tác cuộn theo đường chéo phải cho cảm giác tự nhiên, đồng bộ.

---

#### **3. Tên Tính năng: Hiển thị Thông tin Ngữ cảnh và Điều hướng**

*   **Mục tiêu người dùng:** Với vai trò là người dùng, tôi muốn dễ dàng xác định được thông tin cơ bản như tôi là ai, đang xem lịch của cửa hàng nào để tránh nhầm lẫn.

*   **Mô tả chi tiết:**
    *   Thanh điều hướng trên cùng của ứng dụng phải hiển thị tên cửa hàng hiện tại.
    *   Thông tin của người dùng đang đăng nhập (tên và vai trò) phải được hiển thị nổi bật trên thanh điều hướng.
    *   Ứng dụng cần có một menu điều hướng (dạng thanh bên - drawer) có thể mở ra được. Phần đầu của menu này cũng phải hiển thị lại thông tin của người dùng.
    *   Menu phải chứa các mục để chuyển đổi qua lại giữa các màn hình khác nhau (ví dụ: "Lịch hàng ngày", "Lịch hàng tháng").

*   **Yêu cầu nghiệm thu:**
    *   ✅ Tên cửa hàng hiển thị trên thanh điều hướng phải chính xác.
    *   ✅ Tên và vai trò của người dùng phải được hiển thị chính xác ở hai vị trí: thanh điều hướng và đầu menu.
    *   ✅ Menu có thể mở/đóng và các mục trong đó có thể tương tác được.

---

#### **4. Tên Tính năng: Giữ Màn hình Sáng trong Giờ làm việc**

*   **Mục tiêu người dùng:** Khi đang trong ca làm việc, tôi muốn màn hình ứng dụng luôn sáng để có thể liên tục theo dõi lịch trình mà không cần phải chạm vào màn hình.

*   **Mô tả chi tiết:**
    *   Hệ thống phải có khả năng tự động xác định được "khung giờ làm việc" trong ngày dựa trên thời điểm bắt đầu của nhiệm vụ sớm nhất và thời điểm kết thúc của nhiệm vụ muộn nhất.
    *   Trong khoảng thời gian này, ứng dụng phải chủ động ngăn không cho màn hình thiết bị tự động tắt.
    *   Khi nằm ngoài "khung giờ làm việc", ứng dụng phải trả lại cơ chế tự động tắt màn hình cho hệ điều hành để tiết kiệm pin.
    *   Tính năng này phải hoạt động ngầm và không được yêu cầu người dùng cấp bất kỳ quyền hạn đặc biệt nào.

*   **Yêu cầu nghiệm thu:**
    *   ✅ **Kịch bản 1:** Trong khung giờ làm việc, cài đặt thời gian chờ màn hình của thiết bị là 15 giây. Sau 15 giây, màn hình phải vẫn sáng.
    *   ✅ **Kịch bản 2:** Ngoài khung giờ làm việc, cài đặt thời gian chờ màn hình của thiết bị là 15 giây. Sau 15 giây, màn hình phải tự động tắt.
