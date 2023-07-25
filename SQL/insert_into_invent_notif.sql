UPDATE inventory_transaction_notification 
SET db_name = 'learn3', db_port = 5432, db_host = 'localhost', db_user = 'postgres', db_password = '12345'
WHERE unique_key = 'inventory_transaction_notification';