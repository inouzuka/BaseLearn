DROP TABLE IF EXISTS inventory_transaction_notification;
CREATE TABLE inventory_transaction_notification(
    unique_key varchar,
    db_name varchar,
    db_port varchar,
    db_host varchar,
    db_user varchar,
    db_password varchar
);

-- 
insert into inventory_transaction_notification (unique_key) values ('inventory_transaction_notification');
select * from inventory_transaction_notification;

-- 
DROP TABLE IF EXISTS inventory_transaction_valuation;
CREATE TABLE inventory_transaction_valuation(
    id bigserial,
    transaction_date timestamp,
    partner_ref varchar,
    company_name varchar,
    product_code varchar,
    quantity float,
    unit_cost float,
    value float,
    create_date timestamp default now(),
    move_type int, -- 1=in/purchase, 0=out/sale
    stage int default 1,
    -- column mapping
    picking_id int,
    move_id int,
    move_line_id int,
    product_id int,
    uom_id int,
    company_id int,
    partner_id int,
    categ_id int,
    quantity_svl float,
    value_svl float,
    cost_method varchar,
    valuation varchar,

    location_src_id int,
    location_dest_id int,
    
    acc_move_id int,
    acc_move_line_id_debit int,
    acc_move_line_id_credit int,
    journal_id int,
    debit_account_id int,
    credit_account_id int,
    currency_id int,
    svl_id int,
    primary key(id, stage)
)
partition by list(stage);

CREATE TABLE IF NOT EXISTS inventory_transaction_valuation_ready PARTITION OF inventory_transaction_valuation FOR VALUES IN(1);
CREATE TABLE IF NOT EXISTS inventory_transaction_valuation_done PARTITION OF inventory_transaction_valuation FOR VALUES IN(2);

CREATE INDEX IF NOT EXISTS inventory_transaction_valuation_stage_index ON inventory_transaction_valuation(stage);
CREATE INDEX IF NOT EXISTS inventory_transaction_valuation_transaction_date_index ON inventory_transaction_valuation(transaction_date);
CREATE INDEX IF NOT EXISTS inventory_transaction_valuation_partner_id_index ON inventory_transaction_valuation(partner_ref);
CREATE INDEX IF NOT EXISTS inventory_transaction_valuation_company_index ON inventory_transaction_valuation(company_name);
CREATE INDEX IF NOT EXISTS inventory_transaction_valuation_product_code_index ON inventory_transaction_valuation(product_code);
CREATE INDEX IF NOT EXISTS inventory_transaction_valuation_create_date_index ON inventory_transaction_valuation(create_date);
CREATE INDEX IF NOT EXISTS inventory_transaction_valuation_move_type_index ON inventory_transaction_valuation(move_type);
CREATE INDEX IF NOT EXISTS inventory_transaction_valuation_cost_method_index ON inventory_transaction_valuation(cost_method);
CREATE INDEX IF NOT EXISTS inventory_transaction_valuation_valuation_index ON inventory_transaction_valuation(valuation);

-- 
-- 
-- Prepare table to receive data stage=1 from table inventory_transaction_valuation
DROP TABLE IF EXISTS inventory_transaction_temp;
CREATE TABLE inventory_transaction_temp(
    origin_id bigint,
    product_code varchar,
    transaction_date timestamp,
    quantity float,
    unit_cost float,
    value float,
    create_date timestamp default now(),
    move_type int, -- 1=in/purchase, 0=out/sale
    -- additional information for mapping
    update_quant boolean,
    picking_id int,
    move_id int,
    move_line_id int,
    product_id int,
    uom_id int,
    company_id int,
    partner_id int,
    categ_id int,
    quantity_svl float,
    value_svl float,
    cost_method varchar,
    valuation varchar,

    temp_location_id int, 
    temp_location_dest_id int, 
    
    acc_move_id int,
    acc_move_line_id_debit int,
    acc_move_line_id_credit int,
    journal_id int,
    debit_account_id int,
    credit_account_id int,
    currency_id int,
    svl_id int,
	
	po_id int,
	po_line int
	
);

