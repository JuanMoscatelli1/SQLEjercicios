1. Mostrar el código, razón social de todos los clientes cuyo límite de crédito sea mayor o
igual a $ 1000 ordenado por código de cliente.

select c.clie_codigo,c.clie_razon_social from Cliente c
where c.clie_limite_credito > 1000
order by 1

2. Mostrar el código, detalle de todos los artículos vendidos en el año 2012 ordenados por
cantidad vendida

select p.prod_codigo,p.prod_detalle
from Item_Factura item join Producto p on item.item_producto = p.prod_codigo
join factura f on item.item_sucursal = f.fact_sucursal
AND item.item_numero = f.fact_numero
AND item.item_tipo = f.fact_tipo
WHERE YEAR(f.fact_fecha)= 2012
GROUP BY p.prod_codigo,p.prod_detalle
ORDER BY SUM(item.item_cantidad) DESC

3. Realizar una consulta que muestre código de producto, nombre de producto y el stock
total, sin importar en que deposito se encuentre, los datos deben ser ordenados por
nombre del artículo de menor a mayor.

select p.prod_codigo,p.prod_detalle,sum(stoc_cantidad) from producto p 
join STOCK s on p.prod_codigo = s.stoc_producto
group by p.prod_codigo,p.prod_detalle
order by 2

4. Realizar una consulta que muestre para todos los artículos código, detalle y cantidad de
artículos que lo componen. Mostrar solo aquellos artículos para los cuales el stock
promedio por depósito sea mayor a 100

--AL HACER UN JOIN SE HACE UN FOR, CHEQUEAR QUE NO AUMENTE EL UNIVERSO!!
--uso el subselect para no ampliar el universo, y hacer que los productos solo 
--sean los que tengan el stock > a 100

select p.prod_codigo,p.prod_detalle, count(c.comp_producto) from Producto p 
LEFT JOIN Composicion c on p.prod_codigo = c.comp_producto
where p.prod_codigo in (select s.stoc_producto from STOCK s
group by s.stoc_producto
having avg(s.stoc_cantidad) >= 0)
group by p.prod_codigo,p.prod_detalle
order by 3 DESC

5. Realizar una consulta que muestre código de artículo, detalle y cantidad de egresos de
stock que se realizaron para ese artículo en el año 2012 (egresan los productos que
fueron vendidos). Mostrar solo aquellos que hayan tenido más egresos que en el 2011.

select p.prod_codigo,p.prod_detalle,sum(i.item_cantidad) from Producto p
join Item_Factura i on i.item_producto = p.prod_codigo
join Factura f on f.fact_tipo+f.fact_sucursal+f.fact_numero
 = i.item_tipo+i.item_sucursal+i.item_numero
 where year(f.fact_fecha) = 2012
group by p.prod_codigo,p.prod_detalle
having sum(i.item_cantidad) >
	(select sum(i2.item_cantidad) from Item_Factura i2
join Factura f2 on f2.fact_tipo+f2.fact_sucursal+f2.fact_numero
 = i2.item_tipo+i2.item_sucursal+i2.item_numero
 where year(f2.fact_fecha) = 2011 AND p.prod_codigo = i2.item_producto) 

6. Mostrar para todos los rubros de artículos código, detalle, cantidad de artículos de ese
rubro y stock total de ese rubro de artículos. Solo tener en cuenta aquellos artículos que
tengan un stock mayor al del artículo ‘00000000’ en el depósito ‘00’.

--el distinct para que no repita por stock

select r.rubr_detalle,r.rubr_id,count(DISTINCT p.prod_codigo),sum(stoc_cantidad) from Rubro r 
left join Producto p on r.rubr_id = p.prod_rubro 
join STOCK s on p.prod_codigo = s.stoc_producto
group by r.rubr_detalle,r.rubr_id
having sum(stoc_cantidad) > (select sum(s2.stoc_cantidad) from STOCK s2 where 
s2.stoc_producto = '00000000' AND s2.stoc_deposito = '00')


7. Generar una consulta que muestre para cada artículo código, detalle, mayor precio
menor precio y % de la diferencia de precios (respecto del menor Ej.: menor precio =
10, mayor precio =12 => mostrar 20 %). Mostrar solo aquellos artículos que posean
stock.

select p.prod_codigo,p.prod_detalle, max(i.item_precio) AS 'MAX', min(i.item_precio) AS 'MIN', 
CAST(((MAX(item_precio) - MIN(item_precio)) / MIN(item_precio)) * 100 AS DECIMAL(10,2)) AS 'Diferencia'
from Producto p 
join Item_Factura i on i.item_producto = p.prod_codigo
join STOCK s on s.stoc_producto = p.prod_codigo
group by p.prod_codigo,p.prod_detalle
having sum(s.stoc_cantidad) > 0 --para saber si tienen stock o no

8. Mostrar para el o los artículos que tengan stock en todos los depósitos, nombre del
artículo, stock del depósito que más stock tiene.

select p.prod_detalle, max(stoc_cantidad) from producto p join STOCK s on p.prod_codigo = s.stoc_producto
where s.stoc_cantidad > 0
group by p.prod_detalle
having count(DISTINCT stoc_deposito) = (select count(*) from DEPOSITO) 

9. Mostrar el código del jefe, código del empleado que lo tiene como jefe, nombre del
mismo y la cantidad de depósitos que ambos tienen asignados.

select e.empl_codigo as 'empleado codigo',e.empl_apellido as 'nombre empleado',e.empl_jefe as 'jefe',e.empl_nombre as 'nombre jefe' ,(select count(*) from DEPOSITO dep where dep.depo_encargado =e.empl_codigo ) as 'cant dep empleado',
(select count(*) from DEPOSITO dep2 where dep2.depo_encargado = e.empl_jefe) as 'cant depos jefe'
from empleado e 

otra forma: 

--cuenta el total, por cada fila(empleado + jefe), de los depositos que manejan uno o el otro (el count funciona porq contaría solo los que tienen deposito el empleado o el jefe)
select e.empl_jefe,e.empl_codigo,j.empl_nombre,count(*) from empleado e
join deposito dep on e.empl_codigo = dep.depo_encargado or e.empl_jefe = dep.depo_encargado
join empleado j on e.empl_jefe= j.empl_codigo
group by e.empl_jefe,e.empl_codigo,j.empl_nombre


10. Mostrar los 10 productos más vendidos en la historia y también los 10 productos menos
vendidos en la historia. Además mostrar de esos productos, quien fue el cliente que
mayor compra realizo.

select p.prod_codigo,
(select top(1) f.fact_cliente from Factura f join Item_Factura i3 on f.fact_tipo+f.fact_sucursal+f.fact_numero=i3.item_tipo+i3.item_sucursal+i3.item_numero
 where i3.item_producto = p.prod_codigo
 group by f.fact_cliente
 order by sum(i3.item_cantidad)) 
from producto p 
where p.prod_codigo in (select top(10) i.item_producto from Item_Factura i group by i.item_producto order by sum(i.item_cantidad) DESC)
or prod_codigo in (select top(10) i2.item_producto from Item_Factura i2 group by i2.item_producto order by sum(i2.item_cantidad) ASC)

11. Realizar una consulta que retorne el detalle de la familia, la cantidad diferentes de
productos vendidos y el monto de dichas ventas sin impuestos. Los datos se deberán
ordenar de mayor a menor, por la familia que más productos diferentes vendidos tenga,
solo se deberán mostrar las familias que tengan una venta superior a 20000 pesos para
el año 2012.

select f.fami_detalle,count(DISTINCT i.item_producto) as 'cant prod vendidos', sum(i.item_precio*i.item_cantidad) as 'monto total ventas' from familia f 
join producto p on p.prod_familia = f.fami_id 
join Item_Factura i on p.prod_codigo = i.item_producto
where f.fami_detalle in (select f2.fami_detalle from familia f2 
join producto p on p.prod_familia = f2.fami_id 
join Item_Factura i on p.prod_codigo = i.item_producto 
join factura f on f.fact_tipo+f.fact_sucursal+f.fact_numero=i.item_tipo+i.item_sucursal+i.item_numero 
where year(f.fact_fecha) = 2012
group by f2.fami_detalle
having sum(i.item_precio*i.item_cantidad)>20000 )
group by f.fami_detalle
order by 2 DESC

12. Mostrar nombre de producto, cantidad de clientes distintos que lo compraron, importe
promedio pagado por el producto, cantidad de depósitos en los cuales hay stock del
producto y stock actual del producto en todos los depósitos. Se deberán mostrar
aquellos productos que hayan tenido operaciones en el año 2012 y los datos deberán
ordenarse de mayor a menor por monto vendido del producto.

select p.prod_detalle, count(DISTINCT f.fact_cliente) as 'cantidad clientes', AVG(i.item_precio*i.item_cantidad) as 'precio promedio', 
(select count(stoc_deposito) from STOCK where stoc_producto = i.item_producto
group by stoc_producto
having sum(stoc_cantidad) > 0) as 'cantidad depositos con stock'
,(SELECT SUM(stoc_cantidad)
	FROM STOCK
	WHERE stoc_producto = p.prod_codigo
	GROUP BY stoc_producto) as 'stock total'
from producto p 
join Item_Factura i on p.prod_codigo = i.item_producto
join Factura f on f.fact_tipo+f.fact_sucursal+f.fact_numero=i.item_tipo+i.item_sucursal+i.item_numero 
where f.fact_tipo+f.fact_sucursal+f.fact_numero in 
(select f.fact_tipo+f.fact_sucursal+f.fact_numero from Factura f where year(f.fact_fecha) = 2012)
group by p.prod_detalle,i.item_producto,p.prod_codigo
order by sum(i.item_precio*i.item_cantidad) desc


13. Realizar una consulta que retorne para cada producto que posea composición nombre
del producto, precio del producto, precio de la sumatoria de los precios por la cantidad
de los productos que lo componen. Solo se deberán mostrar los productos que estén
compuestos por más de 2 productos y deben ser ordenados de mayor a menor por
cantidad de productos que lo componen.


select p.prod_detalle,p.prod_precio,sum(pc.prod_precio*c.comp_cantidad) from Producto p 
join Composicion c on p.prod_codigo = c.comp_producto
join Producto pc on c.comp_componente = pc.prod_codigo
group by p.prod_detalle,p.prod_precio
having count(c.comp_componente) >= 2
order by count(c.comp_componente) DESC

14. Escriba una consulta que retorne una estadística de ventas por cliente. Los campos que
debe retornar son:
Código del cliente
Cantidad de veces que compro en el último año
Promedio por compra en el último año
Cantidad de productos diferentes que compro en el último año
Monto de la mayor compra que realizo en el último año
Se deberán retornar todos los clientes ordenados por la cantidad de veces que compro en
el último año.
No se deberán visualizar NULLs en ninguna columna

