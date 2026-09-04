create database banking_fraud;
use banking_fraud;

create table staging_transactions (
    Transaction_ID varchar(50),
    Customer_ID varchar(50),
    Card_ID varchar(50),
    Customer_Age int,
    Customer_Gender varchar(20),
    City varchar(100),
    Transaction_Date varchar(20),
    Day int,
    Month_name varchar(20),
    Year int,
    Transaction_Time time,
    Merchant varchar(150),
    Category varchar(100),
    Amount_EGP decimal(12,2),
    Payment_Method varchar(50),
    Channel varchar(50),
    Device varchar(100),
    Account_Age_Months int,
    Account_Age_Category varchar(50),
    Transaction_Count_24h int,
    Avg_Amount_30d decimal(12,2),
    Distance_From_Home_KM decimal(10,2),
    Failed_Attempts_24h int,
    International varchar(10),
    Card_Present varchar(10),
    IP_Risk_Score decimal(5,2),
    Fraud_Score decimal(5,2),
    Fraud varchar(10),
    Amount_To_Avg_Ratio decimal(10,4),
    Anomaly_Level varchar(50)
);

load data local infile 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/banking_fraud_clean.csv'
into table staging_transactions
fields terminated by ','
enclosed by '"'
lines terminated by '\r\n'
ignore 1 lines;

select count(*) as staging_rows_after_load from staging_transactions;

set sql_safe_updates = 0;

update staging_transactions
set Transaction_Date = str_to_date(Transaction_Date, '%m/%d/%Y')
where Transaction_Date regexp '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}$';

set sql_safe_updates = 1;

select Transaction_Date
from staging_transactions
where Transaction_Date not regexp '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
limit 20;

select distinct Fraud from staging_transactions;
select distinct International from staging_transactions;
select distinct Card_Present from staging_transactions;



create table Customer (
    Customer_ID varchar(50) primary key,
    Customer_Age int,
    Customer_Gender varchar(20),
    City varchar(100)
);

insert into Customer (Customer_ID, Customer_Age, Customer_Gender, City)
select Customer_ID, Customer_Age, Customer_Gender, City
from (
    select
        Customer_ID,
        Customer_Age,
        Customer_Gender,
        City,
        row_number() over (partition by Customer_ID order by Transaction_ID) as rn
    from staging_transactions
    where Customer_ID is not null and Customer_ID <> ''
) c
where rn = 1;



create table Card (
    Card_ID varchar(50) primary key,
    Customer_ID varchar(50) not null,

    foreign key (Customer_ID)
        references Customer(Customer_ID)
);

insert into Card (Card_ID, Customer_ID)
select Card_ID, min(Customer_ID)
from staging_transactions
where Card_ID is not null and Card_ID <> ''
group by Card_ID;


create table Category (
    Category_ID int auto_increment primary key,
    Category_Name  varchar(100) not null unique
);

insert into Category (Category_Name)
select distinct Category
from staging_transactions
where Category is not null and Category <> '';



create table Merchant (
    Merchant_ID int auto_increment primary key,
    Merchant_Name varchar(150) not null,
    Category_ID int not null,

    foreign key (Category_ID)
        references Category(Category_ID),

    unique key uq_merchant_category (Merchant_Name, Category_ID)
);

insert into Merchant (Merchant_Name, Category_ID)
select distinct s.Merchant, c.Category_ID
from staging_transactions s
join Category c
    on c.Category_Name = s.Category
where s.Merchant is not null and s.Merchant <> '';



create table Payment_Method (
    Payment_ID INT auto_increment primary key,
    Payment_Name VARCHAR(50) not null unique
);

insert into Payment_Method (Payment_Name)
select distinct Payment_Method
from staging_transactions
where Payment_Method is not null and Payment_Method <> '';



create table Channel (
    Channel_ID int auto_increment primary key,
    Channel_Name varchar(50) not null unique
);

insert into Channel (Channel_Name)
select distinct Channel
from staging_transactions
where Channel is not null and Channel <> '';



create table Device (
    Device_ID int auto_increment primary key,
    Device_Name varchar(100) not null unique
);

insert into Device (Device_Name)
select distinct Device
from staging_transactions
where Device is not null and Device <> '';