CREATE INDEX IF NOT EXISTS inventory_transaction_temp_update_quant_index ON inventory_transaction_temp(update_quant);
CREATE INDEX IF NOT EXISTS inventory_transaction_temp_cost_method_index ON inventory_transaction_temp(cost_method);
CREATE INDEX IF NOT EXISTS inventory_transaction_temp_valuation_index ON inventory_transaction_temp(valuation);
CREATE INDEX IF NOT EXISTS inventory_transaction_temp_product_code_index ON inventory_transaction_temp(product_code);
CREATE INDEX IF NOT EXISTS inventory_transaction_temp_transaction_date_index ON inventory_transaction_temp(transaction_date);
CREATE INDEX IF NOT EXISTS inventory_transaction_temp_create_date_index ON inventory_transaction_temp(create_date);
CREATE INDEX IF NOT EXISTS inventory_transaction_temp_move_type_index ON inventory_transaction_temp(move_type);

-- Alter table to assign id from table inventory_transaction_valuation
ALTER TABLE stock_move ADD COLUMN IF NOT EXISTS origin_id int;
ALTER TABLE stock_move_line ADD COLUMN IF NOT EXISTS origin_id int;
ALTER TABLE stock_move_line ADD COLUMN IF NOT EXISTS update_quant boolean default false;
CREATE INDEX IF NOT EXISTS update_quant_move_line_index ON stock_move_line(update_quant);
ALTER TABLE stock_picking ADD COLUMN IF NOT EXISTS origin_id int;
ALTER TABLE stock_valuation_layer ADD COLUMN IF NOT EXISTS origin_id int;
ALTER TABLE account_move ADD COLUMN IF NOT EXISTS origin_id int;
ALTER TABLE account_move_line ADD COLUMN IF NOT EXISTS origin_id int;

-- DROP FUNCTION IF EXISTS 

DROP FUNCTION IF EXISTS mapping_transaction_data_temp();
CREATE OR REPLACE FUNCTION mapping_transaction_data_temp()
RETURNS trigger
LANGUAGE PLPGSQL AS 
$$
	DECLARE
	poline record;
	data_value record;
	ival record;
	datas record;
	podata record;
	pptl record;
	pg record;
	stp record;
	sm record;
	sml record;
	ppl record;
	pol_data record;
	data_temp record;
	podata_id int;
	BEGIN
-- 		select * from purchase_order_line into poline;
-- 		raise notice 'this is po line : %', poline;
		-- insert into trans temp
-- 		insert into inventory_transaction_temp (transaction_date, partner_ref, product_code, quantity, unit_cost, move_type)
		
		for data_value in select * from inventory_transaction_valuation where stage=1
		loop
			raise notice 'DATA VALUE : % ', data_value;
-- 			insert into inventory_transaction_temp()		
-- 			select * from inventory_transaction_valuation into ival;
			--
			-- create po
			-- 
			insert into inventory_transaction_temp (
				origin_id, 
				product_code, 
				transaction_date,
				quantity, 
				unit_cost, 
				create_date, 
				move_type,
				product_id, 
				uom_id, 
				company_id, 
				partner_id, 
				categ_id, 
				currency_id,
				value
			) select ivt.id, ivt.product_code, ivt.transaction_date, ivt.quantity, ivt.unit_cost, now(), ivt.move_type,
			pp.id, uom.id, rsc.id, rp.id, pc.id, rsc.currency_id, (ivt.quantity*ivt.unit_cost)
			from inventory_transaction_valuation ivt
			inner join product_template pt on ivt.product_code = pt.default_code
			inner join product_category pc on pc.id = pt.categ_id 
			inner join res_partner rp on rp.name = ivt.partner_ref
			inner join product_product pp on pp.product_tmpl_id = pt.id
			inner join uom_uom uom on pt.uom_id = uom.id 
			inner join res_company rsc on rsc.name = ivt.company_name

			group by pt.id, ivt.id, ivt.product_code,pt.name, pc.id, rp.id, pp.id, ivt.quantity, 
			ivt.unit_cost, uom.id, rsc.id, ivt.transaction_date, ivt.move_type;
			
		end loop;
		select * from inventory_transaction_temp into data_temp;
		raise notice 'DATA VALUATION: %', data_value;
		raise notice 'DATA TEMP: %', data_temp;
			
		for datas in select * from inventory_transaction_temp 
		loop
			raise notice 'IVAL DATA : %', datas;
			insert into purchase_order (
				partner_id, 
				currency_id, 
				company_id, 
				name, 
				state, 
				date_order, 
				date_planned, 
				picking_type_id, 
				create_date, 
				create_uid, 
				write_date, 
				write_uid
			) 
			values (
				datas.partner_id, 
				datas.currency_id, 
				datas.company_id, 
				CONCAT('PO',LPAD(nextval(CONCAT('ir_sequence_003'))::text,5,'0')), 
				'purchase', 
				datas.transaction_date, 
				now(), 
				datas.move_type, 
				now(),
				1,
				now(),
				1
			) returning id into podata_id;
			
			select * from product_template where default_code = datas.product_code into pptl;
			
			raise notice 'product data: % ', pptl;
			raise notice 'product data: % ', pptl.name;
			
