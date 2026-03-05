-- Pay & Bill (paynbill) - main and email DBs
CREATE DATABASE IF NOT EXISTS ipb_system CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS ipb_emails CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS ipb_test CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS ipb_harmonic CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS otm_laravelstaging CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS user_management CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS sjethwa_ttmdev CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS clientportal CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;


CREATE USER IF NOT EXISTS 'u_system'@'%' IDENTIFIED BY 'Ipb@Syst3m';
CREATE USER IF NOT EXISTS 'u_emails'@'%' IDENTIFIED BY 'Ipb@Emai1s';
CREATE USER IF NOT EXISTS 'u_test'@'%' IDENTIFIED BY 'Ipb@T3st';
CREATE USER IF NOT EXISTS 'u_harmonic'@'%' IDENTIFIED BY 'Ipb@Harm0n1c';
CREATE USER IF NOT EXISTS 'db_otm'@'%' IDENTIFIED BY 'otm@!23';
CREATE USER IF NOT EXISTS 'u_usermanagement'@'%' IDENTIFIED BY 'ipbu@@mgmt$htr0v2415';
CREATE USER IF NOT EXISTS 'ttmdev'@'%' IDENTIFIED BY 'TTMDev123';
CREATE USER IF NOT EXISTS 'clientportal'@'%' IDENTIFIED BY 'UpL@r@Cl!P0rt@l';
GRANT ALL PRIVILEGES ON ipb_system.* TO 'u_system'@'%';
GRANT ALL PRIVILEGES ON ipb_emails.* TO 'u_emails'@'%';
GRANT ALL PRIVILEGES ON ipb_test.* TO 'u_test'@'%';
GRANT ALL PRIVILEGES ON ipb_harmonic.* TO 'u_harmonic'@'%';
GRANT ALL PRIVILEGES ON otm_laravelstaging.* TO 'db_otm'@'%';
GRANT ALL PRIVILEGES ON user_management.* TO 'u_usermanagement'@'%';
GRANT ALL PRIVILEGES ON sjethwa_ttmdev.* TO 'ttmdev'@'%';
GRANT ALL PRIVILEGES ON clientportal.* TO 'clientportal'@'%';


FLUSH PRIVILEGES;