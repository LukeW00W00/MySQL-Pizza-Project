--@block
CREATE TABLE `orders` (
    `row_id` int  NOT NULL ,
    `order_id` varchar(10)  NOT NULL ,
    `created_at_date` date  NOT NULL ,
    `created_at_time` time  NOT NULL ,
    `item_id` varchar(10)  NOT NULL ,
    `quantity` int  NOT NULL ,
    `cust_id` int  NOT NULL ,
    `delivery` boolean  NOT NULL ,
    `add_id` int  NOT NULL ,
    PRIMARY KEY (
        `row_id`
    )
);

CREATE TABLE `customers` (
    `customer_id` int  NOT NULL ,
    `cust_firstname` varchar(50)  NOT NULL ,
    `cust_lastname` varchar(50)  NOT NULL ,
    PRIMARY KEY (
        `customer_id`
    )
);

CREATE TABLE `address` (
    `add_id` int  NOT NULL ,
    `delivery_address1` varchar(200)  NOT NULL ,
    `delivery_address2` varchar(200)  NOT NULL ,
    `delivery_city` varchar(50)  NOT NULL ,
    `delivery_zipcode` varchar(20)  NOT NULL ,
    PRIMARY KEY (
        `add_id`
    )
);

CREATE TABLE `item` (
    `item_id` varchar(10)  NOT NULL ,
    `sku` varchar(20)  NOT NULL ,
    `item_name` varchar(100)  NOT NULL ,
    `item_cat` varchar(100)  NOT NULL ,
    `item_size` varchar(10)  NOT NULL ,
    `item_price` decimal(10,2)  NOT NULL ,
    PRIMARY KEY (
        `item_id`
    )
);

CREATE TABLE `ingredient` (
    `ing_id` varchar(10)  NOT NULL ,
    `ing_name` varchar(200)  NOT NULL ,
    `ing_weight` int  NOT NULL ,
    `ing_meas` varchar(20)  NOT NULL ,
    `ing_price` decimal(5,2)  NOT NULL ,
    PRIMARY KEY (
        `ing_id`
    )
);

CREATE TABLE `recipe` (
    `row_id` int  NOT NULL ,
    `recipe_id` varchar(20)  NOT NULL ,
    `ing_id` varchar(10)  NOT NULL ,
    `quantity` int  NOT NULL ,
    PRIMARY KEY (
        `row_id`
    )
);

CREATE TABLE `inventory` (
    `inv_id` int  NOT NULL ,
    `ingr_id` varchar(10)  NOT NULL ,
    `quantity` int  NOT NULL ,
    PRIMARY KEY (
        `inv_id`
    )
);

CREATE TABLE `staff` (
    `staff_id` varchar(20)  NOT NULL ,
    `first_name` varchar(50)  NOT NULL ,
    `last_name` varchar(50)  NOT NULL ,
    `position` varchar(100)  NOT NULL ,
    `hourly_rate` decimal(5,2)  NOT NULL ,
    PRIMARY KEY (
        `staff_id`
    )
);

CREATE TABLE `shift` (
    `shift_id` varchar(20)  NOT NULL ,
    `day_of_week` varchar(10)  NOT NULL ,
    `start_time` time  NOT NULL ,
    `end_time` time  NOT NULL ,
    PRIMARY KEY (
        `shift_id`
    )
);

CREATE TABLE `rota` (
    `row_id` int  NOT NULL ,
    `rota_id` varchar(20)  NOT NULL ,
    `date` date  NOT NULL ,
    `shift_id` varchar(20)  NOT NULL ,
    `staff_id` varchar(20)  NOT NULL ,
    PRIMARY KEY (
        `row_id`
    )
);

--@block

ALTER TABLE `orders` ADD INDEX (`created_at_date`);
ALTER TABLE `orders` ADD INDEX (`item_id`);
ALTER TABLE `orders` ADD INDEX (`cust_id`);
ALTER TABLE `orders` ADD INDEX (`add_id`);
ALTER TABLE `item` ADD INDEX (`sku`);
ALTER TABLE `recipe` ADD INDEX (`ing_id`);
ALTER TABLE `recipe` ADD INDEX (`recipe_id`);
ALTER TABLE `inventory` ADD INDEX (`ingr_id`);
ALTER TABLE `rota` ADD INDEX (`shift_id`);
ALTER TABLE `rota` ADD INDEX (`staff_id`);
ALTER TABLE `rota` ADD INDEX (`date`);

ALTER TABLE `orders` ADD CONSTRAINT `fk_orders_created_at_date` FOREIGN KEY(`created_at_date`)
REFERENCES `rota` (`date`);

ALTER TABLE `orders` ADD CONSTRAINT `fk_orders_item_id` FOREIGN KEY(`item_id`)
REFERENCES `item` (`item_id`);

ALTER TABLE `orders` ADD CONSTRAINT `fk_orders_cust_id` FOREIGN KEY(`cust_id`)
REFERENCES `customers` (`customer_id`);

ALTER TABLE `orders` ADD CONSTRAINT `fk_orders_add_id` FOREIGN KEY(`add_id`)
REFERENCES `address` (`add_id`);

ALTER TABLE `item` ADD CONSTRAINT `fk_item_sku` FOREIGN KEY(`sku`)
REFERENCES `recipe` (`recipe_id`);

