select id, product_id, company_id, stock_move_id, description, quantity, unit_cost, value from stock_valuation_layer where product_id=41;
select 
	product_id, sum(quantity), sum(quantity*unit_cost) from stock_valuation_layer 
where product_id=41 and company_id=1 
group by product_id;
 
select * from stock_valuation_layer;
select * from product_product;

select * from product_template where id=33;
select * from product_category;

select pp.id, pt.id, pp.default_code
from product_product pp
join product_template pt on pt.id = pp.product_tmpl_id
where pp.id=41
group by pp.id, pt.id, pp.default_code;


select * from ir_property;
select * from res_company;
public.ir_model_fields;
FROM public.ir_model;

select * from product_category where id = 8;

select id, company_id, fields_id, name, res_id, type, value_float from ir_property;

select * 
from 


insert into ir_property(company_id,fields_id, name, res_id, type, value_float)
values(1,2905,'standard_price', 'product.product,41','float',60);

select * from inventory_transaction_temp;