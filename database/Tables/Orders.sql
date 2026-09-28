CREATE TABLE [dbo].[Orders]
(
    [OrderId] BIGINT IDENTITY (1, 1) NOT NULL,
    [CustomerId] INT NOT NULL,
    [OrderDate] DATETIME2(3) CONSTRAINT [DF_Orders_OrderDate] DEFAULT (SYSUTCDATETIME()) NOT NULL,
    [Status] VARCHAR(20) CONSTRAINT [DF_Orders_Status] DEFAULT ('Pending') NOT NULL,
    CONSTRAINT [PK_Orders] PRIMARY KEY CLUSTERED ([OrderId]),
    CONSTRAINT [FK_Orders_Customers] FOREIGN KEY ([CustomerId]) REFERENCES [dbo].[Customers] ([CustomerId]),
    CONSTRAINT [CK_Orders_Status] CHECK ([Status] IN ('Pending', 'Paid', 'Shipped', 'Cancelled'))
);
GO
CREATE INDEX [IX_Orders_CustomerId_OrderDate]
    ON [dbo].[Orders] ([CustomerId], [OrderDate] DESC)
    INCLUDE ([Status]);