select c.clie_codigo,count(*),avg(f.fact_total)
,count(DISTINCT i.item_numero)
,max(f.fact_total) from cliente c
join Factura f on c.clie_codigo = f.fact_cliente
join Item_Factura i on f.fact_tipo+f.fact_sucursal+f.fact_numero=i.item_tipo+i.item_sucursal+i.item_numero 
WHERE YEAR(fact_fecha) = (SELECT MAX(YEAR(fact_fecha)) FROM Factura)
group by c.clie_codigo
order by 2 desc

15. Escriba una consulta que retorne los pares de productos que hayan sido vendidos
juntos (en la misma factura) ms de 500 veces. El resultado debe mostrar el cdigo
y descripcin de cada uno de los productos y la cantidad de veces que fueron
vendidos juntos. El resultado debe estar ordenado por la cantidad de veces que se
vendieron juntos dichos productos. Los distintos pares no deben retornarse ms de
una vez.
Ejemplo de lo que retornara la consulta:
--------------------------------------------------------------------------------------
|  PROD1     |  DETALLE1            |  PROD2     |  DETALLE2               |  VECES  |
-------------------------------------------------------------------------------------|
|  00001731  |  MARLBORO KS         |  00001718  |  Linterna con pilas     |  507    |
|  00001718  |  Linterna con pilas  |  00001705  |  PHILIPS MORRIS BOX 10  |  562    |
--------------------------------------------------------------------------------------

select p1.prod_codigo,p1.prod_detalle,p2.prod_codigo,p2.prod_detalle,count(*) from Producto p1 
join Item_Factura i1 on i1.item_producto = p1.prod_codigo
join Factura f on f.fact_tipo+f.fact_sucursal+f.fact_numero=i1.item_tipo+i1.item_sucursal+i1.item_numero 
join Item_Factura i2 on f.fact_tipo+f.fact_sucursal+f.fact_numero=i2.item_tipo+i2.item_sucursal+i2.item_numero 
join Producto p2 on p2.prod_codigo = i2.item_producto 
where p2.prod_codigo < p1.prod_codigo and i1.item_tipo+i1.item_sucursal+i1.item_numero = i2.item_tipo+i2.item_sucursal+i2.item_numero 
group by p1.prod_codigo,p1.prod_detalle,p2.prod_codigo,p2.prod_detalle
having count(*) > 500
order by 5 desc

--o:

SELECT  P1.prod_codigo 'Código Producto 1',
		P1.prod_detalle 'Detalle Producto 1',
		P2.prod_codigo 'Código Producto 2',
		P2.prod_detalle 'Detalle Producto 2',
		COUNT(*) 'Cantidad de veces'
FROM Producto P1 JOIN Item_Factura I1 ON P1.prod_codigo = I1.item_producto,
	 Producto P2 JOIN Item_Factura I2 ON P2.prod_codigo = I2.item_producto
WHERE I1.item_tipo + I1.item_sucursal + I1.item_numero = I2.item_tipo + I2.item_sucursal + I2.item_numero
	AND I1.item_producto < I2.item_producto
GROUP BY P1.prod_codigo, P1.prod_detalle, P2.prod_codigo, P2.prod_detalle
HAVING COUNT(*) > 500
ORDER BY 5 DESC


/*16. Con el fin de lanzar una nueva campaña comercial para los clientes que menos compran
en la empresa, se pide una consulta SQL que retorne aquellos clientes cuyas ventas son
inferiores a 1/3 del promedio de ventas del producto que más se vendió en el 2012.
Además mostrar
1. Nombre del Cliente
2. Cantidad de unidades totales vendidas en el 2012 para ese cliente.
3. Código de producto que mayor venta tuvo en el 2012 (en caso de existir más de 1,
mostrar solamente el de menor código) para ese cliente.
*/


select c.clie_codigo, c.clie_razon_social, sum(i.item_cantidad) as 'cantidad vendida para el cliente', 
(select top 1 i3.item_producto from Item_Factura i3 join Factura f3 on f3.fact_tipo+f3.fact_sucursal+f3.fact_numero = i3.item_tipo+i3.item_sucursal+i3.item_numero
where year(f3.fact_fecha) = 2012 and f3.fact_cliente = c.clie_codigo
group by i3.item_producto
order by sum(i3.item_cantidad) DESC,i3.item_producto) as 'producto con mayor venta para el cliente'
from Cliente c 
join Factura f on f.fact_cliente = c.clie_codigo
join Item_Factura i on f.fact_tipo+f.fact_sucursal+f.fact_numero=i.item_tipo+i.item_sucursal+i.item_numero
where year(f.fact_fecha) = 2012
group by c.clie_codigo, c.clie_razon_social
having sum(i.item_cantidad) < 1.00/3 * 
(select top 1 sum(i2.item_cantidad) 
from Item_Factura i2 join Factura f2 on f2.fact_tipo+f2.fact_sucursal+f2.fact_numero = i2.item_tipo+i2.item_sucursal+i2.item_numero
where year(fact_fecha) = 2012
group by item_producto
order by sum(i2.item_cantidad) desc) 

/*17. Escriba una consulta que retorne una estadística de ventas por año y mes para cada
producto.
La consulta debe retornar:
PERIODO: Año y mes de la estadística con el formato YYYYMM
PROD: Código de producto
DETALLE: Detalle del producto
CANTIDAD_VENDIDA= Cantidad vendida del producto en el periodo
VENTAS_AÑO_ANT= Cantidad vendida del producto en el mismo mes del periodo
pero del año anterior
CANT_FACTURAS= Cantidad de facturas en las que se vendió el producto en el
periodo
La consulta no puede mostrar NULL en ninguna de sus columnas y debe estar ordenada
por periodo y código de producto.*/

select p.prod_codigo,p.prod_detalle,str(year(f.fact_fecha))+str(month(f.fact_fecha)),sum(i.item_cantidad),
	isnull((select sum(i2.item_cantidad) from Item_Factura i2 
	join Factura f2 on f2.fact_tipo+f2.fact_sucursal+f2.fact_numero = i2.item_tipo+i2.item_sucursal+i2.item_numero
	where i2.item_producto = p.prod_codigo and year(f2.fact_fecha)-1 = year(f.fact_fecha) and month(f2.fact_fecha) = month(f.fact_fecha)),0),
count(f.fact_tipo+f.fact_sucursal+f.fact_numero) from Producto p join 
Item_Factura i on i.item_producto = p.prod_codigo join 
Factura f on f.fact_tipo+f.fact_sucursal+f.fact_numero=i.item_tipo+i.item_sucursal+i.item_numero 
group by p.prod_codigo,p.prod_detalle,f.fact_fecha
order by p.prod_codigo,3

/*18. Escriba una consulta que retorne una estadística de ventas para todos los rubros.
La consulta debe retornar:
DETALLE_RUBRO: Detalle del rubro
VENTAS: Suma de las ventas en pesos de productos vendidos de dicho rubro
PROD1: Código del producto más vendido de dicho rubro
PROD2: Código del segundo producto más vendido de dicho rubro
CLIENTE: Código del cliente que compro más productos del rubro en los últimos 30
días
La consulta no puede mostrar NULL en ninguna de sus columnas y debe estar ordenada
por cantidad de productos diferentes vendidos del rubro.*/

select r.rubr_detalle,sum(i.item_cantidad*i.item_precio) as 'total vendido',

(select top 1 prod_codigo from Producto 
join Item_Factura  on item_producto = prod_codigo
group by prod_codigo,prod_rubro
having prod_rubro = r.rubr_id
order by sum(i.item_cantidad*i.item_precio) DESC) as 'producto mas vendido de ese rubro',

(select top 1 prod_codigo from Producto 
join Item_Factura  on item_producto = prod_codigo
group by prod_codigo,prod_rubro
having prod_rubro = r.rubr_id and prod_codigo <>
	(select top 1 prod_codigo from Producto 
	join Item_Factura  on item_producto = prod_codigo
	group by prod_codigo,prod_rubro
	having prod_rubro = r.rubr_id
	order by sum(i.item_cantidad*i.item_precio) DESC)
order by sum(i.item_cantidad*i.item_precio) DESC) as '2do producto + vendido',

(select top 1 fact_cliente from Factura 
join Item_Factura  on fact_tipo+fact_sucursal+fact_numero=item_tipo+item_sucursal+item_numero
join Producto p on item_producto = prod_codigo
where prod_rubro = r.rubr_id --and fact_fecha BETWEEN DATEADD(DAY, -30, GETDATE()) AND GETDATE() --(esto tiraría todo en null x la fecha)
group by fact_cliente
order by sum(item_cantidad) DESC)

from Rubro r 
join Producto p on r.rubr_id = p.prod_rubro
join Item_Factura i on i.item_producto = p.prod_codigo
group by r.rubr_detalle,r.rubr_id
order by count(DISTINCT i.item_producto)

/*19. En virtud de una recategorizacion de productos referida a la familia de los mismos se
solicita que desarrolle una consulta sql que retorne para todos los productos:
- Codigo de producto
- Detalle del producto
- Codigo de la familia del producto
- Detalle de la familia actual del producto
- Codigo de la familia sugerido para el producto
- Detalla de la familia sugerido para el producto
La familia sugerida para un producto es la que poseen la mayoria de los productos cuyo
detalle coinciden en los primeros 5 caracteres.
En caso que 2 o mas familias pudieran ser sugeridas se debera seleccionar la de menor
codigo. Solo se deben mostrar los productos para los cuales la familia actual sea
diferente a la sugerida
Los resultados deben ser ordenados por detalle de producto de manera ascendente*/

select p.prod_codigo,p.prod_detalle,f.fami_id,f.fami_detalle,
	(select top 1 prod_familia from Producto
		where LEFT(prod_detalle,5) = LEFT(p.prod_detalle,5) and prod_familia <> p.prod_familia
		group by prod_familia
		order by COUNT(prod_detalle) DESC, prod_familia),
		(select fami_detalle from Familia 
		where fami_id in (select top 1 prod_familia from Producto
		where LEFT(prod_detalle,5) = LEFT(p.prod_detalle,5) and prod_familia <> p.prod_familia
		group by prod_familia
		order by COUNT(prod_detalle) DESC, prod_familia))
		 from Producto p
join Familia f on f.fami_id = p.prod_familia

/*20. Escriba una consulta sql que retorne un ranking de los mejores 3 empleados del 2012
Se debera retornar legajo, nombre y apellido, anio de ingreso, puntaje 2011, puntaje
2012. El puntaje de cada empleado se calculara de la siguiente manera: para los que
hayan vendido al menos 50 facturas el puntaje se calculara como la cantidad de facturas
que superen los 100 pesos que haya vendido en el año, para los que tengan menos de 50
facturas en el año el calculo del puntaje sera el 50% de cantidad de facturas realizadas
por sus subordinados directos en dicho año.*/

