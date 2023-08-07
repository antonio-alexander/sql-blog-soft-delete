-- DROP DATABASE IF EXISTS sql_blog_soft_delete;
CREATE DATABASE IF NOT EXISTS sql_blog_soft_delete;

USE sql_blog_soft_delete;

-- DROP TABLE IF EXISTS employee_group;
CREATE TABLE IF NOT EXISTS employee_group (
    employee_group_id BIGINT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    employee_group_uuid TEXT(36) NOT NULL DEFAULT (UUID()),
    employee_group_name TEXT NOT NULL,
    employee_group_deleted BOOLEAN DEFAULT false,
    employee_group_version INT NOT NULL DEFAULT 1,
    employee_group_last_updated DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    employee_group_last_updated_by TEXT NOT NULL DEFAULT CURRENT_USER,
    UNIQUE(employee_group_name),
    UNIQUE(employee_group_uuid)
) ENGINE = InnoDB;

-- DROP TABLE IF EXISTS employee_group_audit;
CREATE TABLE IF NOT EXISTS employee_group_audit (
    employee_group_id BIGINT,
    employee_group_name TEXT,
    employee_group_deleted BOOLEAN,
    employee_group_version INT NOT NULL,
    employee_group_last_updated DATETIME NOT NULL,
    employee_group_last_updated_by TEXT NOT NULL,
    FOREIGN KEY (employee_group_id) REFERENCES employee_group(employee_group_id) ON DELETE CASCADE,
    PRIMARY KEY (employee_group_id, employee_group_version)
) ENGINE = InnoDB;

-- KIM: these triggers will override any values provided for
--  timestamp, user or version to ensure they're maintained within
--  the context of audit
-- DROP TRIGGER IF EXISTS employee_group_audit_info_update;
DELIMITER $$
CREATE TRIGGER employee_group_audit_info_update
BEFORE UPDATE
    ON employee_group FOR EACH ROW
BEGIN
    SET new.employee_group_version = old.employee_group_version+1, new.employee_group_last_updated = CURRENT_TIMESTAMP, new.employee_group_last_updated_by = CURRENT_USER;
END$$
DELIMITER ;

-- DROP TRIGGER IF EXISTS employee_group_audit_insert;
DELIMITER $$
CREATE TRIGGER employee_group_audit_insert
AFTER INSERT
    ON employee_group FOR EACH ROW BEGIN
INSERT INTO
    employee_group_audit(employee_group_id, employee_group_name, employee_group_deleted, employee_group_version, employee_group_last_updated, employee_group_last_updated_by)
values
    (new.employee_group_id, new.employee_group_name, new.employee_group_deleted, new.employee_group_version, new.employee_group_last_updated, new.employee_group_last_updated_by);
END$$
DELIMITER ;

-- DROP TRIGGER IF EXISTS employee_group_audit_update;
DELIMITER $$
CREATE TRIGGER employee_group_audit_update
AFTER UPDATE
    ON employee_group FOR EACH ROW BEGIN
INSERT INTO
    employee_group_audit(employee_group_id, employee_group_name, employee_group_deleted, employee_group_version, employee_group_last_updated, employee_group_last_updated_by)
values
    (new.employee_group_id, new.employee_group_name, new.employee_group_deleted, new.employee_group_version, new.employee_group_last_updated, new.employee_group_last_updated_by);
END$$
DELIMITER ;

-- DROP TABLE IF EXISTS employee_group_membership;
CREATE TABLE IF NOT EXISTS employee_group_membership (
    employee_group_id BIGINT NOT NULL,
    employee_id BIGINT NOT NULL,
    employee_group_membership_deleted BOOLEAN NOT NULL DEFAULT false,
    FOREIGN KEY (employee_group_id) REFERENCES employee_group(employee_group_id) ON DELETE CASCADE,
    FOREIGN KEY (employee_id) REFERENCES employee(employee_id) ON DELETE CASCADE,
    UNIQUE(employee_group_id, employee_id)
) ENGINE = InnoDB;

INSERT INTO employee_group(employee_group_name)
    VALUES ('house_atreides'),('house_harkonnen'),('fremen'),('house_corrino');

