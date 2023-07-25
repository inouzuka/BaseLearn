insert into inventory_transaction_valuation (
	transaction_date, company_name, partner_ref, product_code, quantity, unit_cost, move_type
) values (
	'2023-4-25','My Company (San Francisco)','Colleen Diaz','AVCO-QUERY-001',1,60,1
);

select * from inventory_transaction_valuation;


-- insert into inventory_transaction_valuation (
-- 	transaction_date, company_name, partner_ref, product_code, quantity, unit_cost, move_type
-- ) values (
-- 	'2023-2-22','My Company (San Francisco)','Colleen Diaz','AVC-02',10,20,1
-- );

-- select * from inventory_transaction_temp;

-- insert into inventory_transaction_temp(
-- 	origin_id, product_code, transaction_date, quantity, unit_cost, value, create_date, move_type						
-- 	)select id, product_code, transaction_date, quantity, unit_cost, unit_cost, now(), move_type 
-- 	from inventory_transaction_valuation;


-- select * from res_partner where name ilike '%Fletcher%';
-- select * from res_company where name ilike '%My Company (San Francisco)%';
-- select * from stock_picking_type 
-- select * from product_category
-- select * from ir_sequence

-- select pp.id product_id, pt.id, pt.name, pt.default_code product_code, ivt.id origin_id, 
-- pc.id categ_id, rp.id partner_id, rp.name, ivt.quantity quantity, ivt.unit_cost unit_cost,
-- uom.id uom_id, rsc.id company_id, rsc.currency_id currency_id, ivt.transaction_date transaction_date

-- from inventory_transaction_valuation ivt

-- inner join product_template pt on ivt.product_code = pt.default_code
-- inner join product_category pc on pc.id = pt.categ_id 
-- inner join res_partner rp on rp.name = ivt.partner_ref
-- inner join product_product pp on pp.product_tmpl_id = pt.id
-- inner join uom_uom uom on pt.uom_id = uom.id 
-- inner join res_company rsc on rsc.name = ivt.company_name
-- -- inner join stock_location sloc on sloc.company_id = rsc.id
-- -- inner join stock_picking_type on spt.

-- group by pt.id, ivt.id, pt.name, pc.id, rp.id, pp.id, ivt.quantity, ivt.unit_cost, 
-- uom.id, rsc.id, ivt.transaction_date;

-- insert into inventory_transaction_temp (
-- 	origin_id, product_code, transaction_date,
-- 	quantity, unit_cost, create_date, move_type,
-- 	product_id, uom_id, company_id, partner_id, categ_id, currency_id
-- ) select ivt.id, ivt.product_code, ivt.transaction_date, ivt.quantity, ivt.unit_cost, now(), ivt.move_type,
-- pp.id, uom.id, rsc.id, rp.id, pc.id, rsc.currency_id
-- from inventory_transaction_valuation ivt
-- inner join product_template pt on ivt.product_code = pt.default_code
-- inner join product_category pc on pc.id = pt.categ_id 
-- inner join res_partner rp on rp.name = ivt.partner_ref
-- inner join product_product pp on pp.product_tmpl_id = pt.id
-- inner join uom_uom uom on pt.uom_id = uom.id 
-- inner join res_company rsc on rsc.name = ivt.company_name

-- group by pt.id, ivt.id, ivt.product_code,pt.name, pc.id, rp.id, pp.id, ivt.quantity, 
-- ivt.unit_cost, uom.id, rsc.id, ivt.transaction_date,ivt.move_type;


-- insert into purchase_order (parner_id, currency_id, company_id, name, state, date_order, picking_type_id)
-- select nextval(id), 
