# sql-blog-soft-delete (github.com/antonio-alexander/sql-blog-soft-delete)

The purpsoe of this repository is to review (and research) soft-deletes and provide some opinions on implementation and use cases. The things I want to research/understand are:

- What are soft-deletes?
- What's the purpose of a soft-delete?
- How to implement soft-deletes?
- How do soft-deletes affect queries?
- Do soft-deletes affect auditing?
- How can you implement a soft-delete with foreign keys?

## TLDR; Too Long Didn't Read

A soft delete, in contract to a hard delete, gives you the ability to indicate that a row has been deleted without removing the row altogether. In general, soft-deletes are recognized only within a given application rather than in the database itself. From the database's perspective, the data has only changed (had the deleted flag set) but is still present, while from the perspective of the API/software, the row has been deleted.

## Getting Started

This example is really simple, to get mysql up and running with seed data and the appropriate schemas you can execute the following command from the root of the repository:

```sh
docker compose up -d
```

At this point you can exec into the container using the following command:

```sql
docker exec -it mysql /bin/ash
```

Alternatively, you can execute the sql client within the container to try some of the examples:

```sql
docker exec -it mysql mysql -uroot -pmysql sql_blog_soft_delete
```

## What's a soft-delete

I think it's easier to describe what a hard-delete is before describing a soft-delete. A hard-delete is a destructive operation that removes data; a hard-delete is often an un-recoverable event. Soft-deletes on the other hand, generally set a flag marking the row as deleted and leaves it to the software or api to filter those soft-deletes rows from a given query. So in short, if a row has been soft-deleted, it should no longer exist from the perspective of the application/api.

I think the biggest motivation to implement soft-deletes has a lot to do with data recovery. From the perspective of the datbase, backups and restorations occur in aggregate: to ALL of the data. It's not practically possible to restore a _row_. It's __possible__, but generally you wouldn't be able to. For example, backups for databases are almost identical to IT (information technology) [backups](https://en.wikipedia.org/wiki/Backup); a backup schedule could be weekly full backups and daily [incremental](https://en.wikipedia.org/wiki/Incremental_backup) backups. To do an actual restore or at least restore to a test database to get the _row_ of data, you'd take the latest full backups and restore the differential backups up until the day in question and "restore" that row.

The impractical part about this is that backups are points in time and could miss the data mutations you want to undo. If you perform backups at midnight, then its possible for someone to both create a row and delete it within that twelve hour period. In this case it's impossible to recover the data; from the perspective of the backups, the data DOES NOT exist.

Soft-deletes can be a practical solve for this problem; with soft-deletes you can have a "settle" time for pruning (or hard deleting) data that has been deleted such that it's _seen_ by the backup. In addition; soft-deletes give you the ability to un-delete data at will. If someone accidentally deletes data or purposefully deletes data that shouldn't be deleted; you have an option to remedy the situation.

> The sky is the limit, you could do this _manually_ such that it isn't available via API and can only be done manually by an admin OR you could integrate it into your API. You can use the 80/20 rule to determine if un-deleting should be a part of your API; if it's something you do 80% of the time, then it should be a part of the API

## Architecture

A common question of database architecture is how much logic you want to store in the database and how much logic you want to store in the application. I think from a practical standpoint, although changing databases is a thing, it's VERY VERY low on the list, so it should __NEVER__ be used as an excuse to make one decision or another. It's unlikely that your application requires being database agnostic and even more so, if you have ANY desire for optimization, they're going to be heavily coupled to your database.

I think you should ask yourself (and your team) the following question to direct the general solution you use. These are not just for soft-deletes, but are general for any kind of database integration.

1. Where does your team's expertise lie? In writing the application or the database?
2. Is the application in a place to properly implement the solutions you're trying to do?
3. Is the database the best place to put this logic?

> It's a good rule of thumb to place the logic as close to the thing that it affects as possible. My opinion is that the database doesn't really care about "soft-deletes"; from the perspective of the database, it's just a column that is a boolean. The application/api cares about soft-deletes, so the logic for soft-deletes shouldn't be in the database

Although there are some implications for microservices which complicate the topic of foreign key constraints (or the lack thereof), I think we can approach this solution in an agnostic way. Regardless of whether you put this logic in the api/application or within hte database, you _still_ have to have the same functionality.

I think if you implement soft-deletes, you should tailor your functionality around the following "business" rules:

1. Unless explicitly set, any attempts to read objects in aggregate that can be soft-deleted, should not return objects that have been soft-deleted
2. Properties that make a row unique should remain active even if an object is soft-deleted
3. The ability to soft-delete and soft-un-delete should be restricted; you should have different methods to mutate other properties than mutating the deleted property
4. Related objects (e.g. objects that have foreign constraints) should also be soft-deleted as is required by your business logic to maintain data consistency (See rule 1)

