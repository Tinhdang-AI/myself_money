

# Fundy Management App

📱 **Giới thiệu**

# Fundy Management App là một ứng dụng quản lý tài chính cá nhân toàn diện được phát triển bằng Flutter. Ứng dụng này giúp người dùng theo dõi và kiểm soát chi tiêu hàng ngày, thiết lập mục tiêu tiết kiệm, và phân tích mô hình chi tiêu để đưa ra các quyết định tài chính thông minh hơn.

✨ **Tính năng chính**
- **Theo dõi chi tiêu**: Nhập và phân loại các khoản chi tiêu một cách dễ dàng và nhanh chóng
- **Phân loại tự động**: Tự động phân loại các khoản chi tiêu theo nhiều danh mục khác nhau (thức ăn, đi lại, giải trí, v.v.)
- **Mục tiêu tiết kiệm**: Thiết lập và theo dõi tiến độ các mục tiêu tiết kiệm
- **Báo cáo & Phân tích**: Cung cấp báo cáo chi tiết và phân tích chi tiêu để hiểu rõ mô hình chi tiêu cá nhân
- **Giao diện thân thiện**: UI/UX được thiết kế trực quan và dễ sử dụng

🖼️ **Hình ảnh & Thiết kế**

### 📐 **Thiết kế Figma**
![Frame 16](https://github.com/user-attachments/assets/72393338-28a1-4cee-96ee-b4b3db249b55)

### 📱 **Giao diện ứng dụng**

<p align="center">
  <img src="https://github.com/user-attachments/assets/6487ec98-8081-4bb5-b414-c1093a19d40d" alt="image2" width="30%" />
  <img src="https://github.com/user-attachments/assets/66d1c808-9007-4ab0-8d1e-7ddd0bed97a1" alt="image3" width="30%" />
  <img src="https://github.com/user-attachments/assets/0bbe09e4-038b-479a-bcb0-1fa8eae2cde2" alt="image4" width="30%" />
</p>

<p align="center">
  <img src="https://github.com/user-attachments/assets/9650addc-a42d-4f61-89eb-a1205e949803" alt="image5" width="30%" />
  <img src="https://github.com/user-attachments/assets/319c18bf-a662-4878-9fac-47f5e6bb66f5" alt="image6" width="30%" />
  <img src="https://github.com/user-attachments/assets/5f0ec0d2-e1af-48e2-8b28-131749519ef3" alt="image7" width="30%" />
</p>

<p align="center">
  <img src="https://github.com/user-attachments/assets/ba0cf300-c598-4f3b-a14b-9f412e883a91" alt="image8" width="30%" />
  <img src="https://github.com/user-attachments/assets/ac3776ac-ec47-41c5-adac-3924990e07ff" alt="image9" width="30%" />
  <img src="https://github.com/user-attachments/assets/dbc49987-f073-445e-bdad-573aad4ed5aa" alt="image10" width="30%" />
</p>

<p align="center">
  <img src="https://github.com/user-attachments/assets/4f6dc5e6-3d82-47c7-812c-2eb72cf0dd22" alt="image11" width="30%" />
  <img src="https://github.com/user-attachments/assets/672b45ab-f93e-4c44-8da5-31784aacee72" alt="image12" width="30%" />
  <img src="https://github.com/user-attachments/assets/0645e82b-1795-435b-87f6-47329ac43fdd" alt="image13" width="30%" />
</p>

<p align="center">
  <img src="https://github.com/user-attachments/assets/f914657e-8977-484e-b91f-260f0efa42e3" alt="image14" width="30%" />
  <img src="https://github.com/user-attachments/assets/7e5cf5ed-6221-4f38-b3bc-af2d4e0fc55f" alt="image15" width="30%" />
  <img src="https://github.com/user-attachments/assets/df363423-8dd5-49ea-b6c4-0e40038b4209" alt="image16" width="30%" />
</p>

<p align="center">
  <img src="https://github.com/user-attachments/assets/d038ea1a-01da-4b5b-8d2b-2e96ba1380c6" alt="image17" width="30%" />
  <img src="https://github.com/user-attachments/assets/24ed74a2-8cc1-4ee3-8781-bef49bad3daa" alt="image18" width="30%" />
  <img src="https://github.com/user-attachments/assets/350f9c58-00de-44a5-a7b8-c6e1d1ad489a" alt="image19" width="30%" />
</p>

<p align="center">
  <img src="https://github.com/user-attachments/assets/fe3acb51-a6eb-4cb9-8b2c-8d8d6e47b47c" alt="image20" width="30%" />
</p>

🛠️ **Công nghệ sử dụng**
- **Framework**: Flutter
- **Ngôn ngữ**: Dart
- **State Management**: Provider
- **Cơ sở dữ liệu**: SQLite / Hive
- **UI Components**: Material Design
- **Charts & Graphs**: fl_chart
- **Localization**: flutter_localizations

📲 **Hướng dẫn cài đặt**

1. **Cài đặt từ mã nguồn**:
   - Đảm bảo bạn đã cài đặt Flutter SDK
   - Clone repository:  
    git clone https://github.com/Tinhdang-AI/myself_money.git
   - Di chuyển vào thư mục dự án:  
    cd fundy_management_app
   - Cài đặt các dependencies:  
    flutter pub get
   - Chạy ứng dụng:  
    flutter run

🧩 Kiến trúc ứng dụng

Ứng dụng được xây dựng theo mô hình MVVM (Model-View-ViewModel) với cấu trúc thư mục như sau:

  lib/  
  ├── models/          # Mô hình dữ liệu  
  ├── views/           # Giao diện người dùng  
  ├── viewmodels/      # Xử lý logic nghiệp vụ  
  ├── services/        # Các dịch vụ (DB, API, ...)  
  ├── utils/           # Tiện ích và hằng số  
  └── main.dart        # Điểm khởi đầu ứng dụng  