select top 3 e.empl_codigo,e.empl_nombre,e.empl_apellido,e.empl_ingreso
,case 
	when (select COUNT(*) from Factura
			where fact_vendedor = e.empl_codigo and YEAR(fact_fecha) = 2011) >= 50
	then (select COUNT(*) from Factura
			where fact_vendedor = e.empl_codigo and YEAR(fact_fecha) = 2011 and fact_total >100)
	else (select COUNT(*)/2 from Factura where fact_vendedor in (select empl_codigo from Empleado where empl_jefe = e.empl_codigo) and YEAR(fact_fecha) = 2011)
	end 'puntaje2011'
 from Empleado e
 order by 5 desc

/* el 2012 es igual pero cambiandole el año */

/*21. Escriba una consulta sql que retorne para todos los años, en los cuales se haya hecho al
menos una factura, la cantidad de clientes a los que se les facturo de manera incorrecta
al menos una factura y que cantidad de facturas se realizaron de manera incorrecta. Se
considera que una factura es incorrecta cuando la diferencia entre el total de la factura
menos el total de impuesto tiene una diferencia mayor a $ 1 respecto a la sumatoria de
los costos de cada uno de los items de dicha factura. Las columnas que se deben mostrar
son:
- Año
- Clientes a los que se les facturo mal en ese año
- Facturas mal realizadas en ese año*/

select YEAR(f.fact_fecha),COUNT(DISTINCT f.fact_cliente),COUNT(DISTINCT f.fact_numero+f.fact_sucursal+f.fact_tipo) from Factura f
where (select fact_total-fact_total_impuestos from Factura where f.fact_numero+f.fact_sucursal+f.fact_tipo = fact_numero+fact_sucursal+fact_tipo)
- (select SUM(i.item_cantidad*i.item_precio) from Item_Factura i where f.fact_tipo+f.fact_sucursal+f.fact_numero=i.item_tipo+i.item_sucursal+i.item_numero)>1
group by year(f.fact_fecha) 

/*22. Escriba una consulta sql que retorne una estadistica de venta para todos los rubros por
trimestre contabilizando todos los años. Se mostraran como maximo 4 filas por rubro (1
por cada trimestre).
Se deben mostrar 4 columnas:
- Detalle del rubro
- Numero de trimestre del año (1 a 4)
- Cantidad de facturas emitidas en el trimestre en las que se haya vendido al
menos un producto del rubro
- Cantidad de productos diferentes del rubro vendidos en el trimestre
El resultado debe ser ordenado alfabeticamente por el detalle del rubro y dentro de cada
rubro primero el trimestre en el que mas facturas se emitieron.
No se deberan mostrar aquellos rubros y trimestres para los cuales las facturas emitiadas
no superen las 100.
En ningun momento se tendran en cuenta los productos compuestos para esta
estadistica.*/

select r.rubr_detalle,DATEPART(QUARTER,f.fact_fecha) as 'trimestre',COUNT(f.fact_tipo+f.fact_sucursal+f.fact_numero) 'cant facturas'
,COUNT(distinct p.prod_codigo) as 'cant productos' from Rubro r join Producto p on p.prod_rubro = r.rubr_id
join Item_Factura i on i.item_producto = p.prod_codigo join Factura f on 
f.fact_tipo+f.fact_sucursal+f.fact_numero=i.item_tipo+i.item_sucursal+i.item_numero
group by r.rubr_detalle,DATEPART(QUARTER,f.fact_fecha)
having COUNT(f.fact_tipo+f.fact_sucursal+f.fact_numero) > 100
order by 1,3

/*23. Realizar una consulta SQL que para cada año muestre :
- Año
- El producto con composición más vendido para ese año.
- Cantidad de productos que componen directamente al producto más vendido
- La cantidad de facturas en las cuales aparece ese producto.
- El código de cliente que más compro ese producto.
- El porcentaje que representa la venta de ese producto respecto al total de venta
del año.
El resultado deberá ser ordenado por el total vendido por año en forma descendente*/

select year(f.fact_fecha) as 'año',
i.item_producto as 'producto mas vendido',
(select COUNT(*) from Composicion where comp_producto = i.item_producto) as 'cantidad de componentes',
COUNT(distinct f.fact_tipo+f.fact_sucursal+f.fact_numero) as 'cant facturas',
(select top 1 fact_cliente from Factura join Item_Factura on fact_tipo+fact_sucursal+fact_numero=item_tipo+item_sucursal+item_numero
where YEAR(fact_fecha) = year(f.fact_fecha) and item_producto = i.item_producto
group by fact_cliente
order by sum(item_cantidad)desc) as 'cliente que mas compro',
(SUM(isnull(i.item_cantidad*i.item_precio,0))/
(select SUM(item_cantidad*item_precio) from Item_Factura join Factura on 
fact_tipo+fact_sucursal+fact_numero=item_tipo+item_sucursal+item_numero
where YEAR(fact_fecha) = YEAR(f.fact_fecha)))*100 as 'porcentaje del total'
from Factura f join Item_Factura i on
f.fact_tipo+f.fact_sucursal+f.fact_numero=i.item_tipo+i.item_sucursal+i.item_numero
where i.item_producto =
    (select top 1 item_producto from Item_Factura join Composicion  on item_producto = comp_producto
	join Factura on fact_tipo+fact_sucursal+fact_numero=item_tipo+item_sucursal+item_numero
	where YEAR(fact_fecha) = year(f.fact_fecha)
	group by item_producto
	order by SUM(item_cantidad) desc)
group by YEAR(f.fact_fecha),i.item_producto
order by SUM(i.item_cantidad*i.item_precio) desc

/* 24. Escriba una consulta que considerando solamente las facturas correspondientes a los
dos vendedores con mayores comisiones, retorne los productos con composición
facturados al menos en cinco facturas,
La consulta debe retornar las siguientes columnas:
- Código de Producto
- Nombre del Producto
- Unidades facturadas
El resultado deberá ser ordenado por las unidades facturadas descendente.
*/

select p.prod_codigo,p.prod_detalle,SUM(i.item_cantidad) as 'cant facturada'
from Producto p
join Item_Factura i on i.item_producto = p.prod_codigo
join Factura f on f.fact_tipo+f.fact_sucursal+f.fact_numero=i.item_tipo+i.item_sucursal+i.item_numero
where f.fact_vendedor in (select top 2 e.empl_codigo from Empleado e order by e.empl_comision desc)
and p.prod_codigo in (select comp_producto from Composicion) 
group by p.prod_codigo,p.prod_detalle
having COUNT(i.item_producto) > 5

/*25. Realizar una consulta SQL que para cada año y familia muestre :
a. Año
b. El código de la familia más vendida en ese año.
c. Cantidad de Rubros que componen esa familia.
d. Cantidad de productos que componen directamente al producto más vendido de
esa familia.
e. La cantidad de facturas en las cuales aparecen productos pertenecientes a esa
familia.
f. El código de cliente que más compro productos de esa familia.
g. El porcentaje que representa la venta de esa familia respecto al total de venta
del año.
El resultado deberá ser ordenado por el total vendido por año y familia en forma
descendente.*/

select  year(f.fact_fecha) as 'año',

		p.prod_familia as 'familia',

		COUNT(distinct p.prod_rubro) as 'cantidad de rubros en ese año',

		(select COUNT(*) from Composicion where 
			comp_producto= (select top 1 prod_codigo from Producto
							join Item_Factura on prod_codigo = item_producto
							join Factura on item_numero+item_sucursal+item_tipo = fact_numero+fact_sucursal+fact_tipo
							where prod_familia=p.prod_familia and YEAR(fact_fecha) = YEAR(f.fact_fecha)
							group by prod_codigo
							order by SUM(item_cantidad*item_precio) desc)) as 'cant componentes',
		
		COUNT(distinct f.fact_tipo+f.fact_sucursal+f.fact_numero) as 'cantidad de facturas',

		(select top 1 fact_cliente from Producto join Item_Factura on prod_codigo=item_producto join Factura on 
			item_numero+item_sucursal+item_tipo = fact_numero+fact_sucursal+fact_tipo
			where prod_familia = p.prod_familia and YEAR(fact_fecha) = year(f.fact_fecha)
			group by fact_cliente
			order by SUM(item_cantidad) desc) as 'cliente que mas compro de esa familia',

		sum(i.item_cantidad*i.item_precio) / (select SUM(item_cantidad * item_precio)
												  from Item_Factura join Factura on item_numero+item_sucursal+item_tipo = fact_numero+fact_sucursal+fact_tipo
												  where YEAR(fact_fecha) = YEAR(f.fact_fecha))*100 as 'porcentaje del total facturado (familia)'

		from Producto p  join Item_Factura i on i.item_producto = p.prod_codigo
		join Factura f on f.fact_tipo+f.fact_sucursal+f.fact_numero=i.item_tipo+i.item_sucursal+i.item_numero

		where p.prod_familia = (select top 1 prod_familia from Producto
								join Item_Factura on prod_codigo = item_producto
								join Factura on item_numero+item_sucursal+item_tipo = fact_numero+fact_sucursal+fact_tipo
								where YEAR(fact_fecha) = YEAR(f.fact_fecha)
								group by prod_familia
								order by SUM(item_cantidad*item_precio) desc)
								
		group by year(f.fact_fecha),p.prod_familia

/*26. Escriba una consulta sql que retorne un ranking de empleados devolviendo las
siguientes columnas:
- Empleado
- Depósitos que tiene a cargo
- Monto total facturado en el año corriente
- Codigo de Cliente al que mas le vendió
- Producto más vendido
- Porcentaje de la venta de ese empleado sobre el total vendido ese año.
Los datos deberan ser ordenados por venta del empleado de mayor a menor.*/

select  e.empl_codigo as 'codigo empleado',

		year(f.fact_fecha) as 'año',

		(select COUNT(*) from DEPOSITO where depo_encargado = e.empl_codigo) as 'cantidad depositos a cargo',

		SUM(fact_total-fact_total_impuestos) as 'total facturado',

		(select top 1 fact_cliente from Factura 
				where YEAR(fact_fecha) = year(f.fact_fecha) and fact_vendedor = e.empl_codigo
				group by fact_cliente
				order by SUM(fact_total-fact_total_impuestos)desc) as 'cliente al q mas le vendio',

		(select top 1 item_producto from Factura join Item_Factura on item_numero + item_sucursal + item_tipo = fact_numero + fact_sucursal + fact_tipo
				where YEAR(fact_fecha) = year(f.fact_fecha) and fact_vendedor = e.empl_codigo
				group by item_producto
				order by SUM(item_cantidad)desc) as 'producto mas vendido',

		(SUM(fact_total-fact_total_impuestos)/
										(select SUM(fact_total-fact_total_impuestos) from Factura
												where YEAR(fact_fecha) = year(f.fact_fecha)
												)) *100 as '% sobre el total'
																							
