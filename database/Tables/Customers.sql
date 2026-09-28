CREATE TABLE [dbo].[Customers]
(
    [CustomerId] INT IDENTITY (1, 1) NOT NULL,
    [Email] NVARCHAR(320) NOT NULL,
    [DisplayName] NVARCHAR(200) NOT NULL,
    [IsActive] BIT CONSTRAINT [DF_Customers_IsActive] DEFAULT (1) NOT NULL,
    [CreatedAt] DATETIME2(3) CONSTRAINT [DF_Customers_CreatedAt] DEFAULT (SYSUTCDATETIME()) NOT NULL,
    CONSTRAINT [PK_Customers] PRIMARY KEY CLUSTERED ([CustomerId]),
    CONSTRAINT [CK_Customers_Email] CHECK ([Email] LIKE '%_@_%._%'),
    CONSTRAINT [UQ_Customers_Email] UNIQUE ([Email])
);