-- 			select * from purchase_order where partner_id = datas.partner_id  limit 1 DESC into podata;
			select * from purchase_order where id=podata_id into podata;
			raise notice 'PO 		: %', podata;
			raise notice 'PO_dataid :  %', podata_id;
			raise notice 'PO 		: %', podata.id;
-- 			raise notice 'PO %', datas.quantity;
-- 			raise notice 'PO %', datas.uom_id;
-- 			raise notice 'PO %', datas.unit_cost;
-- 			raise notice 'PO %', podata.date_order;
			
			insert into purchase_order_line(
				order_id, 
				product_id, 
				name, 
				product_qty, 
				product_uom, 
				price_unit,
				date_planned,
				state, 
				company_id, 
				currency_id, 
				partner_id, 
				qty_received_method,
				product_uom_qty, 
				qty_received,
				price_subtotal,
				
				create_date, 
				create_uid, 
				write_date, 
				write_uid
			)
			values(
				podata_id, 
				datas.product_id,
				pptl.name,
				datas.quantity,
				datas.uom_id,
				datas.unit_cost,
				podata.date_order,
				podata.state,
				datas.company_id,
				datas.currency_id, 
				datas.partner_id,
				'stock_move',
				datas.quantity,
				datas.quantity,
				(datas.quantity*datas.unit_cost),
			
				now(),
				1, 
				now(),
				1
			);
			select * from purchase_order_line into poline;
			raise notice 'PO LINE DATA : %', poline;
			
			perform transaction_po(podata_id);
			raise notice 'STOCK QUANT';
			perform update_stock_quant();
			raise notice 'ACCOUNTMOVE';
			perform mapping_account_move();
			raise notice 'VALUATION LAYER';
			perform mapping_stock_valuation_layer();
		end loop;
		
		return new;
	END;
$$;

-- -

DROP FUNCTION IF EXISTS transaction_po(integer);

CREATE OR REPLACE FUNCTION transaction_po(po_id integer)
RETURNS void
LANGUAGE PLPGSQL AS 
$$
	DECLARE
		po_data record;
		pd record;
		poc record;
		pol record;
		pg record;
		stp record;
		ppl record;
		pol_data record;
		sm  record;
		sml record;
		trantemp record;
		porder record;
		picking record;
		prod record;
		loc_des int;
		new_data record;
		trantemp0 record;
		id_picking int;
		--

        operation_type_in record;
		pti record;
		-- get info opertaion type from odoo to get source location & destination location
        

		--
	BEGIN
-- 		with data_location as 
-- 			(
-- 				with vendor as(
-- 					select id,'vendor' as name from stock_location where usage='supplier' limit 1
-- 				), customer as(
-- 					select id,'customer' as name from stock_location where usage='customer' limit 1
-- 				) SELECT * FROM vendor UNION ALL SELECT * FROM customer
-- 			)
-- 			SELECT 
-- 				spt.id as picking_type_id, 
-- 				CASE WHEN spt.sequence_id <= 100 THEN
-- 					 CONCAT('ir_sequence_', LPAD(spt.sequence_id::varchar, 3, '0'))
-- 				ELSE CONCAT('ir_sequence_', spt.sequence_id::varchar)
-- 					END AS seq_name,

