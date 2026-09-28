CREATE TABLE [dbo].[OrderItems]
(
    [OrderItemId] BIGINT IDENTITY (1, 1) NOT NULL,
    [OrderId] BIGINT NOT NULL,
    [ProductId] INT NOT NULL,
    [Quantity] INT NOT NULL,
    [UnitPrice] DECIMAL(19, 4) NOT NULL,
    CONSTRAINT [PK_OrderItems] PRIMARY KEY CLUSTERED ([OrderItemId]),
    CONSTRAINT [FK_OrderItems_Orders] FOREIGN KEY ([OrderId]) REFERENCES [dbo].[Orders] ([OrderId]) ON DELETE CASCADE,
    CONSTRAINT [FK_OrderItems_Products] FOREIGN KEY ([ProductId]) REFERENCES [dbo].[Products] ([ProductId]),
    CONSTRAINT [CK_OrderItems_Quantity] CHECK ([Quantity] > 0),
    CONSTRAINT [CK_OrderItems_UnitPrice] CHECK ([UnitPrice] >= 0),
    CONSTRAINT [UQ_OrderItems_Order_Product] UNIQUE ([OrderId], [ProductId])
);
GO
CREATE INDEX [IX_OrderItems_ProductId]
    ON [dbo].[OrderItems] ([ProductId])
    INCLUDE ([OrderId], [Quantity], [UnitPrice]);
