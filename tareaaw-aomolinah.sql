USE AdventureWorks2019;
GO
/*
•	Cree una vista de las que muestre un listado de los productos descontinuados.
	Los productos (Production.Product) descontinuados son aquellos cuyo valor en 
	DiscontinuedDate es distinto de NULL
*/

--1
CREATE VIEW 
Productos_Lista_Descontinuados
AS
SELECT * FROM Production.Product p
WHERE p.DiscontinuedDate IS NOT NULL
GO


/*
•	Crea una vista que muestre un listado de productos (Production.Product) activos 
	con sus respectivas categorías (Production.ProductCategory), 
	subcategorías (Production.ProductSubcategory) 
	y modelo (Production.ProductModel). 
	Deben mostrarse todos los productos activos, aunque no tengan modelo asociado.
*/
--2
CREATE VIEW VW_Product_List
AS
SELECT p.[Name] 'Producto',
pc.[Name] 'Categoria', 
ps.[Name] 'Subcategoria', 
pm.[Name] 'Modelo'
FROM Production.ProductCategory pc
INNER JOIN Production.ProductSubcategory ps 
ON ps.ProductCategoryID = pc.ProductCategoryID
RIGHT JOIN Production.Product p 
ON p.ProductSubcategoryID = ps.ProductSubcategoryID
LEFT JOIN Production.ProductModel pm
ON pm.ProductModelID = p.ProductModelID
WHERE p.SellEndDate IS NULL;
GO

/*
•	Crea una consulta que obtenga los datos generales 
	de los empleados (HumanResources.Employee) 
	del departamento (HumanResources.Department) ‘Document Control’.
*/
--3
SELECT e.BusinessEntityID 'ID',
CONCAT(p.FirstName,' ',p.MiddleName, ' ', 
P.LastName)
AS 'Empleado', 
e.[JobTitle] AS 'Titulo', 
e.[BirthDate] AS 'Fecha Cumpleaños', 
d.[Name] AS 'Departamento'
FROM Person.Person p
INNER JOIN Person.BusinessEntity b
ON p.BusinessEntityID = 
b.BusinessEntityID
INNER JOIN
HumanResources.Employee e
ON b.BusinessEntityID = e.BusinessEntityID
INNER JOIN 
HumanResources.EmployeeDepartmentHistory h
ON h.BusinessEntityID = e.BusinessEntityID
LEFT JOIN HumanResources.Department d 
ON d.DepartmentID = h.DepartmentID
WHERE d.[Name] = 'Document Control';


/*
•	Crea un procedimiento almacenado 
	que obtenga los datos generales 
	de los empleados por departamento
*/
-4
IF EXISTS
(SELECT * FROM INFORMATION_SCHEMA.ROUTINES 
   WHERE SPECIFIC_SCHEMA = N'dbo'
     AND SPECIFIC_NAME = N'SP_EmpleadoPorDepartamento' )
DROP PROCEDURE SP_EmpleadoPorDepartamento;
GO

CREATE PROCEDURE 
SP_EmpleadoPorDepartamento
@Departamento VARCHAR(50)
AS
BEGIN
IF EXISTS(SELECT 1 FROM HumanResources.Department d
WHERE d.[Name] = @Departamento)
BEGIN
SELECT e.BusinessEntityID 'ID',
CONCAT(p.FirstName,' ',p.MiddleName, ' ', 
P.LastName)
AS 'Empleado', 
e.[JobTitle] AS 'Titulo', 
d.[Name] AS 'Departamento'
FROM Person.Person p
INNER JOIN Person.BusinessEntity b
ON p.BusinessEntityID = 
b.BusinessEntityID
INNER JOIN
HumanResources.Employee e
ON b.BusinessEntityID = e.BusinessEntityID
INNER JOIN 
HumanResources.EmployeeDepartmentHistory h
ON h.BusinessEntityID = e.BusinessEntityID
INNER JOIN HumanResources.Department d 
ON d.DepartmentID = h.DepartmentID
WHERE d.[Name] = @Departamento;
END
ELSE
BEGIN
PRINT 'Este departamento no es valido'
END
END;


EXEC SP_EmpleadoPorDepartamento 
'Markng';

EXEC SP_EmpleadoPorDepartamento 
'Sales';

/*
•	Crea un procedimiento que obtenga lista de cumpleañeros del mes 
	ordenados alfabéticamente por el primer apellido y 
	por el nombre del departamento, si no se especifica DepartmentID 
	entonces deberá retornar todos los datos.

*/
--5
IF EXISTS
(SELECT * FROM INFORMATION_SCHEMA.ROUTINES 
   WHERE SPECIFIC_SCHEMA = N'dbo'
     AND SPECIFIC_NAME = N'SP_Cumpleañeros' )
DROP PROCEDURE SP_Cumpleañeros;
GO