-- 				spt.sequence_id as sequence_id, 
-- 				seq.prefix as prefix, 
-- 				seq.suffix as suffix, 
-- 				seq.padding as padding,
-- 				CASE WHEN spt.default_location_src_id IS NULL THEN
-- 					(select id from data_location where name='vendor' limit 1)
-- 				ELSE spt.default_location_src_id 
-- 					END AS location_src_id,
-- 				CASE WHEN spt.default_location_dest_id IS NULL THEN
-- 					(select id from data_location where name='customer' limit 1)
-- 				ELSE spt.default_location_dest_id
-- 					END AS location_dest_id
-- 			FROM stock_picking_type spt
-- 				INNER JOIN ir_sequence seq ON seq.id = spt.sequence_id
-- 			WHERE 
-- 				spt.code = 'incoming'
-- 			LIMIT 1
-- 			INTO operation_type_in;
		
-- 		for pti in SELECT 
-- 				spt.id as picking_type_id, 
-- 				CASE WHEN spt.sequence_id <= 100 THEN
-- 					 CONCAT('ir_sequence_', LPAD(spt.sequence_id::varchar, 3, '0'))
-- 				ELSE CONCAT('ir_sequence_', spt.sequence_id::varchar)
-- 					END AS seq_name,

-- 				spt.sequence_id as sequence_id, 
-- 				seq.prefix as prefix, 
-- 				seq.suffix as suffix, 
-- 				seq.padding as padding,
-- 				CASE WHEN spt.default_location_src_id IS NULL THEN
-- 					(select id from data_location where name='vendor' limit 1)
-- 				ELSE spt.default_location_src_id 
-- 					END AS location_src_id,
-- 				CASE WHEN spt.default_location_dest_id IS NULL THEN
-- 					(select id from data_location where name='customer' limit 1)
-- 				ELSE spt.default_location_dest_id
-- 					END AS location_dest_id
-- 			FROM stock_picking_type spt
-- 				INNER JOIN ir_sequence seq ON seq.id = spt.sequence_id
-- 			WHERE 
-- 				spt.code = 'incoming'
-- 			LIMIT 1
-- 			loop
-- 				raise notice 'POCKING TYPE ID : %', pti;

-- 			end loop;
		
-- 		select * from purchase_order where id=po_id into po_data;
		RAISE NOTICE 'OPERATION TYPE IN : % ', operation_type_in;
		RAISE NOTICE 'CONFIRM PO ';
		
-- 		FOR porder in select id, partner_id, name, date_order, state, company_id, currency_id from purchase_order where id=po_data.id
		FOR porder in select * from purchase_order where id=po_id
		LOOP
			RAISE NOTICE 'data po : % | % | %', porder.id, porder.name, porder.state;
			RAISE NOTICE 'Set Confirm the Purchase Oder';
			
			UPDATE purchase_order SET state='purchase', date_approve = now(), write_uid = 1, write_date = now() where id=porder.id;
			UPDATE purchase_order_line SET state='purchase', write_uid = 1, write_date = now() where order_id=porder.id;
			RAISE NOTICE 'Purchase Oder confirmed';
			
-- 			select id, name, date_order, state, write_date, create_date, create_uid, write_uid from purchase_order where id=po_id into poc;
-- 			RAISE NOTICE 'the PO: % | % | % ', poc.id, poc.name, poc.state;
			
			RAISE NOTICE 'create picking';
			select 
				id, 
				order_id, 
				company_id, 
				partner_id, 
				product_id, 
				product_uom, 
				name, 
				product_qty, 
				product_uom_qty, 
				state 
			from purchase_order_line where order_id=porder.id into pol;
			
			raise notice 'create producrement group';
			insert into procurement_group( 
				partner_id, create_uid, write_uid, name, move_type, create_date, write_date
			) values (
				porder.partner_id, 1, 1, porder.name, 'direct', now(), now()
			);
			select id, partner_id, name, move_type from procurement_group where name=porder.name limit 1 into pg;
			-- get location 
			
			-- get warehouse
			
			raise notice 'created:  %', pg;
			raise notice 'OPERATION :  %', operation_type_in;