ALTER TABLE `recipe` ADD CONSTRAINT `fk_recipe_ing_id` FOREIGN KEY(`ing_id`)
REFERENCES `ingredient` (`ing_id`);

ALTER TABLE `inventory` ADD CONSTRAINT `fk_inventory_ingr_id` FOREIGN KEY(`ingr_id`)
REFERENCES `ingredient` (`ing_id`);

ALTER TABLE `rota` ADD CONSTRAINT `fk_rota_shift_id` FOREIGN KEY(`shift_id`)
REFERENCES `shift` (`shift_id`);

ALTER TABLE `rota` ADD CONSTRAINT `fk_rota_staff_id` FOREIGN KEY(`staff_id`)
REFERENCES `staff` (`staff_id`);

--@block--------------------------------------------------------------------------------------------------
SELECT
o.order_id,
i.item_price,
o.quantity,
i.item_cat,
i.item_name,
o.created_at_date,
o.created_at_time,
a.delivery_address1,
a.delivery_address2,
a.delivery_city,
a.delivery_zipcode,
o.delivery
FROM 
    orders o
    LEFT JOIN item i ON o.item_id = i.item_id
    LEFT JOIN address a ON o.add_id = a.add_id

--@block creating stock1 view------------------------------------------------------------------------------------------------------------
CREATE VIEW stock1 AS
SELECT 
s1.item_name,
s1.ing_id,
s1.ing_name,
s1.ing_weight,
s1.ing_price,
s1.order_quantity,
s1.recipe_quantity,
s1.order_quantity * s1.recipe_quantity AS ordered_weight,
s1.ing_price/s1.ing_weight AS unit_cost,
(s1.order_quantity * s1.recipe_quantity) * (s1.ing_price/s1.ing_weight) AS ingredient_cost
FROM (SELECT
o.item_id,
i.sku,
i.item_name,
r.ing_id,
ing.ing_name,
r.quantity AS recipe_quantity,
sum(o.quantity) as order_quantity,
ing.ing_weight,
ing.ing_price

FROM 
    orders o
    LEFT JOIN item i ON o.item_id = i.item_id
    LEFT JOIN recipe r ON i.sku = r.recipe_id
    LEFT JOIN ingredient ing ON ing.ing_id = r.ing_id
GROUP BY
    o.item_id,
    i.sku,
    i.item_name,
    r.ing_id,
    r.quantity,
    ing.ing_name,
    ing.ing_weight,
    ing.ing_price) s1


--@block stock3 creation---------------------------------------------------------------------------------------------------------------
  CREATE VIEW stock3 AS
SELECT
    ing.ing_id,
    ing.ing_name,
    (SELECT SUM(r2.quantity) FROM recipe r2 WHERE r2.ing_id = ing.ing_id GROUP BY r2.ing_id) AS tot_recipe_quantity,
    SUM(o.quantity) AS tot_order_quantity,
    ing.ing_weight,
    ing.ing_price,
    ((SELECT SUM(r2.quantity) FROM recipe r2 WHERE r2.ing_id = ing.ing_id GROUP BY r2.ing_id) * SUM(o.quantity) * ing.ing_weight) AS tot_ordered_weight
FROM 
    orders o
    INNER JOIN item i ON o.item_id = i.item_id
    INNER JOIN recipe r ON i.sku = r.recipe_id
    INNER JOIN ingredient ing ON ing.ing_id = r.ing_id
GROUP BY
    ing.ing_id,
    ing.ing_name,
    ing.ing_weight,
    ing.ing_price

--@block stock3 utilisations---------------------------------------------------------------------------------------------------------------
CREATE VIEW stock4 AS
SELECT
    s2.ing_name,
    s2.ordered_weight,
    inv.quantity AS total_inv_weight,
    inv.quantity - s2.ordered_weight AS remaining_weight

FROM (SELECT 
    ing_id,
    ing_name,
    tot_ordered_weight AS ordered_weight

FROM 
    stock3
    GROUP BY ing_name, ing_id) s2

LEFT JOIN inventory inv ON inv.ingr_id = s2.ing_id
LEFT JOIN ingredient ing ON ing.ing_id = s2.ing_id

--@block staff info-------------------------------------------------------------------------------------------------------
SELECT
    r.date,
    s.first_name,
    s.last_name,
    s.hourly_rate,
    sh.start_time,
    sh.end_time,
    CASE
        WHEN sh.end_time < sh.start_time THEN
            ((hour(timediff('24:00:00', sh.start_time))*60)+(minute(timediff('24:00:00', sh.start_time))) + (hour(sh.end_time)*60)+minute(sh.end_time))/60
        ELSE
            ((hour(timediff(sh.end_time, sh.start_time))*60)+(minute(timediff(sh.end_time, sh.start_time))))/60
    END AS hours_in_shift,
    CASE
        WHEN sh.end_time < sh.start_time THEN
            ((hour(timediff('24:00:00', sh.start_time))*60)+(minute(timediff('24:00:00', sh.start_time))) + (hour(sh.end_time)*60)+minute(sh.end_time))/60 * s.hourly_rate
        ELSE
            ((hour(timediff(sh.end_time, sh.start_time))*60)+(minute(timediff(sh.end_time, sh.start_time))))/60 * s.hourly_rate
    END AS staff_cost
FROM rota r
LEFT JOIN staff s ON r.staff_id = s.staff_id
LEFT JOIN shift sh ON r.shift_id = sh.shift_id



