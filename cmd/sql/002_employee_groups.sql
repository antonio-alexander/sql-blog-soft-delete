-- DROP DATABASE IF EXISTS sql_blog_soft_delete;
CREATE DATABASE IF NOT EXISTS sql_blog_soft_delete;

USE sql_blog_soft_delete;

-- DROP TABLE IF EXISTS employee_groups;
CREATE TABLE IF NOT EXISTS employee_groups (
    id BIGINT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    uuid TEXT(36) NOT NULL DEFAULT (UUID()),
    name TEXT NOT NULL,
    deleted BOOLEAN DEFAULT false,
    version INT NOT NULL DEFAULT 1,
    last_updated DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_updated_by TEXT NOT NULL DEFAULT CURRENT_USER,
    UNIQUE(name),
    UNIQUE(uuid)
) ENGINE = InnoDB;

-- DROP TABLE IF EXISTS employee_groups_audit;
CREATE TABLE IF NOT EXISTS employee_groups_audit (
    employee_group_id BIGINT,
    name TEXT,
    deleted BOOLEAN,
    version INT NOT NULL,
    last_updated DATETIME NOT NULL,
    last_updated_by TEXT NOT NULL,
    FOREIGN KEY (employee_group_id) REFERENCES employee_groups(id) ON DELETE CASCADE,
    PRIMARY KEY (employee_group_id, version)
) ENGINE = InnoDB;

-- KIM: these triggers will override any values provided for
--  timestamp, user or version to ensure they're maintained within
--  the context of audit
-- DROP TRIGGER IF EXISTS employee_groups_audit_info_update;
DELIMITER $$
CREATE TRIGGER employee_groups_audit_info_update
BEFORE UPDATE
    ON employee_groups FOR EACH ROW
BEGIN
    SET new.version = old.version+1, new.last_updated = CURRENT_TIMESTAMP, new.last_updated_by = CURRENT_USER;
END$$
DELIMITER ;

-- DROP TRIGGER IF EXISTS employee_groups_audit_insert;
DELIMITER $$
CREATE TRIGGER employee_groups_audit_insert
AFTER INSERT
    ON employee_groups FOR EACH ROW BEGIN
INSERT INTO
    employee_groups_audit(employee_id, first_name, last_name, email_address, deleted, version, last_updated, last_updated_by)
values
    (new.id, new.first_name,  new.last_name, new.email_address, new.deleted, new.version, new.last_updated, new.last_updated_by);
END$$
DELIMITER ;

-- DROP TRIGGER IF EXISTS employee_groups_audit_update;
DELIMITER $$
CREATE TRIGGER employee_groups_audit_update
AFTER UPDATE
    ON employee_groups FOR EACH ROW BEGIN
INSERT INTO
    employee_groups_audit(employee_id, first_name, last_name, email_address, deleted, version, last_updated, last_updated_by)
values
    (new.id, new.first_name,  new.last_name, new.email_address, new.deleted, new.version, new.last_updated, new.last_updated_by);
END$$
DELIMITER ;

-- DROP TABLE IF EXISTS employee_group_membership;
CREATE TABLE IF NOT EXISTS employee_group_membership (
    employee_group_id BIGINT NOT NULL,
    employee_id BIGINT NOT NULL,
    deleted BOOLEAN NOT NULL DEFAULT false,
    FOREIGN KEY (employee_group_id) REFERENCES employee_groups(id) ON DELETE CASCADE,
    FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE,
    UNIQUE(employee_group_id, employee_id)
) ENGINE = InnoDB;

INSERT INTO employee_groups(name)
    VALUES ('house_atreides'),('house_harkonnen'),('fremen'),('house_corrino');

INSERT INTO employee_group_membership(employee_group_id,employee_id)
    VALUES
        ((SELECT id FROM employee_groups WHERE name='house_atreides' LIMIT 1), (SELECT id FROM employees WHERE email_address='leto.atreides@house_atreides.com' LIMIT 1)),
        ((SELECT id FROM employee_groups WHERE name='house_atreides' LIMIT 1), (SELECT id FROM employees WHERE email_address='paul.atreides@house_atreides.com' LIMIT 1)),
        ((SELECT id FROM employee_groups WHERE name='house_atreides' LIMIT 1), (SELECT id FROM employees WHERE email_address='jessica.atreides@house_atreides.com' LIMIT 1)),
        ((SELECT id FROM employee_groups WHERE name='house_atreides' LIMIT 1), (SELECT id FROM employees WHERE email_address='alia.atreides@house_atreides.com' LIMIT 1)),
        ((SELECT id FROM employee_groups WHERE name='house_harkonnen' LIMIT 1), (SELECT id FROM employees WHERE email_address='abulurd.harkonnen@house_harkonnen.com' LIMIT 1)),
        ((SELECT id FROM employee_groups WHERE name='house_harkonnen' LIMIT 1), (SELECT id FROM employees WHERE email_address='abulurd.rabban@house_harkonnen.com' LIMIT 1)),
        ((SELECT id FROM employee_groups WHERE name='house_harkonnen' LIMIT 1), (SELECT id FROM employees WHERE email_address='feyd-rautha.harkonnen@house_harkonnen.com' LIMIT 1)),
        ((SELECT id FROM employee_groups WHERE name='house_harkonnen' LIMIT 1), (SELECT id FROM employees WHERE email_address='glossu.rabban.harkonnen@house_harkonnen.com' LIMIT 1)),
        ((SELECT id FROM employee_groups WHERE name='house_harkonnen' LIMIT 1), (SELECT id FROM employees WHERE email_address='vladimir.harkonnen@house_harkonnen.com' LIMIT 1)),
        ((SELECT id FROM employee_groups WHERE name='fremen' LIMIT 1), (SELECT id FROM employees WHERE email_address='paul.atreides@house_atreides.com' LIMIT 1)),
        ((SELECT id FROM employee_groups WHERE name='fremen' LIMIT 1), (SELECT id FROM employees WHERE email_address='leto.atreides@house_atreides.com' LIMIT 1)),
        ((SELECT id FROM employee_groups WHERE name='fremen' LIMIT 1), (SELECT id FROM employees WHERE email_address='chani.kynes@fremen.com' LIMIT 1)),
        ((SELECT id FROM employee_groups WHERE name='fremen' LIMIT 1), (SELECT id FROM employees WHERE email_address='liet.kynes@fremen.com' LIMIT 1)),
        ((SELECT id FROM employee_groups WHERE name='fremen' LIMIT 1), (SELECT id FROM employees WHERE email_address='naib.stilgar@fremen.com' LIMIT 1)),
        ((SELECT id FROM employee_groups WHERE name='house_corrino' LIMIT 1), (SELECT id FROM employees WHERE email_address='shaddam.corrino@house_corrino.com' LIMIT 1)),
        ((SELECT id FROM employee_groups WHERE name='house_corrino' LIMIT 1), (SELECT id FROM employees WHERE email_address='irulan.corrino@house_corrino.com' LIMIT 1)),
        ((SELECT id FROM employee_groups WHERE name='house_corrino' LIMIT 1), (SELECT id FROM employees WHERE email_address='wensicia.corrino@house_corrino.com' LIMIT 1)),
        ((SELECT id FROM employee_groups WHERE name='house_corrino' LIMIT 1), (SELECT id FROM employees WHERE email_address='faradn.corrino@house_corrino.com' LIMIT 1));