from Empleado e join Factura f on f.fact_vendedor = e.empl_codigo and YEAR(f.fact_fecha) = 2012 --uno random, pide el actual pero no hay para 2023
group by e.empl_codigo,YEAR(f.fact_fecha)
order by 4 desc

/*27. Escriba una consulta sql que retorne una estadística basada en la facturacion por año y
envase devolviendo las siguientes columnas:
 -Año
 -Codigo de envase
 -Detalle del envase
 -Cantidad de productos que tienen ese envase
 -Cantidad de productos facturados de ese envase
 -Producto mas vendido de ese envase
 -Monto total de venta de ese envase en ese año
 -Porcentaje de la venta de ese envase respecto al total vendido de ese año
Los datos deberan ser ordenados por año y dentro del año por el envase con más
facturación de mayor a menor
*/

select year(f.fact_fecha),e.enva_codigo,e.enva_detalle,
count(distinct i.item_producto) as 'cantidad productos',
sum(i.item_cantidad) as 'cantidad facturada', 
sum(i.item_precio*i.item_cantidad) as 'total facturado',
(select top 1 item_producto from Producto 
join item_factura on prod_codigo = item_producto
join factura on fact_numero+fact_tipo+fact_sucursal = item_numero+item_tipo+item_sucursal  
where prod_envase = e.enva_codigo and year(fact_fecha) = year(f.fact_fecha)
group by item_producto
order by sum(item_cantidad*item_precio) desc) as 'producto mas vendido',
sum(i.item_precio*i.item_cantidad) / 
	(select sum(fact_total) from factura
	where year(fact_fecha) = year(f.fact_fecha))*100 as '% del total'
from Envases e
join Producto p on p.prod_envase = e.enva_codigo
join Item_Factura i on i.item_producto = p.prod_codigo
join factura f on f.fact_numero+f.fact_tipo+f.fact_sucursal = i.item_numero+i.item_tipo+i.item_sucursal
group by e.enva_codigo,e.enva_detalle,year(f.fact_fecha)
order by 1,2

/*28. Escriba una consulta sql que retorne una estadística por Año y Vendedor que retorne las
siguientes columnas:
- Año.
- Codigo de Vendedor
- Detalle del Vendedor
- Cantidad de facturas que realizó en ese año
- Cantidad de clientes a los cuales les vendió en ese año.
- Cantidad de productos facturados con composición en ese año
- Cantidad de productos facturados sin composicion en ese año.
- Monto total vendido por ese vendedor en ese año
Los datos deberan ser ordenados por año y dentro del año por el vendedor que haya
vendido mas productos diferentes de mayor a menor.*/

select year(f.fact_fecha),f.fact_vendedor,e.empl_nombre,e.empl_apellido,
count (distinct f.fact_numero+f.fact_tipo+f.fact_sucursal) as 'cant facturas',
count (distinct f.fact_cliente) as 'cant clientes',
(select count(distinct item_producto) from Item_Factura 
join Factura on fact_numero+fact_tipo+fact_sucursal = item_numero+item_tipo+item_sucursal
where item_producto in (select comp_producto from Composicion)
and year(fact_fecha) = year(f.fact_fecha)
and fact_vendedor = f.fact_vendedor) as 'cant productos con comp',
(select count(distinct item_producto) from Item_Factura 
join Factura on fact_numero+fact_tipo+fact_sucursal = item_numero+item_tipo+item_sucursal
where item_producto not in (select comp_producto from Composicion)
and year(fact_fecha) = year(f.fact_fecha)
and fact_vendedor = f.fact_vendedor) as 'cant productos sin comp',
sum(f.fact_total) as 'total'
from Empleado e
join Factura f on f.fact_vendedor = e.empl_codigo
group by year(f.fact_fecha),f.fact_vendedor,e.empl_nombre,e.empl_apellido
order by 1, (select count(distinct item_producto) from item_factura 
			join factura on fact_numero+fact_tipo+fact_sucursal = item_numero+item_tipo+item_sucursal
			where year(fact_fecha) = year(f.fact_fecha) and fact_vendedor=f.fact_vendedor) desc

/* 29. Se solicita que realice una estadística de venta por producto para el año 2011, solo para
los productos que pertenezcan a las familias que tengan más de 20 productos asignados
a ellas, la cual deberá devolver las siguientes columnas:
a. Código de producto
b. Descripción del producto
c. Cantidad vendida
d. Cantidad de facturas en la que esta ese producto
e. Monto total facturado de ese producto
Solo se deberá mostrar un producto por fila en función a los considerandos establecidos
antes. El resultado deberá ser ordenado por el la cantidad vendida de mayor a menor.*/

select p.prod_codigo,p.prod_detalle,
sum(i.item_cantidad) as 'cantidad vendida',
count(distinct f.fact_numero+f.fact_tipo+f.fact_sucursal) as 'cant facturas',
sum(i.item_cantidad*i.item_precio) as 'total'
from producto p 
join Item_Factura i on p.prod_codigo = i.item_producto
join factura f on f.fact_numero+f.fact_tipo+f.fact_sucursal = i.item_numero+i.item_tipo+i.item_sucursal 
join familia fam on fam.fami_id = p.prod_familia
where year(f.fact_fecha) = 2011 and fam.fami_id in 
(select fami_id from familia
join Producto on fami_id = prod_familia 
group by fami_id
having count(distinct prod_codigo) > 20)
group by p.prod_codigo,p.prod_detalle
order by 5 desc

/*30. Se desea obtener una estadistica de ventas del año 2012, para los empleados que sean
jefes, o sea, que tengan empleados a su cargo, para ello se requiere que realice la
consulta que retorne las siguientes columnas:
- Nombre del Jefe
- Cantidad de empleados a cargo
- Monto total vendido de los empleados a cargo
- Cantidad de facturas realizadas por los empleados a cargo
- Nombre del empleado con mejor ventas de ese jefe
Debido a la perfomance requerida, solo se permite el uso de una subconsulta si fuese
necesario.
Los datos deberan ser ordenados por de mayor a menor por el Total vendido y solo se
deben mostrarse los jefes cuyos subordinados hayan realizado más de 10 facturas.*/

select e.empl_codigo,
count(distinct subE.empl_codigo) as 'cant empleados a cargo',
sum(f.fact_total) as 'total monto',
count(distinct f.fact_numero+f.fact_tipo+f.fact_sucursal) as 'cant facturas',
(select top 1 empl_codigo from empleado
join Factura on fact_vendedor = empl_codigo  
where empl_jefe = e.empl_codigo and year(fact_fecha) = 2012
group by empl_codigo
order by sum(fact_total) desc) as 'el mejor empleado'
from empleado e 
join empleado subE on e.empl_codigo = subE.empl_jefe
join factura f on f.fact_vendedor = subE.empl_codigo
where year(f.fact_fecha) = 2012
group by e.empl_codigo
having count(distinct f.fact_numero+f.fact_tipo+f.fact_sucursal) > 10
order by 2 desc

/*32. Se desea conocer las familias que sus productos se facturaron juntos en las mismas
facturas para ello se solicita que escriba una consulta sql que retorne los pares de
familias que tienen productos que se facturaron juntos. Para ellos deberá devolver las
siguientes columnas:
- Código de familia
- Detalle de familia
- Código de familia
- Detalle de familia
- Cantidad de facturas
- Total vendido
Los datos deberan ser ordenados por Total vendido y solo se deben mostrar las familias
que se vendieron juntas más de 10 veces.*/

select f1.fami_id,f1.fami_detalle,f2.fami_id,f2.fami_detalle,
count(distinct i1.item_numero+i1.item_tipo+i1.item_sucursal) as 'cant facturas',
sum(i1.item_cantidad*i1.item_precio) as 'total'
from familia f1
join Producto p1 on p1.prod_familia = f1.fami_id
join Item_Factura i1 on p1.prod_codigo = i1.item_producto
join Item_factura i2 on i1.item_numero+i1.item_tipo+i1.item_sucursal = i2.item_numero+i2.item_tipo+i2.item_sucursal
join producto p2 on p2.prod_codigo = i2.item_producto
join familia f2 on f2.fami_id = p2.prod_familia
where f2.fami_id<f1.fami_id
group by f1.fami_id,f1.fami_detalle,f2.fami_id,f2.fami_detalle
having count(distinct i1.item_numero+i1.item_tipo+i1.item_sucursal) > 10
order by 6 desc

/* Version del resuelto: */
SELECT FAM1.fami_id AS [FAMI Cod 1]
	,FAM1.fami_detalle AS [FAMI Detalle 1]
	,FAM2.fami_id AS [FAMI Cod 2]
	,FAM2.fami_detalle [FAMI Detalle 2]
	,COUNT(DISTINCT IFACT2.item_numero+IFACT2.item_tipo+IFACT2.item_sucursal) AS [Cantidad de facturas]
	,SUM(IFACT1.item_cantidad*IFACT1.item_precio) + SUM(IFACT2.item_cantidad*IFACT2.item_precio) AS [Total Vendido entre items de ambas familias]
FROM Familia FAM1
	INNER JOIN Producto P1
		ON P1.prod_familia = FAM1.fami_id
	INNER JOIN Item_Factura IFACT1
		ON IFACT1.item_producto = P1.prod_codigo
	,Familia FAM2
	INNER JOIN Producto P2
		ON P2.prod_familia = FAM2.fami_id
	INNER JOIN Item_Factura IFACT2
		ON IFACT2.item_producto = P2.prod_codigo
WHERE FAM1.fami_id < FAM2.fami_id
	AND IFACT1.item_numero+IFACT1.item_tipo+IFACT1.item_sucursal = IFACT2.item_numero+IFACT2.item_tipo+IFACT2.item_sucursal
GROUP BY FAM1.fami_id,FAM1.fami_detalle,FAM2.fami_id,FAM2.fami_detalle
HAVING COUNT(DISTINCT IFACT2.item_numero+IFACT2.item_tipo+IFACT2.item_sucursal) > 10
ORDER BY 6

/*33. Se requiere obtener una estadística de venta de productos que sean componentes. Para
ello se solicita que realiza la siguiente consulta que retorne la venta de los
componentes del producto más vendido del año 2012. Se deberá mostrar:
a. Código de producto
b. Nombre del producto
c. Cantidad de unidades vendidas
d. Cantidad de facturas en la cual se facturo
e. Precio promedio facturado de ese producto.
f. Total facturado para ese producto
El resultado deberá ser ordenado por el total vendido por producto para el año 2012.*/