ALTER PROCEDURE SP_Cumpleañeros
@Mes VARCHAR(20), 
@DepartamentoID SMALLINT = NULL
AS
BEGIN
IF(@DepartamentoID IS NULL)
BEGIN
SELECT p.FirstName 'Nombre', p.LastName 'Apellido',e.[JobTitle] AS 'Titulo',
DATENAME(MONTH, e.[BirthDate]) AS 'Cumpleaños',d.[Name] AS 'Departamento'
FROM Person.Person p INNER JOIN Person.BusinessEntity b ON p.BusinessEntityID = 
b.BusinessEntityID INNER JOIN HumanResources.Employee e 
ON b.BusinessEntityID = e.BusinessEntityID INNER JOIN 
HumanResources.EmployeeDepartmentHistory h ON h.BusinessEntityID = e.BusinessEntityID
INNER JOIN HumanResources.Department d ON d.DepartmentID = h.DepartmentID
WHERE DATENAME(MONTH, e.[BirthDate]) = @Mes
ORDER BY p.LastName, d.[Name]

END

ELSE
BEGIN
SELECT p.FirstName 'Nombre', p.LastName 'Apellido',e.[JobTitle] AS 'Titulo',
DATENAME(MONTH, e.[BirthDate]) AS 'Cumpleaños',d.[Name] AS 'Departamento'
FROM Person.Person p INNER JOIN Person.BusinessEntity b ON p.BusinessEntityID = 
b.BusinessEntityID INNER JOIN HumanResources.Employee e 
ON b.BusinessEntityID = e.BusinessEntityID INNER JOIN 
HumanResources.EmployeeDepartmentHistory h ON h.BusinessEntityID = e.BusinessEntityID
INNER JOIN HumanResources.Department d ON d.DepartmentID = h.DepartmentID
WHERE DATENAME(MONTH, e.[BirthDate]) = @Mes AND d.DepartmentID = @DepartamentoID
ORDER BY p.LastName, d.[Name]
END
END

EXEC SP_Cumpleañeros 
'Enero', 3;

EXEC SP_Cumpleañeros 
'Enero';
/*
•	Crea un procedimiento que obtenga la cantidad de empleados 
	por departamento ordenados por nombre de departamento, si no se especifica 
	DepartmentID entonces deberá retornar todos los datos.

*/
--6
CREATE PROCEDURE SP_ContarEmpleados
@DepartamentoNombre VARCHAR(50) = NULL
AS
BEGIN 
IF (@DepartamentoNombre IS NULL)
BEGIN

SELECT 
d.[Name] 'Departamento',
COUNT(*) 'Numero empleados'
FROM HumanResources.Employee
e INNER JOIN 
[HumanResources].[EmployeeDepartmentHistory]
h 
ON e.[BusinessEntityID] 
= h.[BusinessEntityID]
INNER JOIN 
[HumanResources].[Department]
d ON d.[DepartmentID] 
= h.[DepartmentID]
GROUP BY d.[Name]
ORDER BY d.[Name]

END

ELSE
BEGIN
SELECT 
d.[Name] 'Departamento',
COUNT(*) 'Numero empleados'
FROM HumanResources.Employee
e INNER JOIN 
[HumanResources].[EmployeeDepartmentHistory]
h 
ON e.[BusinessEntityID] 
= h.[BusinessEntityID]
INNER JOIN 
[HumanResources].[Department]
d ON d.[DepartmentID] 
= h.[DepartmentID]
WHERE d.[Name] = @DepartamentoNombre
GROUP BY d.[Name]
ORDER BY d.[Name]
END
END;

EXEC SP_ContarEmpleados;

EXEC SP_ContarEmpleados 'Sales';

/*
•	Cree un procedimiento que obtenga retorne el Id del producto,
	nombre del producto, cantidad total de ventas (Sales.SalesOrderDetail), 
	monto total de ventas en un rango de fechas (Sales.SalesOrderHeader). 
	El procedimiento debe tener los parámetros @StartDate, @EndDate y 2 parámetros de retorno, los parámetros pueden ser nulos, si no especifican las fechas deberá retornar los datos correspondientes al mes actual. El procedimiento debe validar que el rango de fechas sea válido, 
	si el rango es inválido deberá indicarse en los parámetros de retorno.

*/

--7
CREATE PROCEDURE 
SP_Ventas 
@StartDate DATETIME,
@EndDate DATETIME
AS
BEGIN 
SET DATEFORMAT 'YMD';
SELECT 
p.[ProductID], 
p.[Name],
[OrderDate], 
SUM([SubTotal]) 
'Monto'
FROM Production.Product
p 
INNER JOIN 
[Sales].[SalesOrderDetail]
d
ON 
p.[ProductID]
= d.[ProductID]
INNER JOIN 
[Sales].[SalesOrderHeader]
o 
ON d.[SalesOrderID]
= o.[SalesOrderID]
WHERE [OrderDate] BETWEEN @StartDate AND @EndDate
GROUP BY p.[ProductID], p.[Name], [OrderDate]
END;
GO

EXEC SP_Ventas '2011-05-31','2011-06-12'