-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Oct 13, 2026 at 01:43 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.0.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `timeguard_db`
--

-- --------------------------------------------------------

--
-- Table structure for table `admins`
--

CREATE TABLE `admins` (
  `admin_id` varchar(10) NOT NULL,
  `full_name` varchar(100) NOT NULL,
  `username` varchar(50) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `email` varchar(100) NOT NULL,
  `phone` varchar(15) DEFAULT NULL,
  `status` varchar(20) NOT NULL,
  `last_login_date` datetime DEFAULT NULL,
  `created_date` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `admins`
--

INSERT INTO `admins` (`admin_id`, `full_name`, `username`, `password_hash`, `email`, `phone`, `status`, `last_login_date`, `created_date`) VALUES
('A0001', 'ผู้ดูแลระบบ', 'admin', '$2y$10$9Rr0Ygj6nqX5D2bw53pRkey0vTOs.9X04lvLqFJn0pKII0VZa1dVy', 'admin@test.com', '', 'active', NULL, '2026-10-12');

-- --------------------------------------------------------

--
-- Table structure for table `attendance_logs`
--

CREATE TABLE `attendance_logs` (
  `attendance_id` varchar(10) NOT NULL,
  `user_id` varchar(10) NOT NULL,
  `area_id` varchar(10) NOT NULL,
  `check_type` varchar(20) NOT NULL,
  `check_datetime` datetime NOT NULL,
  `latitude` decimal(10,6) NOT NULL,
  `longitude` decimal(10,6) NOT NULL,
  `verification_method` varchar(50) NOT NULL,
  `zone_status` varchar(20) NOT NULL,
  `device_info` varchar(100) DEFAULT NULL,
  `is_late` tinyint(1) NOT NULL DEFAULT 0,
  `evidence_photo` varchar(255) NOT NULL,
  `reason` varchar(255) DEFAULT NULL,
  `approval_status` varchar(20) NOT NULL,
  `approved_by` varchar(10) DEFAULT NULL,
  `approved_date` datetime DEFAULT NULL,
  `offsite_request_id` varchar(10) DEFAULT NULL
) ;

-- --------------------------------------------------------

--
-- Table structure for table `departments`
--

CREATE TABLE `departments` (
  `department_id` varchar(10) NOT NULL,
  `department_name` varchar(100) NOT NULL,
  `department_code` varchar(20) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `status` varchar(20) NOT NULL,
  `created_date` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `departments`
--

INSERT INTO `departments` (`department_id`, `department_name`, `department_code`, `description`, `status`, `created_date`) VALUES
('D000001001', 'test', 't', 'ทดสอบ', 'active', '2026-10-13'),
('D0001', 'เทคโนโลยีสารสนเทศ', 'IT', 'แผนกตัวอย่าง', 'active', '2026-10-12');

-- --------------------------------------------------------

--
-- Table structure for table `employees`
--

CREATE TABLE `employees` (
  `employee_id` varchar(10) NOT NULL,
  `full_name` varchar(100) NOT NULL,
  `email` varchar(100) NOT NULL,
  `google_uid` varchar(50) DEFAULT NULL,
  `phone` varchar(15) DEFAULT NULL,
  `department_id` varchar(10) NOT NULL,
  `status` varchar(20) NOT NULL,
  `created_date` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `employees`
--

INSERT INTO `employees` (`employee_id`, `full_name`, `email`, `google_uid`, `phone`, `department_id`, `status`, `created_date`) VALUES
('E000001001', 'รพีภัทร ประกอบ', 'poiuy2597@gmail.com', '114769439207888097014', '0643456235', 'D000001001', 'active', '2026-10-13'),
('E000001002', 'test user', 'poiuyt2597@gmail.com', NULL, '0643456235', 'D0001', 'active', '2026-10-13'),
('E0001', 'พนักงานตัวอย่าง', 'employee@test.com', NULL, '', 'D0001', 'active', '2026-10-12');

-- --------------------------------------------------------

--
-- Table structure for table `employee_work_areas`
--

CREATE TABLE `employee_work_areas` (
  `employee_area_id` varchar(10) NOT NULL,
  `employee_id` varchar(10) NOT NULL,
  `area_id` varchar(10) NOT NULL,
  `is_primary` tinyint(1) NOT NULL DEFAULT 0,
  `effective_date` date NOT NULL,
  `end_date` date DEFAULT NULL,
  `status` varchar(20) NOT NULL
) ;

--
-- Dumping data for table `employee_work_areas`
--

INSERT INTO `employee_work_areas` (`employee_area_id`, `employee_id`, `area_id`, `is_primary`, `effective_date`, `end_date`, `status`) VALUES
('EA00001001', 'E000001002', 'G0001', 1, '2026-10-13', NULL, 'active'),
('EA00001002', 'E000001001', 'G000001003', 1, '2026-10-13', NULL, 'active'),
('EA0001', 'E0001', 'G0001', 1, '2026-10-12', NULL, 'active');

-- --------------------------------------------------------

--
-- Table structure for table `face_biometrics`
--

CREATE TABLE `face_biometrics` (
  `biometric_id` varchar(10) NOT NULL,
  `user_id` varchar(10) NOT NULL,
  `face_image` varchar(255) NOT NULL,
  `face_encoding` text NOT NULL,
  `registration_date` datetime NOT NULL,
  `approval_status` varchar(20) NOT NULL,
  `approved_by` varchar(10) DEFAULT NULL,
  `approved_date` datetime DEFAULT NULL,
  `status` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `geofence_areas`
--

CREATE TABLE `geofence_areas` (
  `area_id` varchar(10) NOT NULL,
  `area_name` varchar(100) NOT NULL,
  `department_id` varchar(10) NOT NULL,
  `polygon_coordinates` text NOT NULL,
  `center_latitude` decimal(10,6) NOT NULL,
  `center_longitude` decimal(10,6) NOT NULL,
  `status` varchar(20) NOT NULL,
  `created_date` datetime NOT NULL
) ;

--
-- Dumping data for table `geofence_areas`
--

INSERT INTO `geofence_areas` (`area_id`, `area_name`, `department_id`, `polygon_coordinates`, `center_latitude`, `center_longitude`, `status`, `created_date`) VALUES
('G000001003', 'test', 'D000001001', '[{\"lat\":16.433380385681925,\"lng\":102.8638529777527},{\"lat\":16.431836796177265,\"lng\":102.86275863647462},{\"lat\":16.431960283788985,\"lng\":102.86224365234376},{\"lat\":16.42817329465983,\"lng\":102.86147117614748},{\"lat\":16.427885151161057,\"lng\":102.86526918411256},{\"lat\":16.429552261202918,\"lng\":102.86548376083374},{\"lat\":16.42975807626556,\"lng\":102.86426067352296},{\"lat\":16.430437264425482,\"lng\":102.86434650421144},{\"lat\":16.43062249714796,\"lng\":102.86402463912965},{\"lat\":16.433112831046508,\"lng\":102.8652048110962}]', 16.430672, 102.863892, 'active', '2026-10-13 18:08:52'),
('G0001', 'สำนักงานตัวอย่าง', 'D0001', '[{\"lat\":13.7553,\"lng\":100.5008},{\"lat\":13.7553,\"lng\":100.5028},{\"lat\":13.7573,\"lng\":100.5028},{\"lat\":13.7573,\"lng\":100.5008}]', 13.756300, 100.501800, 'active', '2026-10-12 22:59:06');

-- --------------------------------------------------------

--
-- Table structure for table `human_resources`
--

CREATE TABLE `human_resources` (
  `hr_id` varchar(10) NOT NULL,
  `full_name` varchar(100) NOT NULL,
  `username` varchar(50) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `email` varchar(100) NOT NULL,
  `phone` varchar(15) DEFAULT NULL,
  `status` varchar(20) NOT NULL,
  `last_login_date` datetime DEFAULT NULL,
  `created_date` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `human_resources`
--

INSERT INTO `human_resources` (`hr_id`, `full_name`, `username`, `password_hash`, `email`, `phone`, `status`, `last_login_date`, `created_date`) VALUES
('H0001', 'เจ้าหน้าที่บุคคล', 'hr', '$2y$10$9Rr0Ygj6nqX5D2bw53pRkey0vTOs.9X04lvLqFJn0pKII0VZa1dVy', 'hr@test.com', '', 'active', '2026-10-13 18:07:49', '2026-10-12');

-- --------------------------------------------------------

--
-- Table structure for table `offsite_work_requests`
--

CREATE TABLE `offsite_work_requests` (
  `offsite_request_id` varchar(10) NOT NULL,
  `employee_id` varchar(10) NOT NULL,
  `request_date` datetime NOT NULL,
  `work_date_start` date NOT NULL,
  `work_date_end` date NOT NULL,
  `location_description` varchar(255) NOT NULL,
  `reason` varchar(255) NOT NULL,
  `approval_status` varchar(20) NOT NULL,
  `approved_by` varchar(10) DEFAULT NULL,
  `approved_date` datetime DEFAULT NULL
) ;

--
-- Dumping data for table `offsite_work_requests`
--

INSERT INTO `offsite_work_requests` (`offsite_request_id`, `employee_id`, `request_date`, `work_date_start`, `work_date_end`, `location_description`, `reason`, `approval_status`, `approved_by`, `approved_date`) VALUES
('OS00001001', 'E000001001', '2026-10-13 18:13:17', '2026-10-13', '2026-10-13', 'dd', 'dd', 'รออนุมัติ', NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `supervisors`
--

CREATE TABLE `supervisors` (
  `supervisor_id` varchar(10) NOT NULL,
  `full_name` varchar(100) NOT NULL,
  `username` varchar(50) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `email` varchar(100) NOT NULL,
  `phone` varchar(15) DEFAULT NULL,
  `department_id` varchar(10) NOT NULL,
  `status` varchar(20) NOT NULL,
  `last_login_date` datetime DEFAULT NULL,
  `created_date` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `supervisors`
--

INSERT INTO `supervisors` (`supervisor_id`, `full_name`, `username`, `password_hash`, `email`, `phone`, `department_id`, `status`, `last_login_date`, `created_date`) VALUES
('S0001', 'หัวหน้างาน', 'supervisor', '$2y$10$9Rr0Ygj6nqX5D2bw53pRkey0vTOs.9X04lvLqFJn0pKII0VZa1dVy', 'supervisor@test.com', '', 'D0001', 'active', NULL, '2026-10-12');

-- --------------------------------------------------------

--
-- Table structure for table `system_configurations`
--

CREATE TABLE `system_configurations` (
  `config_id` varchar(10) NOT NULL,
  `config_name` varchar(100) NOT NULL,
  `start_time` time DEFAULT NULL,
  `start_late` time DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `updated_date` datetime NOT NULL,
  `config_type` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `system_configurations`
--

INSERT INTO `system_configurations` (`config_id`, `config_name`, `start_time`, `start_late`, `description`, `updated_date`, `config_type`) VALUES
('CFG0001', 'เวลาปฏิบัติงาน', '09:00:00', '09:00:00', 'ค่าเริ่มต้น ต้องปรับตามนโยบายองค์กร', '2026-10-12 22:59:06', 'attendance');

-- --------------------------------------------------------

--
-- Table structure for table `tech_auth_tokens`
--

CREATE TABLE `tech_auth_tokens` (
  `token_hash` char(64) NOT NULL,
  `employee_id` varchar(10) DEFAULT NULL,
  `admin_id` varchar(10) DEFAULT NULL,
  `hr_id` varchar(10) DEFAULT NULL,
  `supervisor_id` varchar(10) DEFAULT NULL,
  `expires_at` datetime NOT NULL
) ;

--
-- Dumping data for table `tech_auth_tokens`
--

INSERT INTO `tech_auth_tokens` (`token_hash`, `employee_id`, `admin_id`, `hr_id`, `supervisor_id`, `expires_at`) VALUES
('90efd3b0e8c5744c30ad905e958e6b2852b05b31a2272ce3cc3617f5cffea372', 'E000001001', NULL, NULL, NULL, '2026-10-14 16:09:23'),
('938058b774c2078f1065e54a1035a3e6ada5a1b28d7fc7f4aa83c36d269da480', 'E000001001', NULL, NULL, NULL, '2026-10-20 16:03:17');

-- --------------------------------------------------------

--
-- Table structure for table `tech_id_sequences`
--

CREATE TABLE `tech_id_sequences` (
  `prefix` varchar(3) NOT NULL,
  `next_value` bigint(20) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `tech_id_sequences`
--

INSERT INTO `tech_id_sequences` (`prefix`, `next_value`) VALUES
('D', 1001),
('E', 1002),
('EA', 1003),
('G', 1003),
('OS', 1001);

-- --------------------------------------------------------

--
-- Table structure for table `tech_login_attempts`
--

CREATE TABLE `tech_login_attempts` (
  `attempt_key` char(64) NOT NULL,
  `attempts` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `window_start` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `tech_login_attempts`
--

INSERT INTO `tech_login_attempts` (`attempt_key`, `attempts`, `window_start`) VALUES
('238a413e52964697d82f559814f3c249fdbfc82607de017ae8081b3732efde46', 2, '2026-10-13 16:02:50'),
('7237355989f76f236d97cf5b10d62d1a3fee6db2ff3833e37e620693c3ee76a5', 1, '2026-10-13 17:35:14');

-- --------------------------------------------------------

--
-- Table structure for table `tech_notifications`
--

CREATE TABLE `tech_notifications` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `employee_id` varchar(10) NOT NULL,
  `title` varchar(200) NOT NULL,
  `body` text NOT NULL,
  `read_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `tech_notifications`
--

INSERT INTO `tech_notifications` (`id`, `employee_id`, `title`, `body`, `read_at`, `created_at`) VALUES
(1, 'E000001001', 'ส่งคำขอนอกพื้นที่แล้ว', 'dd', NULL, '2026-10-13 18:13:17');

-- --------------------------------------------------------

--
-- Table structure for table `tech_web_audit_logs`
--

CREATE TABLE `tech_web_audit_logs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `actor_id` varchar(10) NOT NULL,
  `actor_role` varchar(20) NOT NULL,
  `action` varchar(30) NOT NULL,
  `entity` varchar(40) NOT NULL,
  `record_id` varchar(10) NOT NULL,
  `changed_fields` text NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tech_web_audit_logs`
--

INSERT INTO `tech_web_audit_logs` (`id`, `actor_id`, `actor_role`, `action`, `entity`, `record_id`, `changed_fields`, `created_at`) VALUES
(1, 'H0001', 'hr', 'create', 'employees', 'E000001001', '[\"employee_id\",\"full_name\",\"email\",\"phone\",\"google_uid\",\"department_id\",\"status\",\"created_date\"]', '2026-10-13 00:43:27'),
(2, 'H0001', 'hr', 'update', 'employees', 'E000001001', '[\"full_name\",\"email\",\"phone\",\"google_uid\",\"department_id\",\"status\"]', '2026-10-13 01:23:09'),
(3, 'H0001', 'hr', 'create', 'employees', 'E000001002', '[\"employee_id\",\"full_name\",\"email\",\"phone\",\"google_uid\",\"department_id\",\"status\",\"created_date\"]', '2026-10-13 15:08:52'),
(4, 'H0001', 'hr', 'create', 'departments', 'D000001001', '[\"department_id\",\"department_name\",\"department_code\",\"description\",\"status\",\"created_date\"]', '2026-10-13 15:33:54'),
(5, 'H0001', 'hr', 'create', 'work_areas', 'EA00001001', '[\"employee_area_id\",\"employee_id\",\"area_id\",\"is_primary\",\"effective_date\",\"end_date\",\"status\"]', '2026-10-13 15:52:39'),
(6, 'H0001', 'hr', 'create', 'work_areas', 'EA00001002', '[\"employee_area_id\",\"employee_id\",\"area_id\",\"is_primary\",\"effective_date\",\"end_date\",\"status\"]', '2026-10-13 15:57:51'),
(11, 'H0001', 'hr', 'create', 'geofences', 'G000001003', '[\"area_id\",\"area_name\",\"department_id\",\"status\",\"center_latitude\",\"center_longitude\",\"polygon_coordinates\",\"created_date\"]', '2026-10-13 18:08:52'),
(12, 'H0001', 'hr', 'update', 'employees', 'E000001001', '[\"full_name\",\"email\",\"phone\",\"google_uid\",\"department_id\",\"status\"]', '2026-10-13 18:10:42'),
(13, 'H0001', 'hr', 'update', 'work_areas', 'EA00001002', '[\"employee_id\",\"area_id\",\"is_primary\",\"effective_date\",\"end_date\",\"status\"]', '2026-10-13 18:10:55');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `admins`
--
ALTER TABLE `admins`
  ADD PRIMARY KEY (`admin_id`),
  ADD UNIQUE KEY `username` (`username`);

--
-- Indexes for table `attendance_logs`
--
ALTER TABLE `attendance_logs`
  ADD PRIMARY KEY (`attendance_id`),
  ADD KEY `area_id` (`area_id`),
  ADD KEY `approved_by` (`approved_by`),
  ADD KEY `offsite_request_id` (`offsite_request_id`),
  ADD KEY `attendance_lookup` (`user_id`,`check_datetime`,`check_type`);

--
-- Indexes for table `departments`
--
ALTER TABLE `departments`
  ADD PRIMARY KEY (`department_id`),
  ADD UNIQUE KEY `department_code` (`department_code`);

--
-- Indexes for table `employees`
--
ALTER TABLE `employees`
  ADD PRIMARY KEY (`employee_id`),
  ADD UNIQUE KEY `email` (`email`),
  ADD UNIQUE KEY `google_uid` (`google_uid`),
  ADD KEY `department_id` (`department_id`);

--
-- Indexes for table `employee_work_areas`
--
ALTER TABLE `employee_work_areas`
  ADD PRIMARY KEY (`employee_area_id`),
  ADD KEY `area_id` (`area_id`),
  ADD KEY `assignment_lookup` (`employee_id`,`status`,`effective_date`,`end_date`);

--
-- Indexes for table `face_biometrics`
--
ALTER TABLE `face_biometrics`
  ADD PRIMARY KEY (`biometric_id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `approved_by` (`approved_by`);

--
-- Indexes for table `geofence_areas`
--
ALTER TABLE `geofence_areas`
  ADD PRIMARY KEY (`area_id`),
  ADD KEY `department_id` (`department_id`);

--
-- Indexes for table `human_resources`
--
ALTER TABLE `human_resources`
  ADD PRIMARY KEY (`hr_id`),
  ADD UNIQUE KEY `username` (`username`);

--
-- Indexes for table `offsite_work_requests`
--
ALTER TABLE `offsite_work_requests`
  ADD PRIMARY KEY (`offsite_request_id`),
  ADD KEY `approved_by` (`approved_by`),
  ADD KEY `offsite_lookup` (`employee_id`,`approval_status`,`work_date_start`,`work_date_end`);

--
-- Indexes for table `supervisors`
--
ALTER TABLE `supervisors`
  ADD PRIMARY KEY (`supervisor_id`),
  ADD UNIQUE KEY `username` (`username`),
  ADD KEY `department_id` (`department_id`);

--
-- Indexes for table `system_configurations`
--
ALTER TABLE `system_configurations`
  ADD PRIMARY KEY (`config_id`);

--
-- Indexes for table `tech_auth_tokens`
--
ALTER TABLE `tech_auth_tokens`
  ADD PRIMARY KEY (`token_hash`),
  ADD KEY `employee_id` (`employee_id`),
  ADD KEY `admin_id` (`admin_id`),
  ADD KEY `hr_id` (`hr_id`),
  ADD KEY `supervisor_id` (`supervisor_id`);

--
-- Indexes for table `tech_id_sequences`
--
ALTER TABLE `tech_id_sequences`
  ADD PRIMARY KEY (`prefix`);

--
-- Indexes for table `tech_login_attempts`
--
ALTER TABLE `tech_login_attempts`
  ADD PRIMARY KEY (`attempt_key`);

--
-- Indexes for table `tech_notifications`
--
ALTER TABLE `tech_notifications`
  ADD PRIMARY KEY (`id`),
  ADD KEY `notice_lookup` (`employee_id`,`id`);

--
-- Indexes for table `tech_web_audit_logs`
--
ALTER TABLE `tech_web_audit_logs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `audit_record` (`entity`,`record_id`,`created_at`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `tech_notifications`
--
ALTER TABLE `tech_notifications`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `tech_web_audit_logs`
--
ALTER TABLE `tech_web_audit_logs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `attendance_logs`
--
ALTER TABLE `attendance_logs`
  ADD CONSTRAINT `attendance_logs_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `employees` (`employee_id`),
  ADD CONSTRAINT `attendance_logs_ibfk_2` FOREIGN KEY (`area_id`) REFERENCES `geofence_areas` (`area_id`),
  ADD CONSTRAINT `attendance_logs_ibfk_3` FOREIGN KEY (`approved_by`) REFERENCES `supervisors` (`supervisor_id`),
  ADD CONSTRAINT `attendance_logs_ibfk_4` FOREIGN KEY (`offsite_request_id`) REFERENCES `offsite_work_requests` (`offsite_request_id`);

--
-- Constraints for table `employees`
--
ALTER TABLE `employees`
  ADD CONSTRAINT `employees_ibfk_1` FOREIGN KEY (`department_id`) REFERENCES `departments` (`department_id`);

--
-- Constraints for table `employee_work_areas`
--
ALTER TABLE `employee_work_areas`
  ADD CONSTRAINT `employee_work_areas_ibfk_1` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`employee_id`),
  ADD CONSTRAINT `employee_work_areas_ibfk_2` FOREIGN KEY (`area_id`) REFERENCES `geofence_areas` (`area_id`);

--
-- Constraints for table `face_biometrics`
--
ALTER TABLE `face_biometrics`
  ADD CONSTRAINT `face_biometrics_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `employees` (`employee_id`),
  ADD CONSTRAINT `face_biometrics_ibfk_2` FOREIGN KEY (`approved_by`) REFERENCES `human_resources` (`hr_id`);

--
-- Constraints for table `geofence_areas`
--
ALTER TABLE `geofence_areas`
  ADD CONSTRAINT `geofence_areas_ibfk_1` FOREIGN KEY (`department_id`) REFERENCES `departments` (`department_id`);

--
-- Constraints for table `offsite_work_requests`
--
ALTER TABLE `offsite_work_requests`
  ADD CONSTRAINT `offsite_work_requests_ibfk_1` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`employee_id`),
  ADD CONSTRAINT `offsite_work_requests_ibfk_2` FOREIGN KEY (`approved_by`) REFERENCES `supervisors` (`supervisor_id`);

--
-- Constraints for table `supervisors`
--
ALTER TABLE `supervisors`
  ADD CONSTRAINT `supervisors_ibfk_1` FOREIGN KEY (`department_id`) REFERENCES `departments` (`department_id`);

--
-- Constraints for table `tech_auth_tokens`
--
ALTER TABLE `tech_auth_tokens`
  ADD CONSTRAINT `tech_auth_tokens_ibfk_1` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`employee_id`),
  ADD CONSTRAINT `tech_auth_tokens_ibfk_2` FOREIGN KEY (`admin_id`) REFERENCES `admins` (`admin_id`),
  ADD CONSTRAINT `tech_auth_tokens_ibfk_3` FOREIGN KEY (`hr_id`) REFERENCES `human_resources` (`hr_id`),
  ADD CONSTRAINT `tech_auth_tokens_ibfk_4` FOREIGN KEY (`supervisor_id`) REFERENCES `supervisors` (`supervisor_id`);

--
-- Constraints for table `tech_notifications`
--
ALTER TABLE `tech_notifications`
  ADD CONSTRAINT `tech_notifications_ibfk_1` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`employee_id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
