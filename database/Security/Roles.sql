CREATE ROLE [app_reader];
GO
CREATE ROLE [app_writer];
GO
GRANT SELECT ON SCHEMA::[dbo] TO [app_reader];
GO
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::[dbo] TO [app_writer];
GO
GRANT EXECUTE ON OBJECT::[dbo].[usp_GetCustomerOrders] TO [app_reader];
GO
GRANT EXECUTE ON OBJECT::[dbo].[usp_GetCustomerOrders] TO [app_writer];
GO
DENY ALTER, CONTROL ON SCHEMA::[dbo] TO [app_reader];
GO
DENY ALTER, CONTROL ON SCHEMA::[dbo] TO [app_writer];