create table Transactions (
    Transaction_ID varchar(50) primary key,

    Customer_ID varchar(50) not null,
    Card_ID     varchar(50) not null,
    Merchant_ID int not null,
    Payment_ID  int not null,
    Channel_ID int not null,
    Device_ID  int not null,

    Transaction_Date date,
    Transaction_Time time,

    Day  int,
    Month_name varchar(20),
    Year int,

    Amount_EGP decimal(12,2),

    Account_Age_Months int,
    Account_Age_Category varchar(50),

    Transaction_Count_24h int,
    Avg_Amount_30d decimal(12,2),
    Distance_From_Home_KM decimal(10,2),
    Failed_Attempts_24h int,

    International varchar(10),
    Card_Present varchar(10),

    IP_Risk_Score decimal(5,2),
    Fraud_Score decimal(5,2),
    Fraud varchar(10),
    Amount_To_Avg_Ratio decimal(10,4),
    Anomaly_Level varchar(50),

    foreign key (Customer_ID)
        references Customer(Customer_ID),

    foreign key (Card_ID)
        references Card(Card_ID),

    foreign key (Merchant_ID)
        references Merchant(Merchant_ID),

    foreign key (Payment_ID)
        references Payment_Method(Payment_ID),

    foreign key (Channel_ID)
        references Channel(Channel_ID),

    foreign key (Device_ID)
        references Device(Device_ID)
);

insert into Transactions (
    Transaction_ID,
    Customer_ID,
    Card_ID,
    Merchant_ID,
    Payment_ID,
    Channel_ID,
    Device_ID,
    Transaction_Date,
    Day,
    Month_name,
    Year,
    Transaction_Time,
    Amount_EGP,
    Account_Age_Months,
    Account_Age_Category,
    Transaction_Count_24h,
    Avg_Amount_30d,
    Distance_From_Home_KM,
    Failed_Attempts_24h,
    International,
    Card_Present,
    IP_Risk_Score,
    Fraud_Score,
    Fraud,
    Amount_To_Avg_Ratio,
    Anomaly_Level
)
select
    s.Transaction_ID,
    s.Customer_ID,
    s.Card_ID,
    m.Merchant_ID,
    p.Payment_ID,
    ch.Channel_ID,
    d.Device_ID,
    s.Transaction_Date,
    s.Day,
    s.Month_name,
    s.Year,
    s.Transaction_Time,
    s.Amount_EGP,
    s.Account_Age_Months,
    s.Account_Age_Category,
    s.Transaction_Count_24h,
    s.Avg_Amount_30d,
    s.Distance_From_Home_KM,
    s.Failed_Attempts_24h,
    s.International,
    s.Card_Present,
    s.IP_Risk_Score,
    s.Fraud_Score,
    s.Fraud,
    s.Amount_To_Avg_Ratio,
    s.Anomaly_Level
from staging_transactions s

join Merchant m
    on m.Merchant_Name = s.Merchant
   and m.Category_ID = (
       select c.Category_ID
       from Category c
       where c.Category_Name = s.Category
   )

join Payment_Method p
    on p.Payment_Name = s.Payment_Method

join Channel ch
    on ch.Channel_Name = s.Channel

join Device d
    on d.Device_Name = s.Device;

select count(*) as staging_count from staging_transactions;
select count(*) as transactions_count from Transactions;
select count(*) as customer_count from Customer;
select count(*) as card_count from Card;
select count(*) as merchant_count from Merchant;
select count(*) as category_count from Category;
select count(*) as payment_count from Payment_Method;
select count(*) as channel_count from Channel;
select count(*) as device_count from Device;


select Transaction_ID, Transaction_Date, Day, Year, Month_name
from Transactions
limit 10;


select * from Transactions ;


select 
Transaction_ID,
Customer_ID,
Amount_EGP
from Transactions
where Amount_EGP > (
    select avg(Amount_EGP)
    from Transactions
    where Fraud ='TRUE'
);


select
Customer_ID,
Customer_Age,
City
from Customer
where Customer_ID in (
    select distinct Customer_ID
    from Transactions
    where Fraud ='TRUE'
);


select
City,
    avg(Fraud_Count) as Avg_Fraud_Per_Customer
