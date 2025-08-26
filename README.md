# 📚 BLib – Library Management System

BLib is a **full-stack library management system** developed as a semester project in Software Engineering.  
The system supports both **subscribers** and **librarians**, providing efficient tools for managing books, loans, reservations, and automated reports.

---

## 🚀 Features

### 🔑 Subscribers
- Register and manage account.
- Borrow up to **5 books** (loans + reservations).
- Search books by **title, subject, or free-text description**.
- Extend loans (if no reservation is pending).
- Receive reminders:
  - **Email/SMS** – 1 day before due date.
  - **In-app notification** – 1 week before due date.
- View personal history and penalties.

### 📖 Librarians
- Manage subscriber accounts (activate, freeze, update info).
- Borrow and return books for subscribers.
- Handle late/lost books (automatic freeze after 1+ week delay).
- Manage reservations:
  - Queue-based (“first come, first served”).
  - Auto-cancel if not collected within 2 days.
- Update return dates manually (logged).
- Generate monthly reports:
  - Borrow Records Report (borrowed, returned, late).
  - Subscribers Status Report (active, inactive, frozen).
- All actions are logged.

---

## 🛠️ Technologies
- **Java** (OOP, multithreading)
- **JavaFX** (GUI with FXML + Scene Builder)
- **MySQL** (Database with Triggers, Events, Procedures)
- **OCSF** (Client-server communication over TCP/IP)
- **JDBC** (MySQL integration)
- **Gson** (JSON handling)

---

## 📂 Database Schema
- **Subscribers**: SubID, Name, Status, Phone, Email, Penalties, Join/Expiration dates  
- **Librarians**: LibID, Name  
- **Books**: BookID, Title, Author, Genre, Description  
- **BookCopies**: CopyID, BookID (FK), Location, Status (Available/Borrowed)  
- **BorrowRecords**: BorrowID, CopyID (FK), SubID (FK), BorrowDate, ReturnDate, Status  
- **OrderRecords**: OrderID, CopyID (FK), SubID (FK), OrderDate, Status (Waiting/In-Progress/Cancelled/Completed)  

### 🔄 Automation
- **Triggers** – log actions, update availability, enforce penalties.  
- **Events** – daily tasks: unfreeze subscribers, detect late returns, cancel overdue reservations.  
- **Procedures** – handle lost books, extend loans, send notifications, generate reports.  



## 🖥️ How to Run

```bash
# 1. Clone the repository
git clone https://github.com/YourUsername/BLib.git


# 2. Run the Server
# Open ServerUI.java → Right-click → Run Java
# Then enter the following parameters in order:
localhost:3306
root
Aa123456
5555


# 3. Run the Client
# Open ClientUI.java → Right-click → Run Java
# When prompted, enter:
localhost



✅ The system is now ready – you can log in as a Subscriber or Librarian.