-- 				operation_type_in.location_src_id, 
-- 				operation_type_in.location_dest_id,
-- 				operation_type_in.picking_type_id,
-- 				CONCAT(operation_type_in.prefix,LPAD(nextval(operation_type_in.sequence_id)::text,5,'0')),
			raise notice 'create stock picking12x';
			
			insert into stock_picking (
				location_id, 
				location_dest_id, 
				picking_type_id, 
				name, 
				partner_id,
				company_id, 
				group_id, 
				user_id, 
				date, 
				origin, 
				state,
				move_type, 
				scheduled_date, 
				is_locked,
				
				create_uid, 
				write_uid, 
				create_date, 
				write_date
			) values (

				4,8,1,
				CONCAT('PICKING/',LPAD(nextval(CONCAT('ir_sequence_002'))::text,6,'0')),
				porder.partner_id, 
				porder.company_id, 
				pg.id, 
				1, 
				now(), 
				pg.name, 
				'assigned', 
				pg.move_type, 
				now(), 
				'True',
				
				1, 
				1, 
				now(), 
				now()
				
			) returning id into id_picking;
			
			select id, name, location_id, location_dest_id, picking_type_id, partner_id,
				company_id, group_id, user_id, date, origin, state, move_type from stock_picking where id=id_picking into stp;
			raise notice 'picking created: %', stp;
			
			INSERT INTO public.purchase_order_stock_picking_rel(
				purchase_order_id, stock_picking_id)
			VALUES (porder.id, stp.id);
			
			select * from public.purchase_order_stock_picking_rel where purchase_order_id=porder.id into ppl;
			raise notice 'po-picking-rel : %', ppl;	
			raise notice 'create stock move';
			
			FOR pol_data in 
				select 
					*
				from 
					purchase_order_line 
					where order_id=porder.id
			LOOP
				raise notice 'puchase order line data : % ', pol_data;
				INSERT INTO stock_move (
					company_id, product_id, product_uom, location_id, location_dest_id, partner_id, picking_id, 
					group_id, picking_type_id, create_uid, write_uid, create_date, write_date, name, 
					state, origin, procure_method, product_qty, product_uom_qty, 
					date, reference, purchase_line_id, quantity_done
				) VALUES (
					pol_data.company_id, pol_data.product_id, pol_data.product_uom, 
					stp.location_id, stp.location_dest_id, pg.partner_id, stp.id,
					pg.id, stp.picking_type_id, 1, 1, now(), now(), stp.name,
					stp.state, stp.name, 'make_to_stock', pol_data.product_uom, pol_data.product_uom_qty, 
					now(), stp.name, pol_data.id, pol_data.product_uom_qty 
				);
				raise notice 'stock move created';
				select id, company_id, product_id, product_uom, location_id, location_dest_id, partner_id, picking_id, 
					group_id, picking_type_id, create_uid, write_uid, create_date, write_date, name, 
					state, origin, procure_method, product_qty, product_uom_qty, date from stock_move where picking_id=stp.id into sm;
				raise notice 'stock move here % ', sm;
				raise notice 'insert to stock move line';
				
				INSERT INTO public.stock_move_line(
					picking_id, move_id, company_id, product_id, product_uom_id, 
					location_id, location_dest_id, create_uid, write_uid, state, 
					reference, date, create_date, write_date, reserved_uom_qty, qty_done
				) VALUES (
					stp.id, sm.id, pol_data.company_id, pol_data.product_id, pol_data.product_uom,
					stp.location_id, stp.location_dest_id, 1, 1, sm.state,
					sm.origin, now(), now(), now(), pol_data.product_uom_qty, pol_data.product_uom_qty 
				);
				select picking_id, move_id, company_id, product_id, product_uom_id, 
					location_id, location_dest_id, create_uid, write_uid, state, 
					reference, date, create_date, write_date from stock_move_line where picking_id=stp.id into sml;
				raise notice '1 stock move line : %', sml;
				
				update purchase_order_line set qty_to_invoice=pol_data.product_uom_qty where id=pol_data.id;
				
				for trantemp in select * from inventory_transaction_temp
				loop
					raise notice 'TRANSTEMP : % ', trantemp;
		
					update inventory_transaction_temp set po_id=porder.id where origin_id=trantemp.origin_id;
					update inventory_transaction_temp set po_line=pol_data.id where origin_id=trantemp.origin_id;
					raise notice 'insert into temp';
				end loop;
				
			END LOOP;
			raise notice 'stock picking: % ', stp;
			raise notice 'stock move: % ', sm;
			raise notice 'stock move line : %', sml;
			
			FOR picking in SELECT * FROM stock_picking where id=stp.id
			LOOP
				RAISE NOTICE '----';
				RAISE NOTICE 'picking ORI %', stp.id;
				RAISE NOTICE 'picking SINI %', picking.id;
				RAISE NOTICE 'SM SINI %', sm;
				RAISE NOTICE 'SML SINI %', sml;
				
				UPDATE stock_picking SET state= 'done', write_uid = 1, write_date = now() WHERE id = picking.id;
				UPDATE stock_picking SET date_done= now(), write_uid = 1, write_date = now() WHERE id = picking.id;