from (
    select
        c.City,
        c.Customer_ID,
        COUNT(t.Transaction_ID) as Fraud_Count
    from Customer c
    join Transactions t on c.Customer_ID = t.Customer_ID
    where t.Fraud ='TRUE'
    group by c.City, c.Customer_ID
) as CustomerFraudSummary
group by City;


select
t1.Transaction_ID,
t1.Customer_ID,
t1.Amount_EGP
from Transactions t1
where t1.Amount_EGP > (
   select avg(t2.Amount_EGP)
    from Transactions t2
    where t2.Customer_ID = t1.Customer_ID
);

select
t.Transaction_ID,
c.Customer_ID,
c.City,
m.Merchant_Name,
p.Payment_Name,
t.Amount_EGP,
t.Fraud
from Transactions t
inner join  Customer c on t.Customer_ID = c.Customer_ID
inner join  Merchant m on t.Merchant_ID = m.Merchant_ID
inner join Payment_Method p on t.Payment_ID = p.Payment_ID;


select
c.Customer_ID,
c.City,
COUNT(t.Transaction_ID) as Total_Transactions,
SUM(t.Amount_EGP) as Total_Spent
from Customer c
left join Transactions t on c.Customer_ID = t.Customer_ID
group by c.Customer_ID, c.City;


select
p.Payment_Name,
COUNT(t.Transaction_ID) as Total_Transactions
from Transactions t
right join Payment_Method p on t.Payment_ID = p.Payment_ID
group by p.Payment_ID, p.Payment_Name;


#__________part 2_______________
SELECT
    COUNT(*) AS Total_Transactions,
    SUM(Amount_EGP) AS Total_Amount_EGP,
    ROUND(AVG(Amount_EGP), 2) AS Avg_Amount_EGP,
    MIN(Amount_EGP) AS Min_Amount_EGP,
    MAX(Amount_EGP) AS Max_Amount_EGP
FROM Transactions;



SELECT
    COUNT(*) AS Fraud_Transaction_Count,
    SUM(Amount_EGP) AS Total_Fraud_Amount,
    ROUND(AVG(Amount_EGP), 2) AS Avg_Fraud_Amount,
    MIN(Amount_EGP) AS Min_Fraud_Amount,
    MAX(Amount_EGP)AS Max_Fraud_Amount,
    ROUND(AVG(Fraud_Score), 2) AS Avg_Fraud_Score
FROM Transactions
WHERE Fraud = 'TRUE';



SELECT
Transaction_ID, Fraud_Score,
    CASE
        WHEN Fraud_Score >= 70 THEN 'High Risk'
        WHEN Fraud_Score >= 40 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS Risk_Level
FROM Transactions;



SELECT
COUNT(CASE WHEN Fraud = 'TRUE' THEN 1 END) AS Fraudulent_Transactions,
COUNT(CASE WHEN Fraud = 'FALSE' THEN 0 END) AS Legitimate_Transactions
FROM Transactions;


SELECT
Year,Month_name,
COUNT(*) AS Transaction_Count,
SUM(Amount_EGP) AS Total_Amount
FROM Transactions
GROUP BY Year, Month_name
ORDER BY Year, FIELD(Month_name,
    'January','February','March','April','May','June',
    'July','August','September','October','November','December');
    

SELECT
Transaction_ID,
Transaction_Date,
YEAR(STR_TO_DATE(Transaction_Date, '%Y-%m-%d')) AS Year,
MONTHNAME(STR_TO_DATE(Transaction_Date, '%Y-%m-%d')) AS Month,
DAY(STR_TO_DATE(Transaction_Date, '%Y-%m-%d')) AS Day
FROM Transactions;


SELECT
Fraud,COUNT(*) AS Transaction_Count,
SUM(Amount_EGP) AS Total_Amount,
AVG(Amount_EGP) AS Average_Amount
FROM Transactions
GROUP BY Fraud;


SELECT
Transaction_ID,
Customer_ID,
Amount_EGP,
RANK() OVER (ORDER BY Amount_EGP DESC) AS Amount_Rank
FROM Transactions;


SELECT
Transaction_ID,
Customer_ID,
Amount_EGP,
SUM(Amount_EGP) OVER (
        PARTITION BY Customer_ID
        ORDER BY Transaction_ID
    ) AS Running_Total
FROM Transactions;