select p.prod_codigo,p.prod_detalle,
sum(i.item_cantidad) as 'cantidad vendida',
count(distinct f.fact_numero+f.fact_tipo+f.fact_sucursal) as 'cant facturas',
avg(i.item_precio) as 'precio promedio',
sum(i.item_precio*i.item_cantidad) as 'total'
from Composicion c 
join producto p on p.prod_codigo = c.comp_componente
join Item_Factura i on i.item_producto = p.prod_codigo
join factura f on f.fact_numero+f.fact_tipo+f.fact_sucursal = i.item_numero+i.item_tipo+i.item_sucursal 
where c.comp_producto = 
	(select top 1 item_producto from Item_Factura 
	join factura on fact_numero+fact_tipo+fact_sucursal = item_numero+item_tipo+item_sucursal
	where year(fact_fecha) = 2012 and item_producto in (select comp_producto from Composicion)
	group by item_producto
	order by sum(item_precio*item_cantidad) desc)
and year(f.fact_fecha) = 2012
group by p.prod_codigo,p.prod_detalle
order by 6

/* 34. Escriba una consulta sql que retorne para todos los rubros la cantidad de facturas mal
facturadas por cada mes del año 2011 Se considera que una factura es incorrecta cuando
en la misma factura se factutan productos de dos rubros diferentes. Si no hay facturas
mal hechas se debe retornar 0. Las columnas que se deben mostrar son:
1- Codigo de Rubro
2- Mes
3- Cantidad de facturas mal realizadas.*/

select p.prod_rubro,
month(f.fact_fecha) as 'mes',

(select count(*) as 'CantFilas' 
from (select fact_numero+fact_tipo+fact_sucursal from Item_Factura join factura on 
fact_numero+fact_tipo+fact_sucursal = item_numero+item_tipo+item_sucursal
join Producto on prod_codigo = item_producto
where year(fact_fecha)=2011 and month(fact_fecha) = month(f.fact_fecha)
group by fact_numero+fact_tipo+fact_sucursal
having count(distinct prod_rubro) > 1) as 'facturas mal realizadas')
from producto p 
join Item_Factura i on i.item_producto = p.prod_codigo
join factura f on f.fact_numero+f.fact_tipo+f.fact_sucursal = i.item_numero+i.item_tipo+i.item_sucursal
where year(f.fact_fecha) = 2011 
group by p.prod_rubro,month(f.fact_fecha)

*******************************************************************************************************************************

T-SQL:

1. Hacer una función que dado un artículo y un deposito devuelva un string que
indique el estado del depósito según el artículo. Si la cantidad almacenada es
menor al límite retornar “OCUPACION DEL DEPOSITO XX %” siendo XX el
% de ocupación. Si la cantidad almacenada es mayor o igual al límite retornar
“DEPOSITO COMPLETO”.

drop function dbo.ej1

Create function ej1 (@articulo char(8), @deposito char(2))
returns VARCHAR(50)
AS
begin
	declare @cantidad_alm decimal(12,2)
	declare @stock_max decimal (12,2)

	select @cantidad_alm = s.stoc_cantidad,@stock_max = s.stoc_stock_maximo from STOCK s
	where @deposito = s.stoc_deposito and @articulo = s.stoc_producto
	
	declare @retorno varchar(50)

	if @cantidad_alm < @stock_max
		set @retorno = 'ocupacion del deposito: ' + str((@cantidad_alm/@stock_max)*100 )+ '%'
	else
		set @retorno = 'deposito completo'

	return @retorno
end


2. Realizar una función que dado un artículo y una fecha, retorne el stock que
existía a esa fecha


CREATE FUNCTION ej2tsql (@articulo CHAR(8),@fecha smalldatetime)
returns decimal(12,2)
as
begin
	
	return (select sum(s.stoc_cantidad) from STOCK s where s.stoc_producto = @articulo) +
	(select sum(i.item_cantidad) from Item_Factura i join Factura f on 
	f.fact_tipo+f.fact_sucursal+f.fact_numero=i.item_tipo+i.item_sucursal+i.item_numero
	where @articulo = i.item_producto and f.fact_fecha > @fecha)

end

/*3. Cree el/los objetos de base de datos necesarios para corregir la tabla empleado
en caso que sea necesario. Se sabe que debería existir un único gerente general
(debería ser el único empleado sin jefe). Si detecta que hay más de un empleado
sin jefe deberá elegir entre ellos el gerente general, el cual será seleccionado por
mayor salario. Si hay más de uno se seleccionara el de mayor antigüedad en la
empresa. Al finalizar la ejecución del objeto la tabla deberá cumplir con la regla
de un único empleado sin jefe (el gerente general) y deberá retornar la cantidad
de empleados que había sin jefe antes de la ejecución.*/


alter procedure ej3 (@cantEmp int OUTPUT)
as
begin
	declare @gerentegeneral numeric(6,0) 
		= (select top 1 e.empl_codigo from Empleado e
				where e.empl_jefe is null
				order by e.empl_salario desc,e.empl_ingreso asc)
	
	SET @cantEmp = (select COUNT(*) from Empleado e where e.empl_jefe is null)
	
	update Empleado 
	SET empl_jefe = @gerentegeneral
	where empl_jefe is null and empl_codigo <> @gerentegeneral
return
end

/*
INSERT INTO Empleado
VALUES (10,'Pablo','Delucchi','1991-01-01 00:00:00','2000-01-01 00:00:00','Gerente',29000,0,NULL,1)*/

/*
DECLARE @Modiff int
EXEC ej3 @cantEmp = @Modiff OUTPUT
PRINT @Modiff
*/

/*
UPDATE Empleado SET empl_jefe = NULL
WHERE empl_codigo IN (1,10,9)
*/

/*
select * from Empleado
*/

/*4 Cree el/los objetos de base de datos necesarios para actualizar la columna de
empleado empl_comision con la sumatoria del total de lo vendido por ese
empleado a lo largo del último año. Se deberá retornar el código del vendedor
que más vendió (en monto) a lo largo del último año. */

create procedure ej4 (@vendedorQueMasVendio numeric(6,0) OUTPUT)
as
begin 

  update Empleado 
  SET empl_comision 
		= (select SUM(f.fact_total-f.fact_total_impuestos) 
				from Factura f 
					where f.fact_vendedor = empl_codigo and year(f.fact_fecha) = 2012)

	set @vendedorQueMasVendio = (select top 1 empl_codigo from Empleado
									order by empl_comision desc)

end

DECLARE @vendedor_que_mas_vendio numeric(6,0)
EXEC ej4 @vendedorQueMasVendio = @vendedor_que_mas_vendio OUTPUT
SELECT @vendedor_que_mas_vendio AS [Vendedor que mas vendio]


/*5 Realizar un procedimiento que complete con los datos existentes en el modelo
provisto la tabla de hechos denominada Fact_table tiene las siguiente definición:*/

IF OBJECT_ID('Fact_table','U') IS NOT NULL 
DROP TABLE Fact_table
GO

Create table Fact_table
( anio char(4) not null,
mes char(2) not null,
familia char(3) not null,
rubro char(4) not null,
zona char(3) not null,
cliente char(6) not null,
producto char(8) not null,
cantidad decimal(12,2),
monto decimal(12,2)
)
Alter table Fact_table
Add constraint pk_Fact_table_ID primary key(anio,mes,familia,rubro,zona,cliente,producto) 

create procedure ej5 
as
begin
	insert into Fact_table
			select YEAR(f.fact_fecha),
					MONTH(f.fact_fecha),
					p.prod_familia,
					p.prod_rubro,
					d.depa_zona,
					f.fact_cliente,
					p.prod_codigo,
					sum(i.item_cantidad),
					sum(i.item_precio)
				from Item_Factura i 
				JOIN Factura f on f.fact_tipo+f.fact_sucursal+f.fact_numero=i.item_tipo+i.item_sucursal+i.item_numero 
				JOIN Producto p on i.item_producto = p.prod_codigo
				JOIN Empleado e on e.empl_codigo = f.fact_vendedor
				JOIN Departamento d on d.depa_codigo = e.empl_departamento
				group by    YEAR(f.fact_fecha),
							MONTH(f.fact_fecha),
							p.prod_familia,
							p.prod_rubro,
							d.depa_zona,
							f.fact_cliente,
							p.prod_codigo
end
go

/*EXEC ej5

SELECT * 
FROM Fact_table*/

/*7. Hacer un procedimiento que dadas dos fechas complete la tabla Ventas. Debe
insertar una línea por cada artículo con los movimientos de stock generados por
las ventas entre esas fechas. La tabla se encuentra creada y vacía.*/

IF OBJECT_ID('Ventas','U') IS NOT NULL 
DROP TABLE Ventas
GO
Create table Ventas
(
vent_renglon int IDENTITY(1,1) PRIMARY KEY, --Nro de linea de la tabla (PK)
vent_codigo char(8) NULL, --Código del articulo
vent_detalle char(50) NULL, --Detalle del articulo
vent_movimientos int NULL, --Cantidad de movimientos de ventas (Item Factura)
vent_precio_prom decimal(12,2) NULL, --Precio promedio de venta
vent_ganancia decimal(12,2) NOT NULL --Precio de venta - Cantidad * Costo Actual
)

create procedure ej7 (@fecha1 smalldatetime, @fecha2 smalldatetime)
as
begin

	insert into Ventas 
		select  p.prod_codigo,
				p.prod_detalle,
				SUM(i.item_cantidad),
				AVG(i.item_precio),
				SUM(f.fact_total-f.fact_total_impuestos)-SUM(i.item_cantidad*i.item_precio) 
			from Producto p 
			JOIN Item_Factura i on p.prod_codigo = i.item_producto
			JOIN Factura f on f.fact_tipo+f.fact_sucursal+f.fact_numero=i.item_tipo+i.item_sucursal+i.item_numero 
			where f.fact_fecha between @fecha1 and @fecha2
			group by p.prod_codigo,p.prod_detalle
end

EXEC ej7 '2012-01-01','2012-07-01'

select * from Factura
order by fact_fecha desc

select * from ventas

/*8. Realizar un procedimiento que complete la tabla Diferencias de precios, para los
productos facturados que tengan composición y en los cuales el precio de
facturación sea diferente al precio del cálculo de los precios unitarios por
cantidad de sus componentes, se aclara que un producto que compone a otro,
también puede estar compuesto por otros y así sucesivamente, la tabla se debe
crear y está formada por las siguientes columnas:*/

CREATE TABLE Diferencias
(
	dif_codigo char(8) NULL
	,dif_detalle char(50) NULL
	,dif_cantidad decimal(12,2) NULL
	,dif_precio_generado decimal(12,2) NULL
	,dif_precio_facturado decimal(12,2) NULL
)

