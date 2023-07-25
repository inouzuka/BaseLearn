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
	BEGIN
		select id, name, date_order, state, write_date, create_date, create_uid, write_uid from purchase_order where id=po_id into po_data;
		RAISE NOTICE '== herer % ', po_data;
		
-- 		select * from inventory_transaction_temp into trantemp where ;
		
-- 		FOR porder in select id, partner_id, name, date_order, state, company_id, currency_id from purchase_order where id=po_data.id
		FOR porder in select * from purchase_order where id=po_data.id
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
			raise notice 'create stock picking';
			
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
				create_uid, 
				write_uid, 
				create_date, 
				write_date
			) values (
				4, 
				8, 
				1,
				porder.name,
				porder.partner_id, 
				porder.company_id, 
				pg.id, 
				1, 
				now(), 
				pg.name, 
				'assigned', 
				pg.move_type, 
				now(), 
				1, 
				1, 
				now(), 
				now()
			);
			
			select id, name, location_id, location_dest_id, picking_type_id, partner_id,
				company_id, group_id, user_id, date, origin, state, move_type from stock_picking where name=pg.name into stp;
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
					state, origin, procure_method, product_qty, product_uom_qty, date, reference, purchase_line_id
				) VALUES (
					pol_data.company_id, pol_data.product_id, pol_data.product_uom, 
					stp.location_id, stp.location_dest_id, pg.partner_id, stp.id,
					pg.id, stp.picking_type_id, 1, 1, now(), now(), stp.name,
					stp.state, stp.name, 'make_to_stock', pol_data.product_uom, pol_data.product_uom_qty, now(), stp.name, pol_data.id 
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
					reference, date, create_date, write_date, reserved_uom_qty
				) VALUES (
					stp.id, sm.id, pol_data.company_id, pol_data.product_id, pol_data.product_uom,
					stp.location_id, stp.location_dest_id, 1, 1, sm.state,
					sm.origin, now(), now(), now(), pol_data.product_uom_qty
				);
				select picking_id, move_id, company_id, product_id, product_uom_id, 
					location_id, location_dest_id, create_uid, write_uid, state, 
					reference, date, create_date, write_date from stock_move_line where picking_id=stp.id into sml;
				raise notice '1 stock move line : %', sml;
			END LOOP;
			raise notice 'stock move: % ', sm;
			raise notice 'stock move line : %', sml;
-- 			perform update_inventory_stock_quant();
			-- stock quant 
			
			FOR picking in SELECT * FROM stock_picking where id=stp.id
			LOOP
				RAISE NOTICE '----';
				RAISE NOTICE 'picking ORI %', stp.id;
				RAISE NOTICE 'picking SINI %', picking.id;
				
				UPDATE stock_picking SET state='done', write_uid = 1, write_date = now() WHERE id = picking.id;
				UPDATE stock_move SET qty_done=stp.product_uom_qty, write_uid = 1, write_date = now() WHERE picking_id = picking.id;
				UPDATE stock_move SET state='done', write_uid = 1, write_date = now() WHERE picking_id = picking.id;
				UPDATE stock_move_line SET qty_done=stp.product_uom_qty, write_uid = 1, write_date = now() WHERE picking_id = picking.id;
				UPDATE stock_move_line SET state='done', write_uid = 1, write_date = now() WHERE picking_id = picking.id;
				
				FOR prod in 
					SELECT id, product_id, location_id, location_dest_id, SUM(product_uom_qty) as qty 
					FROM stock_move 
					WHERE picking_id = stp.id 
					GROUP BY product_id, location_id, location_dest_id, id
				LOOP
					RAISE NOTICE '----';
					RAISE NOTICE 'Move %', prod.id;
					RAISE NOTICE 'Move %', prod;
					RAISE NOTICE 'DEST QUANT';
					
					SELECT id FROM stock_quant WHERE product_id = prod.product_id AND location_id = prod.location_dest_id INTO loc_des;
					IF loc_des IS NULL THEN
						RAISE NOTICE 'NOT YET CREATED';
						INSERT INTO stock_quant(
							product_id, company_id, location_id, 
							quantity, reserved_quantity, in_date,
							create_uid, create_date, write_uid, write_date)
						SELECT 
							sm.product_id, 1, sm.location_dest_id, 
							1, SUM(prod.qty), now(),
							1, NOW(), 1, NOW()
						FROM stock_move sm
						WHERE sm.product_id = prod.product_id AND sm.location_id = prod.location_dest_id
						GROUP BY sm.product_id, sm.location_dest_id;
					ELSE 
						RAISE NOTICE 'CREATED';
						UPDATE stock_quant sq 
						SET 
							quantity = sq.quantity + prod.qty,
							reserved_quantity = sq.quantity + prod.qty,
							write_uid = 1, 
							write_date = now()
						WHERE 
							sq.product_id = prod.product_id AND
							sq.location_id = prod.location_dest_id;
					
					END IF;
					
				END LOOP;

			END LOOP;
			
		END LOOP;
		
	EXCEPTION
		WHEN OTHERS THEN
		RAISE exception 'raise here, please check all part on the line ->';
	
	END 
$$;

select transaction_po(76)
