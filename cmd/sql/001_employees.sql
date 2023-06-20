-- DROP DATABASE IF EXISTS sql_blog_soft_delete;
CREATE DATABASE IF NOT EXISTS sql_blog_soft_delete;

USE sql_blog_soft_delete;

-- DROP TABLE IF EXISTS employees;
CREATE TABLE IF NOT EXISTS employees (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    uuid TEXT(36) DEFAULT (UUID()),
    first_name TEXT DEFAULT '',
    last_name TEXT DEFAULT '',
    email_address TEXT NOT NULL,
    deleted BOOLEAN DEFAULT false,
    version INT DEFAULT 1,
    last_updated DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_updated_by TEXT NOT NULL DEFAULT CURRENT_USER,
    UNIQUE(email_address),
    UNIQUE(uuid)
) ENGINE = InnoDB;

-- KIM: these triggers will override any values provided for
--  timestamp, user or version to ensure they're maintained within
--  the context of audit
-- DROP TRIGGER IF EXISTS employees_audit_info_update;
DELIMITER $$
CREATE TRIGGER employees_audit_info_update
BEFORE UPDATE
    ON employees FOR EACH ROW
BEGIN
    SET new.version = old.version+1, new.last_updated = CURRENT_TIMESTAMP, new.last_updated_by = CURRENT_USER;
END$$
DELIMITER ;

-- DROP TABLE IF EXISTS employees_audit;
CREATE TABLE IF NOT EXISTS employees_audit (
    employees_id BIGINT,
    first_name TEXT,
    last_name TEXT,
    email_address TEXT,
    deleted BOOLEAN,
    version INT NOT NULL,
    last_updated DATETIME NOT NULL,
    last_updated_by TEXT NOT NULL,
    FOREIGN KEY (employees_id) REFERENCES employees(id) ON DELETE CASCADE,
    UNIQUE(employees_id, version)
) ENGINE = InnoDB;

-- DROP TRIGGER IF EXISTS employees_audit_insert;
DELIMITER $$
CREATE TRIGGER employees_audit_insert
AFTER INSERT
    ON employees FOR EACH ROW BEGIN
INSERT INTO
    employees_audit(employees_id, first_name, last_name, email_address, deleted, version, last_updated, last_updated_by)
values
    (new.id, new.first_name,  new.last_name, new.email_address, new.deleted, new.version, new.last_updated, new.last_updated_by);
END$$
DELIMITER ;

-- DROP TRIGGER IF EXISTS employees_audit_update;
DELIMITER $$
CREATE TRIGGER employees_audit_update
AFTER UPDATE
    ON employees FOR EACH ROW BEGIN
INSERT INTO
    employees_audit(employees_id, first_name, last_name, email_address, deleted, version, last_updated, last_updated_by)
values
    (new.id, new.first_name,  new.last_name, new.email_address, new.deleted, new.version, new.last_updated, new.last_updated_by);
END$$
DELIMITER ;

INSERT INTO employees(email_address,first_name,last_name) 
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