create function fn_calcular_precio_comp_recursion (@producto_codigo char(8))
returns decimal(12,2)
as
begin

	declare @costo_total decimal(12,2)
	declare @componente char(8)
	declare @cantidad decimal(12,2)

	if not exists (select * from Composicion c where c.comp_producto = @producto_codigo)
	begin
		set @costo_total = (select p.prod_precio from Producto p where p.prod_codigo = @producto_codigo)
		return @costo_total
	end

	set @costo_total = 0

	declare cursorComp cursor for 
	select comp_componente, comp_cantidad
	from Composicion
	where @producto_codigo = comp_producto

	open cursorComp
	fetch next from cursorComp into @componente, @cantidad
		while @@FETCH_STATUS = 0
			begin 
				set @costo_total = @costo_total + (dbo.fn_calcular_precio_comp_recursion (@componente)) * @cantidad
				fetch next from cursorComp into @componente, @cantidad
			end
	close cursorComp
	deallocate cursorComp
	return @costo_total
end

create procedure ej8
as
begin

	insert into Diferencias
		select p.prod_codigo, p.prod_detalle,COUNT(distinct c.comp_componente), dbo.fn_calcular_precio_comp_recursion(p.prod_codigo), i.item_precio  
		from Producto p 
		join Composicion c on p.prod_codigo = c.comp_producto
		join Item_Factura i on i.item_producto = p.prod_codigo
		where i.item_precio <> dbo.fn_calcular_precio_comp_recursion(p.prod_codigo) 
		group by p.prod_codigo,p.prod_detalle,i.item_precio

end

exec ej8

/* 9. Crear el/los objetos de base de datos que ante alguna modificación de un ítem de
factura de un artículo con composición realice el movimiento de sus
correspondientes componentes.*/

create trigger ej9 on item_factura 
for update
as 
begin 

	declare @prod_codigo char(8), @cantidad_i decimal(12,2), @cantidad_d decimal(12,2)
	declare cursorUpdate cursor for 
	select i.item_producto, i.item_cantidad, de.item_cantidad 
	from inserted i join deleted de on i.item_tipo + i.item_numero + i.item_sucursal = de.item_tipo + de.item_numero + de.item_sucursal and i.item_producto = de.item_producto
	where i.item_cantidad <> de.item_cantidad


	open cursorUpdate
	fetch next from cursorUpdate into @prod_codigo, @cantidad_i, @cantidad_d
		while @@FETCH_STATUS = 0
		begin
		if exists (select * from Composicion c where c.comp_producto = @prod_codigo)
			begin 
				update STOCK 
					set stoc_cantidad = stoc_cantidad +  (@cantidad_d - @cantidad_i) * c.comp_cantidad
						from STOCK join Composicion c on c.comp_producto = @prod_codigo 
						and c.comp_componente = stoc_producto
						
					where stoc_deposito in (select top 1 stoc_deposito from STOCK
												where stoc_producto = c.comp_componente and stoc_cantidad > 0
												order by stoc_cantidad desc)	  
			end
			fetch next from cursorUpdate into @prod_codigo, @cantidad_i, @cantidad_d
		end
		close cursorUpdate
		deallocate cursorUpdate
end

/*10. Crear el/los objetos de base de datos que ante el intento de borrar un artículo
verifique que no exista stock y si es así lo borre en caso contrario que emita un
mensaje de error.*/

create trigger ej10 on Producto
for delete
as 
begin

    if (select SUM(s.stoc_cantidad) from deleted d join STOCK s on d.prod_codigo = s.stoc_producto) > 0
	begin
		rollback transaction
		print 'no se puede ejecutar el delete, hay alguno que tiene stock'
	end 

end


/*11. Cree el/los objetos de base de datos necesarios para que dado un código de
empleado se retorne la cantidad de empleados que este tiene a su cargo (directa o
indirectamente). Solo contar aquellos empleados (directos o indirectos) que
tengan un código mayor que su jefe directo.*/

create function ej11 (@empleado_codigo numeric(6,0))
returns int
as
begin
	
	declare @acumEmpleadosACargo int = 0
	declare @subempleado_codigo numeric(6,0)

	if not exists (select * from Empleado where empl_jefe = @empleado_codigo)
		begin
			return @acumEmpleadosACargo
		end	
	
	set @acumEmpleadosACargo = (select COUNT(*) from Empleado where empl_jefe = @empleado_codigo and empl_codigo > @empleado_codigo)

	declare cursorEmp cursor for 
		(select empl_codigo from Empleado
			where empl_jefe = @empleado_codigo)

	open cursorEmp
	fetch next from cursorEmp into @subempleado_codigo
	while @@FETCH_STATUS = 0
		begin
			set @acumEmpleadosACargo = @acumEmpleadosACargo + dbo.ej11(@subempleado_codigo)
			fetch next from cursorEmp into @subempleado_codigo
		end
	close cursorEmp
	deallocate cursorEmp

	return @acumEmpleadosACargo
end

SELECT dbo.ej11(1)

/*12. Cree el/los objetos de base de datos necesarios para que nunca un producto
pueda ser compuesto por sí mismo. Se sabe que en la actualidad dicha regla se
cumple y que la base de datos es accedida por n aplicaciones de diferentes tipos
y tecnologías. No se conoce la cantidad de niveles de composición existentes.*/




create function ej12checkComp (@producto_codigo char(8),@producto_componente char(8))
returns int
as
begin

	declare @comp_componente_aux char(8)

	if exists (select * from Composicion where comp_producto = @producto_componente and comp_componente = @producto_codigo)
	begin
		return 1
	end

	declare cursorComp cursor for 
		select comp_componente from
		Composicion where comp_producto = @producto_componente

	open cursorComp
	fetch next into @comp_componente_aux
	while @@FETCH_STATUS =0
	begin
		if (dbo.ej12checkComp(@producto_codigo,@comp_componente_aux) = 1)
		begin
			return 1
		end
		fetch next into @comp_componente_aux
	end
	close cursorComp
	deallocate cursorComp
	return 0 
end

create trigger ej12 on Composicion for insert
as
begin

	if exists (select comp_producto from inserted where comp_producto = comp_componente)
	begin
		rollback transaction
	end
	
	if exists (select comp_producto from inserted where dbo.ej12checkComp(comp_producto,comp_producto)=1) 
	begin
		rollback transaction
	end

end

/* 13. Cree el/los objetos de base de datos necesarios para implantar la siguiente regla
“Ningún jefe puede tener un salario mayor al 20% de las suma de los salarios de
sus empleados totales (directos + indirectos)”. Se sabe que en la actualidad dicha
regla se cumple y que la base de datos es accedida por n aplicaciones de
diferentes tipos y tecnologías*/

alter function salarioEj13(@empleado numeric(6,0))
returns decimal(12,2)
as
begin
		declare @acumSalario decimal (12,2) = 0 
		declare @subEmpleado numeric(6,0)

		if not exists (select * from Empleado e where e.empl_jefe = @empleado)
		begin 
			set @acumSalario = (select e.empl_salario from Empleado e where e.empl_codigo = @empleado)
			return @acumSalario
		end

		declare cursorEmp cursor for 
		(select e.empl_codigo from Empleado e
			where e.empl_jefe = @empleado)
		open cursorEmp
		fetch next from cursorEmp into @subEmpleado
		while @@FETCH_STATUS = 0
		begin
			set @acumSalario = @acumSalario + dbo.salarioEj13(@subEmpleado)
			fetch next from cursorEmp into @subEmpleado
		end
		close cursorEmp
		deallocate cursorEmp
		return @acumSalario
end 


Create trigger ej13 on Empleado for Insert
as 
begin

	if exists (select * from inserted i where i.empl_salario > dbo.salarioEj13(i.empl_codigo) * 0.2)
	begin
		rollback transaction
	end

end

select dbo.salarioEj13(1)

/*14. Agregar el/los objetos necesarios para que si un cliente compra un producto
compuesto a un precio menor que la suma de los precios de sus componentes
que imprima la fecha, que cliente, que productos y a qué precio se realizó la
compra. No se deberá permitir que dicho precio sea menor a la mitad de la suma
de los componentes.*/



Create function ej14CalcularPrecioComp(@producto char(8))
returns decimal(12,2)
as
begin
	declare @precio decimal(12,2)
	set @precio = (select SUM(p.prod_precio) from Producto p join Composicion c on c.comp_componente = p.prod_codigo
					where c.comp_producto = @producto)
	return @precio
end

Create trigger ej14 on item_factura instead of Insert 
as
begin
	declare @producto char(8)
	declare @precio decimal(12,2)
	declare @numero char(8)
	declare @sucursal char(4)
	declare @tipo char(1)
	declare @fecha smalldatetime
	declare @cliente char(6)
	
	declare cursorCompra cursor for
		(select i.item_producto,i.item_precio,i.item_numero,i.item_sucursal,i.item_tipo from inserted i)
	open cursorCompra
	fetch next from cursorCompra into @producto,@precio,@numero,@sucursal,@tipo
	while @@FETCH_STATUS = 0
	begin
		if exists (select * from Composicion c where c.comp_producto = @producto)
		begin 
			if @precio < dbo.ej14CalcularPrecioComp(@producto) and @precio >= (dbo.ej14CalcularPrecioComp(@producto)/2) 
			begin

				set @cliente= (select fact_cliente from Factura f where f.fact_numero+f.fact_sucursal+f.fact_tipo = @numero+@sucursal+@tipo)
				set @fecha= (select fact_fecha from Factura f where f.fact_numero+f.fact_sucursal+f.fact_tipo = @numero+@sucursal+@tipo) 

				insert into Item_Factura
				select * from inserted where @producto = item_producto

				print @cliente + @fecha + @producto + @precio
			end
			else
			begin
				if(@precio >= dbo.ej14CalcularPrecioComp(@producto))
				begin
					insert into Item_Factura
					select * from inserted where @producto = item_producto
				end
					else
					begin
						print @producto + 'no se pudo insertar porque el precio es menor a la mitad de la suma de sus comp'
					end
			end
				
		end
		else 
			begin
				insert into Item_Factura
				select * from inserted where @producto = item_producto
			end
		fetch next from cursorCompra into @producto,@precio,@numero,@sucursal,@tipo
	end

end

/*15. Cree el/los objetos de base de datos necesarios para que el objeto principal
reciba un producto como parametro y retorne el precio del mismo.
Se debe prever que el precio de los productos compuestos sera la sumatoria de
los componentes del mismo multiplicado por sus respectivas cantidades. No se
conocen los nivles de anidamiento posibles de los productos. Se asegura que
nunca un producto esta compuesto por si mismo a ningun nivel. El objeto
principal debe poder ser utilizado como filtro en el where de una sentencia
select.*/