-- 				update stock_picking set is_locked = 'True' where id=picking.id;
				UPDATE stock_move SET state='done', write_uid = 1, write_date = now() WHERE picking_id = picking.id;
-- 				UPDATE stock_move_line SET qty_done= stp.product_uom_qty, write_uid = 1, write_date = now() WHERE picking_id = picking.id;
				UPDATE stock_move_line SET state='done', write_uid = 1, write_date = now() WHERE picking_id = picking.id;
				
-- 				update purchase_order_line set qty_to_invoice = sm.
				update inventory_transaction_temp set picking_id = picking.id where origin_id=1;

				for sml in select * from stock_move_line where picking_id=picking.id
				loop
					update inventory_transaction_temp set move_id = sml.move_id where picking_id=picking.id;
					update inventory_transaction_temp set move_line_id = sml.id where picking_id=picking.id;
					update inventory_transaction_temp set temp_location_id = sml.location_id where picking_id=picking.id;
					update inventory_transaction_temp set temp_location_dest_id = sml.location_dest_id where picking_id=picking.id;
					
				end loop;
				
				select * from inventory_transaction_temp into trantemp;
			
				RAISE NOTICE 'TRANTEMPP: % ', trantemp;
				
				RAISE NOTICE '----';
				RAISE NOTICE 'UPDATE CLEAR';

			END LOOP;
			
		END LOOP;
		
	EXCEPTION
		WHEN OTHERS THEN
		RAISE exception 'raise here, please check all part on the line ->';
	
	END 
$$;

--- stock quant

-- MAPPING TO UPDATE STOCK QUANT
DROP FUNCTION IF EXISTS update_stock_quant;
CREATE OR REPLACE FUNCTION update_stock_quant()
RETURNS void
LANGUAGE plpgsql
AS $$
	DECLARE 
		squant record;

    BEGIN
        RAISE notice 'update stock quant';
        
        -- process 1
        -- UPDATE Qty if product_id and location_id
        UPDATE stock_quant sq 
        SET 
            quantity =  CASE 
                            WHEN sml.location = 8 THEN 
                                sq.quantity + sml.quantity
                            ELSE 
                                sq.quantity - sml.quantity
                        END,
            write_uid = 1, 
            write_date = now()
        FROM 
            (select 
                sum(case
                    when move_type = 1 then
                        quantity
                    else
                        quantity*-1
                end) as quantity, 
                product_id, 
                CASE 
                    WHEN move_type = 1 THEN 
                        temp_location_dest_id
                    WHEN move_type = 0 THEN
                        temp_location_id
                END as location
                from inventory_transaction_temp 
                group by product_id, location
            ) as sml
        WHERE 
            sq.product_id = sml.product_id AND
            sq.location_id = sml.location;

        -- process 2
        -- INSERT STOCK QUANT if didn't find the data stock quant  
        INSERT INTO stock_quant(
            in_date,
            product_id, 
            company_id, 
            location_id, 
            quantity,
            reserved_quantity,

            create_uid, 
            create_date, 
            write_uid, 
            write_date
        )
        with
            summary as(
                SELECT 
                    rec.transaction_date,
                    rec.product_id, 
                    1 as company_id, 
                    case
                        when rec.move_type = 1 then 
                            rec.temp_location_dest_id
                        else
                            rec.temp_location_id
                    end as location_id,
                    case
                        when rec.move_type = 1 then 
                            rec.quantity*1
                        else
                            rec.quantity*-1
                    end as quantity,
                    0 as reserved_quantity,

                    1 as create_uid, 
                    NOW() as create_date, 
                    1 as write_uid, 
                    NOW() as write_date
                FROM 
                    inventory_transaction_temp rec
        )
        SELECT 
            rec.transaction_date as in_date,
            rec.product_id, 
            rec.company_id, 
            rec.location_id, 
            sum(rec.quantity),
            sum(rec.reserved_quantity),

            rec.create_uid, 
            rec.create_date, 
            rec.write_uid, 
            rec.write_date
        FROM 
            summary rec
            LEFT JOIN stock_quant sq ON 
                sq.product_id = rec.product_id AND sq.location_id = rec.location_id
        WHERE sq.id IS NULL
        group by rec.transaction_date, 
            rec.product_id, 
            rec.company_id, 
            rec.location_id,

            rec.create_uid, 
            rec.create_date, 
            rec.write_uid, 
            rec.write_date; 


		select * from stock_quant into squant;
		
        RAISE notice 'update stock_quant End: %', squant;
    END;
