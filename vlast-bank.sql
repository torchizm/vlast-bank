-- --------------------------------------------------------
-- Sunucu:                       vlasttest.com
-- Sunucu sürümü:                10.6.4-MariaDB - mariadb.org binary distribution
-- Sunucu İşletim Sistemi:       Win64
-- HeidiSQL Sürüm:               11.1.0.6116
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!50503 SET NAMES utf8mb4 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;


-- es_vlast için veritabanı yapısı dökülüyor
CREATE DATABASE IF NOT EXISTS `es_vlast` /*!40100 DEFAULT CHARACTER SET utf8mb3 */;
USE `es_vlast`;

-- tablo yapısı dökülüyor es_vlast.bank_logs
CREATE TABLE IF NOT EXISTS `bank_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `transmitter` varchar(50) NOT NULL,
  `receiver` varchar(50) NOT NULL,
  `amount` int(11) NOT NULL DEFAULT 0,
  `description` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=20971 DEFAULT CHARSET=utf8mb3;

-- Veri çıktısı seçilmemişti

/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IF(@OLD_FOREIGN_KEY_CHECKS IS NULL, 1, @OLD_FOREIGN_KEY_CHECKS) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