create function ej15calcularPrecio(@producto char(8))
returns decimal(12,2)
as
begin
	
	declare @acumPrecio decimal(12,2)
	declare @cantidad decimal(12,2)
	declare @componente char(8)

	if not exists(select * from Composicion c where c.comp_producto = @producto)
	begin
		set @acumPrecio = (select p.prod_precio from Producto p where p.prod_codigo = @producto)
		return @acumPrecio
	end

	declare cursorComp cursor for 
		select c.comp_componente,c.comp_cantidad from Composicion c
		where c.comp_producto = @producto
	open cursorComp
	fetch next from cursorComp into @componente,@cantidad
	while @@FETCH_STATUS = 0
	begin
		set @acumPrecio = @acumPrecio + @cantidad * dbo.ej15calcularPrecio(@componente)


		fetch next from cursorComp into @componente,@cantidad
	end
	close cursorComp
	deallocate cursorComp
	return @acumPrecio

end

create function ej15 (@producto char(8))
returns decimal(12,2)
as
begin
	return dbo.ej15calcularPrecio(@producto)
end

/*17. Sabiendo que el punto de reposicion del stock es la menor cantidad de ese objeto
que se debe almacenar en el deposito y que el stock maximo es la maxima
cantidad de ese producto en ese deposito, cree el/los objetos de base de datos
necesarios para que dicha regla de negocio se cumpla automaticamente. No se
conoce la forma de acceso a los datos ni el procedimiento por el cual se
incrementa o descuenta stock*/

create trigger ej17 on Stock for Insert,Update
as
begin
	
	if exists (select * from inserted i where i.stoc_cantidad > i.stoc_stock_maximo 
						or i.stoc_cantidad < i.stoc_punto_reposicion)
				begin 
					rollback transaction
				end

end

/*18. Sabiendo que el limite de credito de un cliente es el monto maximo que se le
puede facturar mensualmente, cree el/los objetos de base de datos necesarios
para que dicha regla de negocio se cumpla automaticamente. No se conoce la
forma de acceso a los datos ni el procedimiento por el cual se emiten las facturas*/

alter trigger ej18 on Factura instead of Insert 
as
begin

	insert into Factura (fact_tipo,fact_sucursal,fact_numero,fact_fecha,fact_vendedor,fact_total,fact_total_impuestos,fact_cliente)
		(select * from inserted i where 
			i.fact_cliente in (select fact_cliente from Factura join Cliente on fact_cliente = clie_codigo 
										group by fact_cliente,clie_limite_credito having
										SUM(fact_total) + i.fact_total < clie_limite_credito ))

end

/*19. Cree el/los objetos de base de datos necesarios para que se cumpla la siguiente
regla de negocio automáticamente “Ningún jefe puede tener menos de 5 años de
antigüedad y tampoco puede tener más del 50% del personal a su cargo
(contando directos e indirectos) a excepción del gerente general”. Se sabe que en
la actualidad la regla se cumple y existe un único gerente general.*/

create function ej19cantEmpl (@empleado numeric(6,0))
returns int
as
begin

	declare @cantEmpl int = 0
	declare @subEmp numeric(6,0) 

	if not exists (select * from Empleado e where e.empl_jefe = @empleado)
	begin
		return @cantEmpl
	end

	set @cantEmpl = 
		(select COUNT(*) from Empleado where empl_jefe = @empleado)

	declare cursorEmp cursor for
		(select empl_codigo from Empleado
			where empl_jefe = @empleado)
	open cursorEmp
	fetch next from cursorEmp into @subEmp
	while @@FETCH_STATUS = 0
	begin
		set @cantEmpl = @cantEmpl + dbo.ej19cantEmpl(@empleado)
	fetch next from cursorEmp into @subEmp
	end
	close cursorEmp
	deallocate cursorEmp

	return @cantEmpl

end

create trigger ej19 on Empleado for Insert
as
begin

	if exists	
		(select * from inserted i where 
			((i.empl_codigo in (select empl_jefe from Empleado e) )AND
			DATEDIFF(YEAR,i.empl_ingreso,GETDATE()) < 5) or 
			(dbo.ej19cantEmpl(i.empl_codigo) > (select COUNT(*)/2 from Empleado))			
		)
		begin
			rollback
		end

end

/*20. Crear el/los objeto/s necesarios para mantener actualizadas las comisiones del
vendedor.
El cálculo de la comisión está dado por el 5% de la venta total efectuada por ese
vendedor en ese mes, más un 3% adicional en caso de que ese vendedor haya
vendido por lo menos 50 productos distintos en el mes.*/

alter procedure ej20
as
begin	

	declare @empleado numeric(6,0)
	declare @comision decimal(12,2)

	declare cursorEmpl cursor for 
		select empl_codigo from Empleado
	open cursorEmpl
	fetch next from cursorEmpl into @empleado
	while @@FETCH_STATUS = 0
	begin
		
		if (select COUNT(DISTINCT i.item_producto) 
			from Factura f
			join Item_Factura i on f.fact_numero+f.fact_sucursal+f.fact_tipo = i.item_numero+i.item_sucursal+i.item_tipo
			where f.fact_vendedor = @empleado and month(f.fact_fecha) = MONTH(GETDATE())
			) >= 50
			begin
				set @comision = (select SUM(f.fact_total) from Factura f where f.fact_vendedor = @empleado and month(f.fact_fecha) = MONTH(GETDATE())) * 0.08
			end
		else
			begin
				set @comision = (select SUM(f.fact_total) from Factura f where f.fact_vendedor = @empleado and month(f.fact_fecha) = MONTH(GETDATE())) * 0.05
			end

		fetch next from cursorEmpl into @empleado
	end
	close cursorEmpl
	deallocate cursorEmpl

end

/*21. Desarrolle el/los elementos de base de datos necesarios para que se cumpla
automaticamente la regla de que en una factura no puede contener productos de
diferentes familias. En caso de que esto ocurra no debe grabarse esa factura y
debe emitirse un error en pantalla.*/

create trigger ej21 on item_factura for insert 
as
begin

	declare @tipo char(1)
	declare @sucursal char(4)
	declare @numero char(8)

	if		exists (select * from inserted i
			JOIN producto p on p.prod_codigo = i.item_producto
			group by i.item_numero+i.item_sucursal+i.item_tipo
			having COUNT(distinct p.prod_familia) > 1)
			begin 
				declare cursorFact cursor for 
					(select i.item_numero+i.item_sucursal+i.item_tipo from inserted i)
				open cursorFact
				fetch next from cursorFact into @tipo,@sucursal,@numero
				while @@FETCH_STATUS = 0
				begin
					if(select COUNT(distinct prod_familia) from inserted
						join Producto on item_producto = prod_codigo
						where item_tipo+item_sucursal+item_numero = @tipo+@sucursal+@numero
						group by item_tipo+item_sucursal+item_numero) >1
					begin
					DELETE FROM Item_Factura where item_tipo+item_sucursal+item_numero = @tipo+@sucursal+@numero
					DELETE FROM Factura where fact_tipo+fact_sucursal+fact_numero = @tipo+@sucursal+@numero
					end   
					fetch next from cursorFact into @tipo,@sucursal,@numero
				end
				rollback 
				close cursorFact
				deallocate cursorFact
				print'no se puede insertar una factura con diferentes familias'
			end
	
end

/*22. Se requiere recategorizar los rubros de productos, de forma tal que nigun rubro
tenga más de 20 productos asignados, si un rubro tiene más de 20 productos
asignados se deberan distribuir en otros rubros que no tengan mas de 20
productos y si no entran se debra crear un nuevo rubro en la misma familia con
la descirpción “RUBRO REASIGNADO”, cree el/los objetos de base de datos
necesarios para que dicha regla de negocio quede implementada.*/

create procedure ej22
as
begin
	
	declare @rubro char(4)
	declare @cantidad_productos int
	declare cursorRubro cursor for 
		(select rubr_id,COUNT(distinct prod_codigo) from Rubro 
		join Producto on prod_rubro = rubr_id 
		group by rubr_id
		having COUNT(distinct prod_codigo) > 20)
	open cursorRubro
	fetch next from cursorRubro into @rubro,@cantidad_productos
	while @@FETCH_STATUS = 0
	begin
			declare @rubroNuevo char(4)
			declare @producto char(8)
			declare @familia char(3)

			declare cursorProd cursor for 
			(select prod_codigo,prod_familia from Producto where prod_rubro = @rubro)
			open cursorProd
			fetch next from cursorProd into @producto,@familia
			while @@FETCH_STATUS = 0 and @cantidad_productos > 20
			begin
				
				if exists (select top 1 prod_rubro from Producto 
						group by prod_rubro
						having COUNT(distinct prod_codigo) < 20 
						order by COUNT(distinct prod_codigo) asc)
					begin 
					set @rubroNuevo = 
						(select top 1 prod_rubro from Producto 
							group by prod_rubro
							having COUNT(distinct prod_codigo) < 20 
							order by COUNT(distinct prod_codigo) asc)
					  
					update Producto set prod_rubro = @rubroNuevo where prod_codigo = @producto
					
					end
				else
					begin
						if not exists (select * from Rubro where rubr_detalle = 'RUBRO REASIGNADO')
						begin
							insert into rubro (rubr_id,rubr_detalle) values ('ej22','RUBRO REASIGNADO')
						end
						update Producto set prod_rubro='ej22'  
					end

				set @cantidad_productos = @cantidad_productos - 1
				fetch next from cursorProd into @producto	
			end
			close cursorProd
			deallocate cursorProd 
		
		fetch next from cursorRubro into @rubro
	end
	close cursorRubro
	deallocate cursorRubro
end

/*23. Desarrolle el/los elementos de base de datos necesarios para que ante una venta
automaticamante se controle que en una misma factura no puedan venderse más
de dos productos con composición. Si esto ocurre debera rechazarse la factura.*/

create trigger ej23 on item_factura for Insert
as
begin
	
	declare @tipo char(1)
	declare @sucursal char(4)
	declare @numero char(8)

	IF EXISTS (
    SELECT 1
    FROM (
        SELECT COUNT(DISTINCT item_producto) AS cant
        FROM inserted
        WHERE item_producto IN (SELECT comp_producto FROM Composicion)
        GROUP BY item_tipo + item_sucursal + item_numero
		) AS subconsulta
		 WHERE cant > 2
	)
	begin
	declare cursorFact cursor for 
		(select i.item_numero,i.item_tipo,i.item_sucursal from inserted i)
	open cursorFact
	fetch next from cursorFact into @numero,@tipo,@sucursal
	while @@FETCH_STATUS = 0
	begin
		if(SELECT COUNT(DISTINCT item_producto)
        FROM inserted
        WHERE item_producto IN (SELECT comp_producto FROM Composicion)
		and item_tipo+item_sucursal+item_numero = @tipo+@sucursal+@numero
        GROUP BY item_tipo + item_sucursal + item_numero)>2
		begin
		DELETE FROM Item_Factura where item_tipo+item_sucursal+item_numero = @tipo+@sucursal+@numero
		DELETE FROM Factura where fact_tipo+fact_sucursal+fact_numero = @tipo+@sucursal+@numero
		end
	fetch next from cursorFact into @numero,@tipo,@sucursal
	end
	
	close cursorFact
	deallocate cursorFact
	rollback
	end
