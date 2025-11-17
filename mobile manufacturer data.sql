--SQL Advance Case Study
use db_sqlcasestudies
select * from fact_transactions

--Q1--BEGIN 

select distinct l.state  from dim_location as l
join fact_transactions as t on l.idlocation = t.idlocation	
where t.transactiondate > '2004-12-31'

--Q1--END

--Q2--BEGIN
	
select l.state , count(t.idmodel) as sam_phone_sold from dim_location as l
join fact_transactions as t on l.idlocation = t.idlocation
join dim_model as m on t.idmodel = m.idmodel
where l.country = 'us' and m.idmanufacturer = '12'
group by l.state 
order by count(t.idmodel) desc limit 1 

--Q2--END

--Q3--BEGIN      
	
select  m.idmodel,l.state , l.zipcode ,count(*) as total_tran  from fact_transactions as t 
join dim_location as l on t.idlocation = l.idlocation 
join dim_model as m on t.idmodel = m.idmodel
group by m.idmodel,l.state , l.zipcode 

--Q3--END

--Q4--BEGIN

select distinct ma.manufacturer_name,m.model_name,m.unit_price from dim_manufacturer as ma
join dim_model as m on ma.idmanufacturer = m.idmanufacturer
order by m.unit_price asc limit 1

--Q4--END

--Q5--BEGIN

SELECT 
    m.manufacturer_name,
    mo.model_name,
    ROUND(AVG(mo.unit_price), 2) AS avg_price
FROM dim_model AS mo
JOIN dim_manufacturer AS m ON m.idmanufacturer = mo.idmanufacturer
JOIN fact_transactions AS t ON t.idmodel = mo.idmodel
JOIN (
    SELECT m2.idmanufacturer
    FROM dim_manufacturer AS m2
    JOIN dim_model AS mo2 ON m2.idmanufacturer = mo2.idmanufacturer
    JOIN fact_transactions AS t2 ON t2.idmodel = mo2.idmodel
    GROUP BY m2.idmanufacturer
    ORDER BY SUM(t2.quantity) DESC
    LIMIT 5
) AS top5 ON m.idmanufacturer = top5.idmanufacturer
GROUP BY m.manufacturer_name, mo.model_name
ORDER BY avg_price DESC;

--Q5--END

--Q6--BEGIN

select c.customer_name,round(avg(t.totalprice),2) as avg_spend from dim_customer as c 
join fact_transactions as t on c.idcustomer = t.idcustomer
where year(t.transactiondate) = '2009' 
group by c.customer_name 
having round(avg(t.totalprice),2) > 500
order by round(avg(t.totalprice),2) desc

--Q6--END
	
--Q7--BEGIN  
select  distinct a.model_name from	
(select m.model_name,sum(t.quantity) from dim_model as m 
join fact_transactions as t on m.idmodel = t.idmodel
where year(t.transactiondate) = 2008
group by m.model_name
order by sum(t.quantity) desc limit 5) as a
join
(select m.model_name,sum(t.quantity) from dim_model as m 
join fact_transactions as t on m.idmodel = t.idmodel
where year(t.transactiondate) = 2009
group by m.model_name
order by sum(t.quantity) desc limit 5)as b 
join
(select m.model_name,sum(t.quantity) from dim_model as m 
join fact_transactions as t on m.idmodel = t.idmodel
where year(t.transactiondate) = 2010
group by m.model_name
order by sum(t.quantity) desc limit 5) as c
on a.model_name = c.model_name

--Q7--END	
--Q8--BEGIN

select manufacturer_name,sales_year,total_sales from
(select year(t.transactiondate) as sales_year,m.manufacturer_name , sum(t.totalprice) as total_sales from dim_manufacturer as m
join dim_model as mo on m.idmanufacturer = mo.idmanufacturer
join fact_transactions as t on t.idmodel = mo.idmodel
where year(t.transactiondate) = 2009
group by m.manufacturer_name,year(t.transactiondate)
order by sum(t.totalprice) desc limit 1 offset 1) as a
union
select manufacturer_name,sales_year,total_sales from
(select year(t.transactiondate) as sales_year,m.manufacturer_name , sum(t.totalprice) as total_sales from dim_manufacturer as m
join dim_model as mo on m.idmanufacturer = mo.idmanufacturer
join fact_transactions as t on t.idmodel = mo.idmodel
where year(t.transactiondate) = 2010
group by m.manufacturer_name,year(t.transactiondate)
order by sum(t.totalprice) desc limit 1 offset 1) as b

--Q8--END

--Q9--BEGIN
	
select distinct m.manufacturer_name  from dim_manufacturer as m
join dim_model as mo on m.idmanufacturer = mo.idmanufacturer
join fact_transactions as t on t.idmodel = mo.idmodel
where year(t.transactiondate) = 2010 and m.manufacturer_name not in (
	select distinct m.manufacturer_name  from dim_manufacturer as m
	join dim_model as mo on m.idmanufacturer = mo.idmanufacturer
	join fact_transactions as t on t.idmodel = mo.idmodel
	where year(t.transactiondate) = 2009
)    
	
--Q9--END

--Q10--BEGIN
	
SELECT 
    yd.customer_name,
    yd.year,
    yd.avg_spend,
    yd.avg_quantity,
    ROUND(
        ( (yd.avg_spend - LAG(yd.avg_spend) OVER (PARTITION BY yd.customer_name ORDER BY yd.year))
          / LAG(yd.avg_spend) OVER (PARTITION BY yd.customer_name ORDER BY yd.year) * 100 ), 2
    ) AS percent_change_spend
FROM (
    SELECT 
        c.customer_name,
        YEAR(t.transactiondate) AS year,
        ROUND(AVG(t.totalprice), 2) AS avg_spend,
        ROUND(AVG(t.quantity), 2) AS avg_quantity
    FROM dim_customer AS c
    JOIN fact_transactions AS t ON c.idcustomer = t.idcustomer
    JOIN (
        SELECT idcustomer
        FROM (
            SELECT idcustomer
            FROM fact_transactions
            GROUP BY idcustomer
            ORDER BY SUM(totalprice) DESC
            LIMIT 100
        ) AS top100
    ) AS tc ON c.idcustomer = tc.idcustomer
    GROUP BY c.customer_name, YEAR(t.transactiondate)
) AS yd
ORDER BY yd.customer_name, yd.year;

--Q10--END
	