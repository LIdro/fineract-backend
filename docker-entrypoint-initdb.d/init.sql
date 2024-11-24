-- Create databases if they don't exist
CREATE DATABASE IF NOT EXISTS fineract_tenants CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS fineract_default CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Create user if it doesn't exist and grant privileges
CREATE USER IF NOT EXISTS 'fineract'@'%' IDENTIFIED BY 'fineract';
GRANT ALL PRIVILEGES ON fineract_tenants.* TO 'fineract'@'%';
GRANT ALL PRIVILEGES ON fineract_default.* TO 'fineract'@'%';
FLUSH PRIVILEGES;
