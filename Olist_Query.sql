-- Processo Seletivo Olist (Vaga: Analista de BI & Analytics Sênior)

-- Nome: Vitor Eidi Ando Yamada
-- Data Início: 22/03/2021 23:28
-- Data Fim:

--Conhecendo as Tables:
select top 1000 * from [dbo].[olist_customers_dataset]				--| customer_id (E), unique_id, zip_code_prefix (A), customer_city (B), customer_state (C)
select top 1000 * from [dbo].[olist_geolocation_dataset]			--|	geo_zip_code_prefix (A), geo_lat, geo_lng, geo_city (B), geo_state (C)
select top 1000 * from [dbo].[olist_order_items_dataset]			--| order_id (D), order_item_id, product_id (F), seller_id (G), shipping_limit_date, price, freight_value
select top 1000 * from [dbo].[olist_order_payments_dataset]			--| order_id (D), payment_sequencial, payment_type, payment_installments, payment_value
select top 1000 * from [dbo].[olist_order_reviews_dataset]			--| Erro ao importar dados
select top 1000 * from [dbo].[olist_orders_dataset]					--| order_id (D), customer_id (E), order_status, order_purchase_timestamp, order_approved_at, order_delivered_carrier_date, order_delivered_customer_date, order_estimated_delivery_date
select top 1000 * from [dbo].[olist_products_dataset]				--| product_id (F), product_category_name, product_name_lenght, product_description_lenght, product_photos_qty, product_weight_g, product_lenght_cm, product_height_cm, product_width_cm
select top 1000 * from [dbo].[olist_sellers_dataset]				--| seller_id (G), seller_zip_code_prefix (A), seller_city (B), seller_state (C)
select top 1000 * from [dbo].[product_category_name_translation]	--| product_category_name, product_category_name_english

-- DESAFIO:
-- 1. Será que nossos diferentes lojistas associados conseguem manter o preço do mesmo produto sem grandes discrepâncias?
-- 2. Podemos dar os mesmos benefícios para todos os lojistas (sellers)? Ou existe algum que merece destaque?
-- 3. Existe diferença no valor do frete praticado em regiões/cidades diferentes? Ou podemos aplicar as mesmas regras de subsídio de frete para qualquer localidade?
-- 4. Será que nosso catálogo de produtos é abrangente? Ou tem foco em categorias específicas?
-- 5. Será que sempre vendemos os mesmos produtos? Ou existem sazonalidades?
-- 6. Será que existe um modelo preditivo para nos preparar para o futuro?
-- 7. Será que o atual banco de dados vai suportar o nosso crescimento? Ou existe uma opção mais escalável?

-- DICAS:
-- Pense em alguns KPIs para monitoramento. Talvez outros para direcionamento dos gestores!
-- Um cruzamento dos dados poderia gerar relatórios interessantes. Afinal, quem são os Top 10 em vendas? Que tipo produtos eles vendem? Qual é o impacto deles para o negócio?
-- Que tal realizar uma análise exploratória dos dados. E então? Algo lhe chama a atenção?
-- Você poderia apresentar esses dados em um dashboard. Isso daria agilidade na tomada de decisão!
-- Temos interesse em suas habilidades com matemática aplicada e estatística descritiva. O que você pode nos mostrar com os dados?
-- O que acha de escrever um relatório ou slides detalhando as suas descobertas?
-- Fique livre para criar sua própria abordagem, caso considere que as dicas anteriores não sejam pertinentes.


-- [RESOLUÇÃO]

-- 1. Para resolução, buscamos os SKUs com maior variedade de Sellers distintos:
select distinct seller_id from [dbo].[olist_sellers_dataset] -- <- Existem 3.095 Sellers distintos
				
select product_id, count(distinct seller_id) from [dbo].[olist_order_items_dataset] group by product_id order by count(distinct seller_id) desc -- <-  SKUSs com > variação de Sellers
-- 10 SKUs com > Variação de Seller: 69455f41626a745aea9ee9164cb9eafd, d285360f29ac7fd97640bf0baef03de0, 656e0eca68dcecf6a31b8ececfabe3e8, 36f60d45225e60c7da4558b070ce4b60,
--									 4298b7e67dc399c200662b569563a2b2, dbb67791e405873b259e4656bf971246, e0d64dcfaa3b6db5c54ca298ae101d05, be0dbdc3d67d55727a65d4cd696ca73c,
--									 c0abb5707b6d57b4e7d9797222a77fc8, d04e48982547095af81c231c3d581cb6

