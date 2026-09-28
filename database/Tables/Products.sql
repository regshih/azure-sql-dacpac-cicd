CREATE TABLE [dbo].[Products]
(
    [ProductId] INT IDENTITY (1, 1) NOT NULL,
    [Sku] NVARCHAR(50) NOT NULL,
    [Name] NVARCHAR(200) NOT NULL,
    [UnitPrice] DECIMAL(19, 4) NOT NULL,
    [IsActive] BIT CONSTRAINT [DF_Products_IsActive] DEFAULT (1) NOT NULL,
    CONSTRAINT [PK_Products] PRIMARY KEY CLUSTERED ([ProductId]),
    CONSTRAINT [UQ_Products_Sku] UNIQUE ([Sku]),
    CONSTRAINT [CK_Products_UnitPrice] CHECK ([UnitPrice] >= 0)
);