> Foreign key constraints is a touchy subject (especially with microservices and their single responsibility principle). In general, to maintain data consistency, you have to soft-delete any child objects to maintain data consistency (and un-delete them in kind). Although not necessary, not having this functionality could create some confusion

> Data consistency is something that we generally leave to the database, but we're adding something that's very un-database-like and as a result we have to add guard rails for that functionality.

Finally, in terms of architecture, there's a conversation about how to structure/organize your queries. I think in general it's a _great_ rule of thumb to keep queries that involve the deleted column local to the table in question. I think it's REALLY easy to over-complicate a schema/architecture by attempting to co-mingle or inter-relate the deleted column from other tables. There will be some queries below that attempt to show this idea.

## Implementation

Within this repo, I've put together a pure sql implementation of employees (and employee groups) to try to show an implementation of soft-deletes. Although i've mentioned microservices and having to code around the single responsibility princple, I think it's better to omit that conversation since the implementation is generally the same. I'll be running all the sql queries manually; if you were to implement it in code, you'd pretty much do the same thing.

> This is half true, but the complexity of it all takes away from the core of what I'm trying to get across

Before we get started, lets talk about business rules in a more concrete way:

- employees must have a non-empty email address
- employees can be soft-deleted by setting the deleted flag to true
- employees can be un-soft-deleted by setting the deleted flag to false
- employee groups must have a non-empty name
- employees can belong to zero or more employee groups
- employee groups can be soft-deleted by setting the deleted flag to true
- employee groups can be un-soft-deleted by setting the deleted flag to false
- if an employee group is hard-deleted, all of the references between employees and that employee group must also be deleted
- if an employee is hard-deleted, they must also be hard-deleted from their employee groups
- if an employee is soft-deleted, they must also be soft-deleted from their employee groups

> You may be asking yourself, what do we do if an employee is un-deleted; should we also un-delete their memberships to other groups? And I think the answer is no, because there's no way to _know_ if an employee was deleted from the group as an __action__ for employee groups or because of employees. The rule becomes ambiguous and it's better to solve that via a process where a user that has been soft-undeleted must also be added __BACK__ to those employee groups he was soft-deleted from

In the remainder of this section, we'll go through our solution/implementation and how we implement schema/architecture (along with examples) to achieve the business rules noted above. It's expected that you either use the [docker-compose.yml](./docker-compose.yml) in this repository or otherwise get the [sql](./sql/) schemas into the database.

### Employees

First, we must seed some data into the employees database:

```sql
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
```

Once the above data has been seeded, we can soft-delete an existing employee by doing the following:

```sql
UPDATE employees SET deleted=true WHERE email_address='paul.atreides@house_atreides.com';
SELECT * FROM employees WHERE email_address='paul.atreides@house_atreides.com';
```

The output should show that deleted is true (or 1) and you should see the version and last_updated fields also be incremented. Although the field is set; it's pretty obvious that the employee is still quite visible. See the output from the following query:

```sql
SELECT * FROM employees;
```

Although it'll list other employees, you'll see that although we've soft-deleted Paul Atreides, he still comes in the query. To _recognize_ this soft-deletion, we'll need to modify our query slightly:

```sql
SELECT * FROM employees WHERE deleted=false;
```

This query will filter out employees that haven't been soft-deleted, while employees who are hard-deleted won't appear at all. This logic is something you'll need to add (generally by default) with all of your queries to a table with rows that can be soft-deleted. If you're worried about foreign key constraints and data consistency; we're a ways off, but we WILL touch on that soon.

### Employee Groups

The employee group implementation is fairly similar to the employee implementation except that in order to implement it's business logic, we need two tables: (1) to hold the information to identify a single group and (2) another to describe the individual, one-to-many relationship between employee groups and employees.

> You may be wondering why we don't have an audit table for the employee_group_membership; and that's primarily for simplicity, but also because short of soft-deleting a membership, there isn't much to change unlike an employee in which you could change the first/last name

To start, we need to seed some employee groups, you can enter the following query to accomplish this:

```sql
INSERT INTO employee_groups(name)
    VALUES ('house_atreides'),('house_harkonnen'),('fremen'),('house_corrino');
```

Now that we have four employee groups, we can add employees to multiple groups with the following query:

```sql
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
        ((SELECT id FROM employee_groups WHERE name='fremen' LIMIT 1), (SELECT id FROM employees WHERE email_address='chani.kynes@fremen.com' LIMIT 1)),
        ((SELECT id FROM employee_groups WHERE name='fremen' LIMIT 1), (SELECT id FROM employees WHERE email_address='liet.kynes@fremen.com' LIMIT 1)),
        ((SELECT id FROM employee_groups WHERE name='fremen' LIMIT 1), (SELECT id FROM employees WHERE email_address='naib.stilgar@fremen.com' LIMIT 1)),
        ((SELECT id FROM employee_groups WHERE name='house_corrino' LIMIT 1), (SELECT id FROM employees WHERE email_address='shaddam.corrino@house_corrino.com' LIMIT 1)),
        ((SELECT id FROM employee_groups WHERE name='house_corrino' LIMIT 1), (SELECT id FROM employees WHERE email_address='irulan.corrino@house_corrino.com' LIMIT 1)),
        ((SELECT id FROM employee_groups WHERE name='house_corrino' LIMIT 1), (SELECT id FROM employees WHERE email_address='wensicia.corrino@house_corrino.com' LIMIT 1)),
        ((SELECT id FROM employee_groups WHERE name='house_corrino' LIMIT 1), (SELECT id FROM employees WHERE email_address='faradn.corrino@house_corrino.com' LIMIT 1));
```

The sub-queries in the above query help us not have to worry about dynamic constants like the uuid and id fields in the employee's table since the email address must be unique and if you've seeded the data, they're already present. We can query the members of a given employee group with the following query:

```sql
SELECT first_name,last_name,email_address FROM employees WHERE id IN(SELECT employee_id FROM employee_group_membership WHERE employee_group_id=(SELECT id FROM employee_groups WHERE name='fremen'));
```

Alternatively, we can list the employee groups a given user is a member of with the following query:

```sql
SELECT name FROM employee_groups WHERE id IN(SELECT employee_group_id FROM employee_group_membership WHERE employee_id=(SELECT id FROM employees WHERE email_address='paul.atreides@house_atreides.com'));
SELECT name FROM employee_groups WHERE id IN(SELECT employee_group_id FROM employee_group_membership WHERE employee_id=(SELECT id FROM employees WHERE email_address='chani.kynes@fremen.com'));
```

Notice that Paul should be a member of two groups (atreides and fremen) while Chani is only a member of the fremen employee group.

We can soft-delete an employee group in a similar way that we do for employees:

```sql
UPDATE employee_groups SET deleted=true WHERE name='house_atreides';
```

Once an employee group is soft-deleted, you can then (similar to employees) query non soft-deleted employee groups with the following query:

```sql
SELECT name from employee_groups WHERE deleted=false;
```

### Interactions between employees and employee groups

Although we can enforce the relationship between employees and employee groups; a lot of this is handled within sql by the presence of a row or lack thereof; by adding soft-deletion into the mix, we create a problem because even though a row has been soft-deleted, as far as sql is concerned it still exists, so it can't do its magic without help. By introducing soft-deletion; we have a very __real__ possibility to break data consistency.

> Breaking data consistency with these two tables can be summed up by the idea that references that have been soft-deleted can be "leaked" without filtering by the deleted column

For example, lets say we've added Paul Atreides to the fremen and house_attreides employee group:

```sql
INSERT INTO employee_groups(name) VALUES ('house_atreides'),('fremen');
INSERT INTO employee_group_membership(employee_group_id,employee_id)
    VALUES
        (SELECT from employee_groups WHERE name='house_atreides' LIMIT 1, SELECT id FROM employees WHERE email_address='leto.atreides@house_atreides.com' LIMIT 1),
        ((SELECT id FROM employee_groups WHERE name='fremen' LIMIT 1), (SELECT id FROM employees WHERE email_address='paul.atreides@house_atreides.com' LIMIT 1));
```

If we were to soft-delete Paul, we'd create a data inconsistency. This is quite obvious when we soft-delete Paul and then query the members of the fremen and house_atreides employee groups:

```sql
UPDATE employees SET deleted=true WHERE email_address='paul.atreides@house_atreides.com';
SELECT first_name,last_name,email_address FROM employees WHERE id IN(SELECT employee_id FROM employee_group_membership WHERE employee_group_id=(SELECT id FROM employee_groups WHERE name='fremen'));
SELECT first_name,last_name,email_address FROM employees WHERE id IN(SELECT employee_id FROM employee_group_membership WHERE employee_group_id=(SELECT id FROM employee_groups WHERE name='house_atreides'));
```

