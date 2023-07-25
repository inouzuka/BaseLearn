SELECT id, sequence, product_uom, product_id, order_id, company_id, partner_id, currency_id, product_packaging_id, create_uid, write_uid, state, qty_received_method, display_type, analytic_distribution, name, product_qty, price_unit, price_subtotal, price_total, qty_invoiced, qty_received, qty_received_manual, qty_to_invoice, date_planned, create_date, write_date, product_uom_qty, price_tax, product_packaging_qty, sale_order_id, sale_line_id, orderpoint_id, product_description_variants, propagate_cancel
	FROM public.purchase_order_line where order_id=23;
	

select * from stock_location;
select * from stock_warehouse;

select * from purchase_order where id=47;

select * from stock_move_line;
select * from ir_sequence;
select move_id,
	account_id,
	journal_id,
	company_currency_id,
	currency_id,
	company_id,
	display_type,
	product_id, 
	product_uom_id,
	parent_state,
	ref,
	name,
	date,
	debit,
	credit,
	balance,
	amount_residual, 
	quantity,
	price_unit,
	price_subtotal,
	price_total from account_move_line;
insert into account_move_line(
	move_id,
	account_id,
	journal_id,
	company_currency_id,
	currency_id,
	company_id,
	display_type,
	product_id, 
	product_uom_id,
	parent_state,
	ref,
	name,
	date,
	debit,
	credit,
	balance,
	amount_residual, 
	quantity,
	price_unit,
	price_subtotal,
	price_total,
-- 	purchase_line_id,
	
	create_uid,
	write_uid,
	create_date,
	write_date
	
) values(
	66,
	62,
	2,
	12,
	1,
	1,
	'product',
	44,
	1,
	'posted',
	'--1-111',
	'amoeline',
	now(),
	-1,
	0,
	0,
	0,
	1,
	100,
	100,
	100,
	1,1,now(),now()
	
);