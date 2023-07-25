SELECT id, company_id, create_uid, write_uid, name, allow_new_product, max_weight, create_date, write_date
	FROM public.stock_storage_category;
	
	
select * from stock_valuation_layer;

select 
	svl.id, svl.product_id,
	sum(svl.quantity) as qty, svl.unit_cost, sum(svl.value) as value
from stock_valuation_layer svl
join product_product pp on pp.id = svl.product_id
join product_template pt on pp.product_tmpl_id = pt.id
where pp.id=41
group by svl.id, svl.company_id, svl.product_id, pt.name;