$$;

-- select transaction_po(76)

-- account move
drop function if exists mapping_account_move;
create or replace function mapping_account_move()
returns void
language plpgsql
as 
$$ 
	declare
	datas record;
	journal record;
	acmove record;
	acc_credit record;
	podata int;
	acc_move_id int;
	begin
		select * from account_journal where type='purchase' into journal;
		raise notice 'JOURNAL : %', journal;
		select * from account_account where name = 'Account Payable' limit 1 into acc_credit;
		raise notice 'AP : % ', acc_credit;
		update inventory_transaction_temp set journal_id=journal.id where origin_id=1;
		update inventory_transaction_temp set acc_move_line_id_debit=journal.default_account_id where origin_id=1;
		update inventory_transaction_temp set acc_move_line_id_credit=acc_credit.id where origin_id=1;
		for datas in  select * from inventory_transaction_temp
		loop
			raise notice 'datas trantemp: % ', datas;
-- 			select po.id from purchase_order po where datas.partner_id = po.partner_id order by id desc into podata;
-- 			raise notice 'PODATA : %', podata;
			
			insert into account_move (
				journal_id,
				sequence_number,
				sequence_prefix,
				name,
				partner_id,
				invoice_partner_display_name,
				
				currency_id,
				company_id,
				state,
				move_type,
				auto_post,
				date,
				invoice_date,
				posted_before,
				amount_total_signed,
-- 				amount_total_in_currency_signed,
				
				
				create_uid,
				create_date,
				write_uid,
				write_date
			)
				values( 
					journal.id,
					6,
					(journal.code,'/',DATE_PART('year', now()::date),'/'),
-- 					'BILL-NAME-001',
					CONCAT(journal.code,'/',DATE_PART('year', now()::date),'/',LPAD(nextval(CONCAT('ir_sequence_003'))::text,6,'0')),
					datas.partner_id,
					datas.partner_id,
					datas.currency_id,
					datas.company_id,
					'posted',
					'in_invoice',
					'no',
					now(),
					now(),
					'True',
					((datas.unit_cost*datas.quantity)*-1),
					
					1,
					now(),
					1,
					now()
				) returning id into acc_move_id;
					
-- 			select id from account_move where id = ()
			raise notice 'ID ACC MOVE % ',acc_move_id;
			select * from account_move where id=acc_move_id into acmove;
			raise notice 'ACCOUNT MOVE : %', acmove;
			
