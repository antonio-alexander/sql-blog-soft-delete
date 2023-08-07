-- DROP DATABASE IF EXISTS sql_blog_soft_delete;
CREATE DATABASE IF NOT EXISTS sql_blog_soft_delete;

USE sql_blog_soft_delete;

-- DROP TABLE IF EXISTS employee;
CREATE TABLE IF NOT EXISTS employee (
    employee_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    employee_uuid TEXT(36) DEFAULT (UUID()),
    employee_first_name TEXT DEFAULT '',
    employee_last_name TEXT DEFAULT '',
    employee_email_address TEXT NOT NULL,
    employee_deleted BOOLEAN DEFAULT false,
    employee_version INT DEFAULT 1,
    employee_last_updated DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    employee_last_updated_by TEXT NOT NULL DEFAULT CURRENT_USER,
    UNIQUE(employee_email_address),
    UNIQUE(employee_uuid)
) ENGINE = InnoDB;

-- KIM: these triggers will override any values provided for
--  timestamp, user or version to ensure they're maintained within
--  the context of audit
-- DROP TRIGGER IF EXISTS employee_audit_info_update;
DELIMITER $$
CREATE TRIGGER employee_audit_info_update
BEFORE UPDATE
    ON employee FOR EACH ROW
BEGIN
    SET new.employee_version = old.employee_version+1, new.employee_employee_last_updated = CURRENT_TIMESTAMP, new.employee_last_updated_by = CURRENT_USER;
END$$
DELIMITER ;

-- DROP TABLE IF EXISTS employee_audit;
CREATE TABLE IF NOT EXISTS employee_audit (
    employee_id BIGINT,
    employee_first_name TEXT,
    employee_last_name TEXT,
    employee_email_address TEXT,
    employee_deleted BOOLEAN,
    employee_version INT NOT NULL,
    employee_last_updated DATETIME NOT NULL,
    employee_last_updated_by TEXT NOT NULL,
    FOREIGN KEY (employee_id) REFERENCES employee(employee_id) ON DELETE CASCADE,
    UNIQUE(employee_id, employee_version)
) ENGINE = InnoDB;

-- DROP TRIGGER IF EXISTS employee_audit_insert;
DELIMITER $$
CREATE TRIGGER employee_audit_insert
AFTER INSERT
    ON employee FOR EACH ROW BEGIN
INSERT INTO
    employee_audit(employee_id, employee_first_name, employee_last_name, employee_email_address, employee_deleted, employee_version, employee_last_updated, employee_last_updated_by)
values
    (new.employee_id, new.employee_first_name,  new.employee_last_name, new.employee_email_address, new.employee_deleted, new.employee_version, new.employee_last_updated, new.employee_last_updated_by);
END$$
DELIMITER ;

-- DROP TRIGGER IF EXISTS employee_audit_update;
DELIMITER $$
CREATE TRIGGER employee_audit_update
AFTER UPDATE
    ON employee FOR EACH ROW BEGIN
INSERT INTO
    employee_audit(employee_id, employee_first_name, employee_last_name, employee_email_address, employee_deleted, employee_version, employee_last_updated, employee_last_updated_by)
values
    (new.employee_id, new.employee_first_name,  new.employee_last_name, new.employee_email_address, new.employee_deleted, new.employee_version, new.employee_last_updated, new.employee_last_updated_by);
END$$
DELIMITER ;

INSERT INTO employee(employee_email_address,employee_first_name,employee_last_name) 
    VALUES
        ('leto.atreides@house_atreides.com','Leto','Atreides'),
        ('paul.atreides@house_atreides.com','Paul','Atreides'),
        ('jessica.atreides@house_atreides.com','Jessica','Atreides'),
        ('alia.atreides@house_atreides.com','Alia','Atreides'),
        ('abulurd.harkonnen@house_harkonnen.com','Abulurd','Harkonnen'),
        ('abulurd.rabban@house_harkonnen.com','Abulurd','Rabban'),
        ('feyd-rautha.harkonnen@house_harkonnen.com','Feyd-Rautha','Harkonnen'),
        ('glossu.rabban.harkonnen@house_harkonnen.com','Glossu Rabban','Harkonnen'),
        ('vladimir.harkonnen@house_harkonnen.com','Vladimir','Harkonnen'),
        ('chani.kynes@fremen.com','Chani','Kynes'),
        ('liet.kynes@fremen.com','Liet','Kynes'),
        ('naib.stilgar@fremen.com','Naib','Stilgar'),
        ('shaddam.corrino@house_corrino.com','Shaddam','Corrino'),
        ('irulan.corrino@house_corrino.com','Irulan','Corrino'),
        ('wensicia.corrino@house_corrino.com','Wensicia','Corrino'),
        ('faradn.corrino@house_corrino.com','Faradn','Corrino');