INSERT INTO employee_group_membership(employee_group_id,employee_id)
    VALUES
        ((SELECT employee_group_id FROM employee_group WHERE employee_group_name='house_atreides' LIMIT 1), (SELECT employee_id FROM employee WHERE employee_email_address='leto.atreides@house_atreides.com' LIMIT 1)),
        ((SELECT employee_group_id FROM employee_group WHERE employee_group_name='house_atreides' LIMIT 1), (SELECT employee_id FROM employee WHERE employee_email_address='paul.atreides@house_atreides.com' LIMIT 1)),
        ((SELECT employee_group_id FROM employee_group WHERE employee_group_name='house_atreides' LIMIT 1), (SELECT employee_id FROM employee WHERE employee_email_address='jessica.atreides@house_atreides.com' LIMIT 1)),
        ((SELECT employee_group_id FROM employee_group WHERE employee_group_name='house_atreides' LIMIT 1), (SELECT employee_id FROM employee WHERE employee_email_address='alia.atreides@house_atreides.com' LIMIT 1)),
        ((SELECT employee_group_id FROM employee_group WHERE employee_group_name='house_harkonnen' LIMIT 1), (SELECT employee_id FROM employee WHERE employee_email_address='abulurd.harkonnen@house_harkonnen.com' LIMIT 1)),
        ((SELECT employee_group_id FROM employee_group WHERE employee_group_name='house_harkonnen' LIMIT 1), (SELECT employee_id FROM employee WHERE employee_email_address='abulurd.rabban@house_harkonnen.com' LIMIT 1)),
        ((SELECT employee_group_id FROM employee_group WHERE employee_group_name='house_harkonnen' LIMIT 1), (SELECT employee_id FROM employee WHERE employee_email_address='feyd-rautha.harkonnen@house_harkonnen.com' LIMIT 1)),
        ((SELECT employee_group_id FROM employee_group WHERE employee_group_name='house_harkonnen' LIMIT 1), (SELECT employee_id FROM employee WHERE employee_email_address='glossu.rabban.harkonnen@house_harkonnen.com' LIMIT 1)),
        ((SELECT employee_group_id FROM employee_group WHERE employee_group_name='house_harkonnen' LIMIT 1), (SELECT employee_id FROM employee WHERE employee_email_address='vladimir.harkonnen@house_harkonnen.com' LIMIT 1)),
        ((SELECT employee_group_id FROM employee_group WHERE employee_group_name='fremen' LIMIT 1), (SELECT employee_id FROM employee WHERE employee_email_address='paul.atreides@house_atreides.com' LIMIT 1)),
        ((SELECT employee_group_id FROM employee_group WHERE employee_group_name='fremen' LIMIT 1), (SELECT employee_id FROM employee WHERE employee_email_address='leto.atreides@house_atreides.com' LIMIT 1)),
        ((SELECT employee_group_id FROM employee_group WHERE employee_group_name='fremen' LIMIT 1), (SELECT employee_id FROM employee WHERE employee_email_address='chani.kynes@fremen.com' LIMIT 1)),
        ((SELECT employee_group_id FROM employee_group WHERE employee_group_name='fremen' LIMIT 1), (SELECT employee_id FROM employee WHERE employee_email_address='liet.kynes@fremen.com' LIMIT 1)),
        ((SELECT employee_group_id FROM employee_group WHERE employee_group_name='fremen' LIMIT 1), (SELECT employee_id FROM employee WHERE employee_email_address='naib.stilgar@fremen.com' LIMIT 1)),
        ((SELECT employee_group_id FROM employee_group WHERE employee_group_name='house_corrino' LIMIT 1), (SELECT employee_id FROM employee WHERE employee_email_address='shaddam.corrino@house_corrino.com' LIMIT 1)),
        ((SELECT employee_group_id FROM employee_group WHERE employee_group_name='house_corrino' LIMIT 1), (SELECT employee_id FROM employee WHERE employee_email_address='irulan.corrino@house_corrino.com' LIMIT 1)),
        ((SELECT employee_group_id FROM employee_group WHERE employee_group_name='house_corrino' LIMIT 1), (SELECT employee_id FROM employee WHERE employee_email_address='wensicia.corrino@house_corrino.com' LIMIT 1)),
        ((SELECT employee_group_id FROM employee_group WHERE employee_group_name='house_corrino' LIMIT 1), (SELECT employee_id FROM employee WHERE employee_email_address='faradn.corrino@house_corrino.com' LIMIT 1));