-- 			update inventory_transaction_temp set acc_move_id = acmove.id where origin_id=1;
			raise notice 'temp updated';
			insert into account_move_purchase_order_rel(purchase_order_id, account_move_id)
				values(datas.po_id, acc_move_id);
			raise notice 'LINKED am to po';
			
			--
			update purchase_order set invoice_count = 1 where id = datas.po_id;
			update purchase_order set invoice_status = 'invoiced' where id = datas.po_id;
			update purchase_order set receipt_status = 'full' where id = datas.po_id;
			
			-- debit
			insert into account_move_line(
				move_id,
				account_id,
				journal_id,
				
				partner_id,
				
				company_currency_id,
				currency_id,
				company_id,
				display_type,
				product_id, 
-- 				product_uom_id,
				parent_state,
				move_name,
				
				name,
				date,
				debit,
				credit,
				quantity,
				
				price_unit,
				price_subtotal,
				price_total,
				
				purchase_line_id,

				create_uid,
				write_uid,
				create_date,
				write_date

			) values(
				acc_move_id,
				datas.acc_move_line_id_debit,
				journal.id,
				datas.partner_id,
				datas.currency_id,
				datas.currency_id,
				datas.company_id,
				'product',
				datas.product_id,
				acmove.state,
				acmove.name,
				
-- 				'label',
				concat(datas.product_code), 
				now(),
				abs(datas.quantity*datas.unit_cost),
				0,
				datas.quantity,
				
				datas.unit_cost,
				(datas.quantity*datas.unit_cost),
				(datas.quantity*datas.unit_cost),
				
				datas.po_line,
				
				1,1,now(),now()
			
			);
			
			-- credit
			INSERT INTO account_move_line(
		
				move_id,
				name,
				partner_id, 
				company_id,
				company_currency_id,
				currency_id,
				
				date,
				product_id,
				ref,
				journal_id,
				parent_state,
				move_name,
				
				display_type,
				account_id,
				debit,
				credit,
				quantity,
				
				price_unit,
				price_subtotal,
				price_total,

				create_uid, 
				create_date, 
				write_uid, 
				write_date,

				origin_id
			) values(
				acc_move_id,
				concat(datas.product_code),
				datas.partner_id,
				datas.company_id,
				datas.currency_id,
				datas.currency_id,
				
				now(),
				datas.product_id,
				'Inventory Valuation',
				datas.journal_id,
				acmove.state,
				acmove.name,
				
				'payment_term',
				datas.acc_move_line_id_credit,
				0,
				abs(datas.quantity*datas.unit_cost),
				datas.quantity,
				
				datas.unit_cost,
				(datas.quantity*datas.unit_cost),
				(datas.quantity*datas.unit_cost),
				
				1, 
				now(), 
				1, 
				now(),
				datas.origin_id
			);
			
			raise notice 'account move line credit';
		end loop;
		
		update purchase_order_line set qty_invoiced = datas.quantity where order_id=datas.po_id;
		update purchase_order set amount_total = (datas.unit_cost*datas.quantity) where id=datas.po_id;
		update inventory_transaction_temp set acc_move_id = acmove.id where origin_id=datas.origin_id;
		raise notice 'ISENG CEK TEMP : % ', datas;
		
	
	end;
$$;

-- -

--- stock valuation layer
create or replace function mapping_stock_valuation_layer()
returns void
language plpgsql
as $$
	declare
	datas record;
	vayer_id int;
	svel record;
	begin
		for datas in select * from inventory_transaction_temp
		loop
			raise notice 'TEMP : %', datas;
-- 			select * from product_template pt 
-- 			join product_product pp on pp.product_tmpl_id = pt.id
-- 			join inventory_transaction_temp ivet on ivet.product_id = pp.id 
-- 			where pt.default_code = ivet.product_code;
			
			
			insert into stock_valuation_layer(
				company_id,
				product_id,
				stock_move_id,
				description,
				quantity,
				unit_cost,
				value,
				remaining_qty,
				remaining_value,

				create_uid,
				create_date,
				write_uid,
				write_date,
				
				origin_id
				
			) values (
				datas.company_id,
				datas.product_id,
				datas.move_id,
				(select pt.name from product_template pt 
				join product_product pp on pp.product_tmpl_id = pt.id
				join inventory_transaction_temp ivet on ivet.product_id = pp.id 
				where pt.default_code = ivet.product_code),
				datas.quantity,
				datas.unit_cost,
				datas.value,
				datas.quantity,
				datas.value,
				1,now(),1,now(),
				
				datas.origin_id
				
			) returning id into vayer_id;
			
			update inventory_transaction_temp set svl_id = vayer_id where origin_id=datas.origin_id;
		end loop;
		
		-- update standard price
		-- select all product from stock valuaion layer
		-- group it by product
		-- join with product
		-- check the category id of the product
		-- if product using average
		-- set the quantity with formula
		-- new value = sum(value)/quantity
		-- update the product standard price using new value
		
		-- insert into ir_property(company_id,fields_id, name, res_id, type,value_float)
		-- values(1,2905,'standard_price', 'product.product,41','float',60);
		
		raise notice 'STOCK VALUATION LAYER ';
	end;
$$;



DROP TRIGGER IF EXISTS notif_transaction_trigger ON inventory_transaction_notification CASCADE;
CREATE TRIGGER notif_transaction_trigger 
AFTER UPDATE ON inventory_transaction_notification
FOR EACH ROW EXECUTE FUNCTION mapping_transaction_data_temp();


