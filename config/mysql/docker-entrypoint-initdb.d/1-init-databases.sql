CREATE DATABASE IF NOT EXISTS `fineract_tenants`;
CREATE DATABASE IF NOT EXISTS `fineract_default`;

USE `fineract_tenants`;

CREATE TABLE IF NOT EXISTS `tenants` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(100) NOT NULL,
  `name` varchar(100) NOT NULL,
  `schema_name` varchar(100) NOT NULL,
  `timezone_id` varchar(100) NOT NULL,
  `country_id` int(11) DEFAULT NULL,
  `joined_date` date DEFAULT NULL,
  `created_date` datetime DEFAULT NULL,
  `lastmodified_date` datetime DEFAULT NULL,
  `schema_server` varchar(100) NOT NULL DEFAULT 'localhost',
  `schema_server_port` varchar(10) NOT NULL DEFAULT '3306',
  `schema_connection_parameters` text DEFAULT NULL,
  `schema_username` varchar(100) NOT NULL DEFAULT 'root',
  `schema_password` varchar(100) NOT NULL DEFAULT 'mysql',
  `auto_update` tinyint(1) NOT NULL DEFAULT '1',
  `pool_initial_size` int(11) DEFAULT '5',
  `pool_validation_interval` int(11) DEFAULT '30000',
  `pool_remove_abandoned` tinyint(1) DEFAULT '1',
  `pool_remove_abandoned_timeout` int(11) DEFAULT '60',
  `pool_log_abandoned` tinyint(1) DEFAULT '1',
  `pool_abandon_when_percentage_full` int(11) DEFAULT '50',
  `pool_test_on_borrow` tinyint(1) DEFAULT '1',
  `pool_max_active` int(11) DEFAULT '40',
  `pool_min_idle` int(11) DEFAULT '20',
  `pool_max_idle` int(11) DEFAULT '10',
  `pool_suspect_timeout` int(11) DEFAULT '60',
  `pool_time_between_eviction_runs_millis` int(11) DEFAULT '34000',
  `pool_min_evictable_idle_time_millis` int(11) DEFAULT '60000',
  `deadlock_max_retries` int(11) DEFAULT '0',
  `deadlock_max_retry_interval` int(11) DEFAULT '1',
  `oltp_max_retries` int(11) DEFAULT '0',
  `oltp_max_retry_interval` int(11) DEFAULT '1',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT IGNORE INTO `tenants` (`id`, `identifier`, `name`, `schema_name`, `timezone_id`, `schema_server`, `schema_username`, `schema_password`)
VALUES (1, 'default', 'Default Tenant', 'fineract_default', 'Asia/Kolkata', 'mariadb', 'root', 'mysql');
