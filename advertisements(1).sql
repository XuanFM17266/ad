/*
 Navicat Premium Dump SQL

 Source Server         : mysql
 Source Server Type    : MySQL
 Source Server Version : 80041 (8.0.41)
 Source Host           : localhost:3306
 Source Schema         : advertisements

 Target Server Type    : MySQL
 Target Server Version : 80041 (8.0.41)
 File Encoding         : 65001

 Date: 23/05/2025 00:45:37
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for ads
-- ----------------------------
DROP TABLE IF EXISTS `ads`;
CREATE TABLE `ads`  (
  `ad_id` bigint NOT NULL COMMENT '广告唯一标识',
  `title` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_german2_ci NOT NULL COMMENT '广告标题',
  `content` text CHARACTER SET utf8mb4 COLLATE utf8mb4_german2_ci NOT NULL COMMENT '广告内容',
  `daily_budget` decimal(15, 2) NOT NULL COMMENT '每日预算',
  `start_date` date NOT NULL COMMENT '投放开始日期',
  `end_date` date NOT NULL COMMENT '投放结束日期',
  `status` enum('pending','approved','online','paused','expired','rejected') CHARACTER SET utf8mb4 COLLATE utf8mb4_german2_ci NOT NULL COMMENT '状态（pending等）',
  `price` decimal(15, 2) NOT NULL COMMENT '广告单价',
  `owner_id` bigint NOT NULL COMMENT '所属用户ID',
  `created_at` datetime NOT NULL COMMENT '创建时间',
  PRIMARY KEY (`ad_id`) USING BTREE,
  INDEX `status`(`status` ASC) USING BTREE,
  INDEX `owner_id`(`owner_id` ASC) USING BTREE,
  CONSTRAINT `ads_ibfk_1` FOREIGN KEY (`owner_id`) REFERENCES `users` (`user_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_german2_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of ads
-- ----------------------------

-- ----------------------------
-- Table structure for audit_logs
-- ----------------------------
DROP TABLE IF EXISTS `audit_logs`;
CREATE TABLE `audit_logs`  (
  `log_id` bigint NOT NULL COMMENT '日志唯一标识',
  `user_id` bigint NOT NULL COMMENT '操作用户ID',
  `action_type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_german2_ci NOT NULL COMMENT '操作类型',
  `target_id` bigint NOT NULL COMMENT '操作对象ID',
  `details` text CHARACTER SET utf8mb4 COLLATE utf8mb4_german2_ci NULL COMMENT '操作详情',
  `created_at` datetime NOT NULL COMMENT '记录时间',
  PRIMARY KEY (`log_id`) USING BTREE,
  INDEX `created_at`(`created_at` ASC) USING BTREE,
  INDEX `user_id`(`user_id` ASC) USING BTREE,
  CONSTRAINT `audit_logs_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_german2_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of audit_logs
-- ----------------------------

-- ----------------------------
-- Table structure for impressions
-- ----------------------------
DROP TABLE IF EXISTS `impressions`;
CREATE TABLE `impressions`  (
  `impression_id` bigint NOT NULL COMMENT '展示记录唯一标识',
  `ad_id` bigint NOT NULL COMMENT '广告ID',
  `display_time` datetime NOT NULL COMMENT '展示时间',
  `click_count` int NOT NULL COMMENT '点击量',
  `position` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_german2_ci NULL DEFAULT NULL COMMENT '展示位置',
  PRIMARY KEY (`impression_id`) USING BTREE,
  INDEX `display_time`(`display_time` ASC) USING BTREE,
  INDEX `ad_id`(`ad_id` ASC) USING BTREE,
  CONSTRAINT `impressions_ibfk_1` FOREIGN KEY (`ad_id`) REFERENCES `ads` (`ad_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_german2_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of impressions
-- ----------------------------

-- ----------------------------
-- Table structure for invoices
-- ----------------------------
DROP TABLE IF EXISTS `invoices`;
CREATE TABLE `invoices`  (
  `invoice_id` bigint NOT NULL COMMENT '发票唯一标识',
  `order_id` bigint NOT NULL COMMENT '关联订单ID',
  `company_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_german2_ci NOT NULL COMMENT '公司名称',
  `tax_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_german2_ci NOT NULL COMMENT '税号',
  `amount` decimal(15, 2) NOT NULL COMMENT '开票金额',
  `status` enum('unpaid','paid') CHARACTER SET utf8mb4 COLLATE utf8mb4_german2_ci NOT NULL DEFAULT 'unpaid' COMMENT '状态',
  `issued_at` datetime NOT NULL COMMENT '开票时间',
  PRIMARY KEY (`invoice_id`) USING BTREE,
  INDEX `order_id`(`order_id` ASC) USING BTREE,
  CONSTRAINT `invoices_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_german2_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of invoices
-- ----------------------------

-- ----------------------------
-- Table structure for orders
-- ----------------------------
DROP TABLE IF EXISTS `orders`;
CREATE TABLE `orders`  (
  `order_id` bigint NOT NULL COMMENT '订单唯一标识',
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `ad_id` bigint NOT NULL COMMENT '广告ID',
  `quantity` int NOT NULL COMMENT '购买数量',
  `total_amount` decimal(15, 2) NOT NULL COMMENT '总金额',
  `order_time` datetime NOT NULL COMMENT '下单时间',
  PRIMARY KEY (`order_id`) USING BTREE,
  INDEX `order_time`(`order_time` ASC) USING BTREE,
  INDEX `user_id`(`user_id` ASC) USING BTREE,
  INDEX `ad_id`(`ad_id` ASC) USING BTREE,
  CONSTRAINT `orders_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `orders_ibfk_2` FOREIGN KEY (`ad_id`) REFERENCES `ads` (`ad_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_german2_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of orders
-- ----------------------------

-- ----------------------------
-- Table structure for recharges
-- ----------------------------
DROP TABLE IF EXISTS `recharges`;
CREATE TABLE `recharges`  (
  `recharge_id` bigint NOT NULL COMMENT '充值记录唯一标识',
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `amount` decimal(15, 2) NOT NULL COMMENT '充值金额',
  `payment_method` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_german2_ci NOT NULL COMMENT '支付方式',
  `transaction_no` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_german2_ci NULL DEFAULT NULL COMMENT '交易流水号',
  `status` enum('pending','processing','success','failed','expired','canceled','refunded') CHARACTER SET utf8mb4 COLLATE utf8mb4_german2_ci NOT NULL COMMENT '状态（success等）',
  `created_at` datetime NOT NULL COMMENT '充值时间',
  PRIMARY KEY (`recharge_id`) USING BTREE,
  INDEX `created_at`(`created_at` ASC) USING BTREE,
  INDEX `user_id`(`user_id` ASC) USING BTREE,
  CONSTRAINT `recharges_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_german2_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of recharges
-- ----------------------------

-- ----------------------------
-- Table structure for users
-- ----------------------------
DROP TABLE IF EXISTS `users`;
CREATE TABLE `users`  (
  `user_id` bigint NOT NULL COMMENT '用户唯一标识',
  `username` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_german2_ci NOT NULL COMMENT '用户名',
  `password` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_german2_ci NOT NULL COMMENT '密码（加密存储）',
  `contact` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_german2_ci NULL DEFAULT NULL COMMENT '联系方式',
  `company` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_german2_ci NULL DEFAULT NULL COMMENT '公司名称',
  `role` enum('client','admin') CHARACTER SET utf8mb4 COLLATE utf8mb4_german2_ci NOT NULL DEFAULT 'client' COMMENT '角色（client/admin）',
  `balance` decimal(15, 2) NOT NULL COMMENT '账户余额',
  `created_at` datetime NOT NULL COMMENT '创建时间',
  PRIMARY KEY (`user_id`) USING BTREE,
  INDEX `user_id`(`user_id` ASC, `username` ASC, `password` ASC, `contact` ASC, `company` ASC, `role` ASC, `balance` ASC, `created_at` ASC) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_german2_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of users
-- ----------------------------

SET FOREIGN_KEY_CHECKS = 1;