end

/*24. Se requiere recategorizar los encargados asignados a los depositos. Para ello
cree el o los objetos de bases de datos necesarios que lo resueva, teniendo en
cuenta que un deposito no puede tener como encargado un empleado que
pertenezca a un departamento que no sea de la misma zona que el deposito, si
esto ocurre a dicho deposito debera asignársele el empleado con menos
depositos asignados que pertenezca a un departamento de esa zona.*/

IF EXISTS (
    SELECT 1
    FROM (
        SELECT COUNT(DISTINCT item_producto) AS cant
        FROM item_factura
        WHERE item_producto IN (SELECT comp_producto FROM Composicion)
        GROUP BY item_tipo + item_sucursal + item_numero
    ) AS subconsulta
    WHERE cant > 2
)
BEGIN
    -- Al menos un valor retornado es mayor a 2
    PRINT 'Al menos un valor es mayor a 2'
END
else
begin
	print 'ninguno es mayor a 2'
end

create procedure ej24 
as
begin

	declare @deposito char(2)
	declare @zona char(3)

	declare cursorDeposito cursor for 
	(select d.depo_codigo,d.depo_zona from DEPOSITO d 
	join Empleado e on e.empl_codigo = d.depo_encargado
	join Departamento dep on dep.depa_codigo = e.empl_departamento
	where dep.depa_zona <> d.depo_zona)
	open cursorDeposito
	fetch next from cursorDeposito into @deposito,@zona
	while @@FETCH_STATUS = 0
	begin
		declare @nuevoEncargado numeric(6,0)
		set @nuevoEncargado = (select top 1 depo_encargado from DEPOSITO
								join Empleado on depo_encargado = empl_codigo
								join Departamento on depa_codigo = empl_departamento
								where @zona = depa_zona
								group by depo_encargado
								order by COUNT(*))
		update DEPOSITO set depo_encargado = @nuevoEncargado where depo_codigo = @deposito
	
	fetch next from cursorDeposito into @deposito,@zona
	end
	close cursorDeposito
	deallocate cursorDeposito
end

/*25. Desarrolle el/los elementos de base de datos necesarios para que no se permita
que la composición de los productos sea recursiva, o sea, que si el producto A
compone al producto B, dicho producto B no pueda ser compuesto por el
producto A, hoy la regla se cumple.*/

create trigger ej25 on composicion for insert,update
as
begin

	if exists(select * from inserted c1
				join Composicion c2 on c1.comp_producto=c2.comp_componente and c1.comp_componente = c2.comp_producto)
	begin
		rollback
	end

end 

/*26. Desarrolle el/los elementos de base de datos necesarios para que se cumpla
automaticamente la regla de que una factura no puede contener productos que
sean componentes de otros productos. En caso de que esto ocurra no debe
grabarse esa factura y debe emitirse un error en pantalla.*/

create trigger ej26 on item_factura for insert
as
begin
	
	declare @tipo char(1)
	declare @sucursal char(4)
	declare @numero char(8)

	if exists(select * from inserted i 
	where i.item_producto in (select c.comp_componente from Composicion c))
	declare cursorFact cursor for 
		(select i.item_numero,i.item_tipo,i.item_sucursal from inserted i
		where i.item_producto in (select c.comp_componente from Composicion c))
	open cursorFact
	fetch next from cursorFact into @numero,@tipo,@sucursal
	while @@FETCH_STATUS = 0
	begin
		begin
		DELETE FROM Item_Factura where item_tipo+item_sucursal+item_numero = @tipo+@sucursal+@numero
		DELETE FROM Factura where fact_tipo+fact_sucursal+fact_numero = @tipo+@sucursal+@numero
		end
	fetch next from cursorFact into @numero,@tipo,@sucursal
	end
	close cursorFact
	deallocate cursorFact
	rollback
end

/*27. Se requiere reasignar los encargados de stock de los diferentes depósitos. Para
ello se solicita que realice el o los objetos de base de datos necesarios para
asignar a cada uno de los depósitos el encargado que le corresponda,
entendiendo que el encargado que le corresponde es cualquier empleado que no
es jefe y que no es vendedor, o sea, que no está asignado a ningun cliente, se
deberán ir asignando tratando de que un empleado solo tenga un deposito
asignado, en caso de no poder se irán aumentando la cantidad de depósitos
progresivamente para cada empleado.*/

create procedure ej27 
as
begin
	declare @deposito char(2)
	declare cursorDepo cursor for 
	(select depo_codigo from DEPOSITO)
	open cursorDepo
	fetch next from cursorDepo into @deposito
	while @@FETCH_STATUS = 0
	begin
		declare @encargadoNuevo numeric(6,0)
		set @encargadoNuevo = 
		(
		select top 1 depo_encargado from DEPOSITO
		where depo_encargado not in 
		(select empl_jefe from Empleado) 
		and depo_encargado not in 
		(select clie_vendedor from Cliente)
		group by depo_encargado
		order by COUNT(*) asc
		)

		update DEPOSITO set
		depo_encargado = @encargadoNuevo
		where depo_codigo = @deposito

	fetch next from cursorDepo into @deposito
	end
	close cursorDepo
	deallocate cursorDepo
end

/*28. Se requiere reasignar los vendedores a los clientes. Para ello se solicita que 
realice el o los objetos de base de datos necesarios para asignar a cada uno de los
cliente el vendedor que le corresponda, entendiendo que el vendedor que le corresponde
es aquel que le vendió más facturas a ese cliente, si en particular un cliente no tiene
facturas compradas, se le deberá asignar el vendedor con más venta de la empresa, o sea,
el que en monto haya vendido más */

create procedure ej28
as
begin
	declare @cliente char(6)
	declare cursorCliente cursor for 
	(select clie_codigo from Cliente)
	open cursorCliente
	fetch next from cursorCliente into @cliente
	while @@FETCH_STATUS = 0
	begin

		declare @vendedor numeric(6,0)
		if exists (select * from Factura where fact_cliente = @cliente)
		begin
			set @vendedor = 
				(select top 1 fact_vendedor from Factura
				where fact_cliente = @cliente
				group by fact_vendedor
				order by COUNT(*) desc)
			update Cliente set
			clie_vendedor = @vendedor where
			clie_codigo = @cliente
		end
		else
		begin
			set @vendedor =
				(select top 1 fact_vendedor from Factura
				group by fact_vendedor
				order by SUM(fact_total) desc)
			update Cliente set
			clie_vendedor = @vendedor where
			clie_codigo = @cliente
		end
	fetch next from cursorCliente into @cliente
	end
	close cursorCliente
	deallocate cursorCliente

end

/*30. Agregar el/los objetos necesarios para crear una regla por la cual un cliente no
pueda comprar mas de 100 unidades en el mes de ningun producto, si esto ocurre no se deberá
ingresar la operación y se deberá emitir un mensaje 'Se ha superado el limite de compra de un
producto'. Se sabe que esta regla se cumple y que las facturas no pueden ser modificadas. */

create trigger ej30 on item_factura for insert
as
begin
	declare @cliente char(6)
	declare @producto char(8) 
	declare @cantidad decimal(12,2)
	declare @tipo char(1)
	declare @sucursal char(4)
	declare @numero char(8)
	declare cursorItem cursor for 
	(select i.item_producto,f.fact_cliente,i.item_cantidad,i.item_numero,i.item_sucursal,i.item_tipo from inserted i
	join Factura f on i.item_numero+i.item_sucursal+i.item_tipo=f.fact_numero+f.fact_sucursal+f.fact_tipo) 
	open cursorItem
	fetch next from cursorItem into @producto,@cliente,@cantidad,@tipo,@sucursal,@numero
	while @@FETCH_STATUS = 0
	begin
	
		declare @cantUnidades int
		set @cantUnidades = 
		(
		select sum(item_cantidad) from Item_Factura join
		factura on item_numero+item_sucursal+item_tipo=fact_numero+fact_sucursal+fact_tipo
		where fact_cliente = @cliente and item_producto = @producto and
		fact_fecha = month(getdate())
		)
		if @cantUnidades+@cantidad > 100
		begin
		DELETE FROM Item_Factura where item_tipo+item_sucursal+item_numero = @tipo+@sucursal+@numero
		DELETE FROM Factura where fact_tipo+fact_sucursal+fact_numero = @tipo+@sucursal+@numero
		rollback
		end

	fetch next from cursorItem into @producto,@cliente,@cantidad,@tipo,@sucursal,@numero
	end 	
	close cursorItem
	deallocate cursorItem
end

/*31. Desarrolle el o los objetos de base de datos necesarios, para que un jefe no pueda
tener más de 20 empleados a cargo, directa o indirectamente, si esto ocurre
debera asignarsele un jefe que cumpla esa condición, si no existe un jefe para
asignarle se le deberá colocar como jefe al gerente general que es aquel que no
tiene jefe.*/


create function ej31CantEmpleados(@empleado numeric(6,0))
returns int
as
begin
	declare @cantEmpl int = 0
	declare @subEmpl numeric(6,0)

	if not exists(select * from Empleado where empl_jefe = @empleado)
	begin
		return @cantEmpl
	end	
	
	set @cantEmpl = (select count(*) from Empleado where empl_jefe = @empleado)
	declare cursorEmpl cursor for (select empl_codigo from Empleado	where empl_jefe=@empleado)
	open cursorEmpl
	fetch next from cursorEmpl into @subEmpl
	while @@FETCH_STATUS = 0
	begin

	set @cantEmpl = @cantEmpl + dbo.ej31CantEmpleados(@subEmpl)

	fetch next from cursorEmpl into @subEmpl
	end
	close cursorEmpl
	deallocate cursorEmpl
	return @cantEmpl

end

create procedure ej31 
as
begin
	
	declare @jefe numeric(6,0)
	declare @nuevoJefe numeric(6,0)

	declare cursorJefes cursor for 
	(select empl_codigo from Empleado where
	empl_jefe is not null)
	open cursorJefes  
	fetch next from cursorJefes into @jefe
	while @@FETCH_STATUS = 0
	begin
	if dbo.ej31CantEmpleados(@jefe) > 20
	begin

		set @nuevoJefe = (select empl_codigo from Empleado 
							where dbo.ej31CantEmpleados(empl_codigo) < 20 and
							dbo.ej31CantEmpleados(empl_codigo) > 0)
		if @nuevoJefe is not null
		begin
			update empleado set empl_jefe = @nuevoJefe where empl_codigo = @jefe
		end
		else
		begin
			update empleado set empl_jefe = (select empl_codigo from Empleado where empl_jefe is null)
			where empl_codigo = @jefe
		end
	end
	fetch next from cursorJefes into @jefe
	end
	close cursorJefes
	deallocate cursorJefes
end

















