select 
	I.seller_id,
	product_id,
	["order_purchase_timestamp"],
	price,
	freight_value,
	cast(price as numeric (18,5)) + cast(freight_value as numeric(18,5)) as total_price
from [dbo].[olist_order_items_dataset] I 
		left join [dbo].[olist_sellers_dataset] D on (I.seller_id = D.seller_id)
		left join [dbo].[olist_orders_dataset] O on (I.order_id = replace(O.["order_id"],'"',''))
where product_id = '69455f41626a745aea9ee9164cb9eafd' or product_id = 'd285360f29ac7fd97640bf0baef03de0' 
   or product_id = '656e0eca68dcecf6a31b8ececfabe3e8' or product_id = '36f60d45225e60c7da4558b070ce4b60'
   or product_id = '4298b7e67dc399c200662b569563a2b2' or product_id = 'dbb67791e405873b259e4656bf971246'
   or product_id = 'e0d64dcfaa3b6db5c54ca298ae101d05' or product_id = 'be0dbdc3d67d55727a65d4cd696ca73c'
   or product_id = 'c0abb5707b6d57b4e7d9797222a77fc8' or product_id = 'd04e48982547095af81c231c3d581cb6'
order by I.seller_id
--(cast(price as numeric (18,5)) + cast(freight_value as numeric(18,5))) desc


-- 2. e 4. Dados para saber quem são os Melhores Sellers + Trazendo dados de Categoria:
select 
	S.seller_id,
	I.order_id,
	I.order_item_id,
	I.product_id,
	P.["product_category_name"],
	I.price,
	I.freight_value,
	cast(PA.payment_value as numeric) as payment_value
from [dbo].[olist_sellers_dataset] S
	left join [dbo].[olist_order_items_dataset] I on (S.seller_id = I.seller_id)
	left join [dbo].[olist_products_dataset] P on (replace(P.["product_id"],'"','') = I.product_id)
	left join [dbo].[olist_order_payments_dataset] PA on (PA.order_id = I.order_id)
order by I.order_id desc


select * from [dbo].[olist_order_items_dataset] where order_id = '179394da67149ef0dec1368b27e3b2e0'
select * from [dbo].[olist_products_dataset] where ["product_id"] = 'a2ff5a97bf95719e38ea2e3b4105bce8'
select * from [dbo].[olist_order_items_dataset] where order_id = '0fd408210166f23fe823070a2f690048'
select * from [dbo].[olist_products_dataset] where ["product_id"] = 'd2e131d6f19ae0d665fc1a6c420b4f4c' -- <-Esta TB tem dados com " em algumas células!
select count(*) from [dbo].[olist_order_items_dataset]
select count(distinct seller_id) from [dbo].[olist_order_items_dataset]
select count(distinct seller_id) from [dbo].[olist_sellers_dataset]


-- 3. Query de item_dataset com seller_dataset
select 
	I.order_id,
	I.seller_id,
	I.freight_value,
	I.order_item_id,
	S.seller_state,
	S.seller_city,
	P.["product_weight_g"],
	P.["product_length_cm"],
	P.["product_height_cm"],
	P.["product_width_cm"]
--	G.["geolocation_lat"],
--	G.["geolocation_lng"]
from [dbo].[olist_order_items_dataset] I 
	inner join [dbo].[olist_sellers_dataset] S on (I.seller_id = S.seller_id)
	inner join [dbo].[olist_products_dataset] P on (replace(P.["product_id"],'"','') = I.product_id)
--	inner join [dbo].[olist_geolocation_dataset] G on (replace(G.["geolocation_zip_code_prefix"],'"','') = S.seller_zip_code_prefix)

-- 5. item_dataset, orders_dataset, products_dataset:

select 
	I.product_id,
	I.order_id,
	P.["product_category_name"],
	I.price,
	cast(O.["order_purchase_timestamp"] as date) as purchase_timestamp
from [dbo].[olist_order_items_dataset] I 
	left join [dbo].[olist_orders_dataset] O on (I.order_id = replace(O.["order_id"],'"',''))
	left join [dbo].[olist_products_dataset] P on (replace(P.["product_id"],'"','') = I.product_id)

