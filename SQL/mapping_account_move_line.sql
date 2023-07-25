-- MAPPING ACCOUNT MOVE LINE
DROP FUNCTION IF EXISTS mapping_account_move_line();
CREATE OR REPLACE FUNCTION public.mapping_account_move_line()
RETURNS void
LANGUAGE plpgsql
AS $$
    BEGIN
        RAISE notice 'mapping_account_move_line Start at: %', now();
        RAISE notice 'Acc Move Line Debit';
        
        INSERT INTO account_move_line(
            id, 
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
            
            account_id,
            debit,
            credit,
            quantity,

            create_uid, 
            create_date, 
            write_uid, 
            write_date,
            
            origin_id
        )
        WITH data_unnest_acc_move_line AS (
            SELECT unnest(array['acc_move_line_id_debit', 'acc_move_line_id_credit']) AS data_move_line, 
                acc_move_id AS acc_move_id,
                unnest(array[acc_move_line_id_debit, acc_move_line_id_credit]) AS acc_move_line_id
            FROM inventory_transaction_temp
        )
        SELECT 
            aml.acc_move_line_id as id,
            rec.acc_move_id as move_id,
            concat(sp.name,' - ',rec.product_code) as name,
            rec.partner_id as partner_id,
            rec.company_id as company_id,
            rec.currency_id as company_currency_id,
            rec.currency_id as currency_id,
            transaction_date as date,
            rec.product_id as product_id,
            'Inventory Valuation' as ref,
            rec.journal_id as journal_id,
            
            rec.debit_account_id as account_id,
            abs(rec.value) as debit,
            0 as credit,
            case
                when rec.move_type = 1 then
                    quantity
                else
                    quantity*-1
            end as quantity,
            
            1, 
            now(), 
            1, 
            now(),
            
            rec.origin_id as origin_id
        FROM data_unnest_acc_move_line aml  
        JOIN inventory_transaction_temp rec ON rec.acc_move_id = aml.acc_move_id
        LEFT JOIN stock_picking sp ON sp.id = rec.picking_id
        WHERE aml.data_move_line = 'acc_move_line_id_debit';
        
        RAISE notice 'Acc Move Line Credit';
        INSERT INTO account_move_line(
            id, 
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
            
            account_id,
            debit,
            credit,
            quantity,

            create_uid, 
            create_date, 
            write_uid, 
            write_date,
            
            origin_id
        )
        WITH data_unnest_acc_move_line AS (
            SELECT unnest(array['acc_move_line_id_debit', 'acc_move_line_id_credit']) AS data_move_line, 
                acc_move_id AS acc_move_id,
                unnest(array[acc_move_line_id_debit, acc_move_line_id_credit]) AS acc_move_line_id
            FROM inventory_transaction_temp
        )
        SELECT 
            aml.acc_move_line_id as id,
            rec.acc_move_id as move_id,
            concat(sp.name,' - ',rec.product_code) as name,
            rec.partner_id as partner_id,
            rec.company_id as company_id,
            rec.currency_id as company_currency_id,
            rec.currency_id as currency_id,
            transaction_date as date,
            rec.product_id as product_id,
            'Inventory Valuation' as ref,
            rec.journal_id as journal_id,
            
            rec.credit_account_id as account_id,
            0 as debit,
            abs(rec.value) as credit,
            case
                when rec.move_type = 1 then
                    quantity
                else
                    quantity*-1
            end as quantity,
            
            1, 
            now(), 
            1, 
            now(),
            
            rec.origin_id as origin_id
        FROM data_unnest_acc_move_line aml  
        JOIN inventory_transaction_temp rec ON rec.acc_move_id = aml.acc_move_id
        LEFT JOIN stock_picking sp ON sp.id = rec.picking_id
        WHERE aml.data_move_line = 'acc_move_line_id_credit';
        
        RAISE notice 'mapping_account_move_line End at: %', now();

    END;
$$;