Even though Paul no longer _exists_ as an employee; he's still listed as a member of house_atreides and fremen; so in a roundabout way, if someone wanted to list the employees that belong to a certain group, they have an opportunity to be aware that Paul exists from the perspective of employee groups, but not from the perspective of employees. For a schema this simple, it's not a big deal, but for much bigger schemas, this can become a complicated problem. Although there are some slight nuances to solutions for this problem, in general you __MUST__ update the queries to filter by the deleted column.

We can resolve this data inconsistency, but updating the SELECT queries above to the following:

```sql
SELECT first_name,last_name,email_address FROM employees WHERE deleted=false AND id IN(SELECT employee_id FROM employee_group_membership WHERE employee_group_id=(SELECT id FROM employee_groups WHERE name='fremen'));
SELECT first_name,last_name,email_address FROM employees WHERE deleted=false AND id IN(SELECT employee_id FROM employee_group_membership WHERE employee_group_id=(SELECT id FROM employee_groups WHERE name='house_atreides'));
```

Now that we've added the filter on deleted, the output of the SELECT statements matches data consistency (all the listed employee group members aren't deleted). In addition, we can ensure that this works both ways as the employee group memberships can _ALSO_ be soft-deleted:

```sql
UPDATE employees SET deleted=false WHERE email_address='paul.atreides@house_atreides.com';
UPDATE employee_group_membership SET deleted=true WHERE employee_group_id=(SELECT id FROM employee_groups WHERE name='fremen') AND employee_id=(SELECT id FROM employees WHERE email_address='paul.atreides@house_atreides.com');
SELECT first_name,last_name,email_address FROM employees WHERE deleted=false AND id IN(SELECT employee_id FROM employee_group_membership WHERE employee_group_id=(SELECT id FROM employee_groups WHERE name='fremen'));
```

Again, you'll notice that although we've soft-deleted Paul's membership with the fremen group, if we attempt to query the members of the fremen group, Paul is still a member. We'll need to amend the queries to filter by deleted:

```sql
SELECT first_name,last_name,email_address FROM employees WHERE deleted=false AND id IN(SELECT employee_id FROM employee_group_membership WHERE deleted=false AND employee_group_id=(SELECT id FROM employee_groups WHERE name='fremen'));
```

Finally, we can show how sql itself will maintain data consistency through the use of foreign keys and the use of 'ON DELETE CASCADE'. For _entertainment_ purposes, these queries WILL NOT filter by deleted:

```sql
SELECT first_name,last_name,email_address FROM employees WHERE id IN(SELECT employee_id FROM employee_group_membership WHERE employee_group_id=(SELECT id FROM employee_groups WHERE name='house_atreides'));
DELETE FROM employees WHERE id=(SELECT id FROM employees WHERE email_address='paul.atreides@house_atreides.com');
SELECT first_name,last_name,email_address FROM employees WHERE id IN(SELECT employee_id FROM employee_group_membership WHERE employee_group_id=(SELECT id FROM employee_groups WHERE name='house_atreides'));
```

Although it's not as flashy, if you delete an employee group, it will ALSO delete the memberships; this is super un-flashy to demo, so I suggest you try it on your own and see what happens.

## Considerations for parent-child relationships

I think one of the things that this repo doesn't do a good job of is showing you how to handle soft-deletes between parent and child objects. The working example between employees and employee groups is a bit unique because there isn't a parent-child relationship between employee groups and employees, but simply a referential relationship; the Deleted column can _remain_ local to it's appropriate table. This isn't necessarily true for parent/child relationships.

I think if you have a dependent object (e.g., an actual parent/child relationship) and the child can be referenced on its own; then if you soft-delete the parent, the child-object must be made inaccessible (somehow). 

A more concrete example is a database of states, cities and counties. The parent/child relationships are State -> City -> County. If you wer to soft-delete the state, then you shouldn't be able to reference (or read) any cities associated with the soft-deleted state OR counties associated with cities to maintain data consistency. I think this problem (resolving data consistency) can be solved in one of two ways:

1. filter out ability to reference child objects where the parent has been soft-deleted by using the parent object deleted column
2. automatically set child objects Deleted column to true when an associated parent object is set and maintain using the Deleted columns local to the objects being referenced

I have a preference for the first option because the second option can inadvertently __destroy__ data. If using option 2, a child object that was soft-deleted for a reason not associated with a parent object being soft-deleted would be ambiguously soft-deleted as a result of soft-deleting a parent object.

This has the __BIGGEST__ impact on resolving data-consistency and returning to an expected data set after un-soft-deleting. By automatically setting all child objects to being soft-deleted, you're forced to either un-delete all child objects OR go through every object one-by-one and determine if the child object should be un-deleted. Compare the idea of that against just un-deleting the parent object and leaving the child objects as-is.
