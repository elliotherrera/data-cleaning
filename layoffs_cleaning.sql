-- Limpieza de Datos

SELECT *
FROM layoffs;

/* Pasos a seguir:

 0. Copiar base de datos
 1. Eliminar duplicados
 2. Estandarizar los datos
 3. Tratar valores Null o en blanco
 4. Eliminar columnas innecesarias */



-- 0. Generamos una copia de la tabla para trabajar en ella, "nombre_stagging"

CREATE TABLE layoffs_stagging
LIKE layoffs;

INSERT layoffs_stagging
SELECT *
FROM layoffs;

SELECT *
FROM layoffs_stagging;


-- 1. Eliminar registros duplicados

-- 1.1 Aplicamos este PATRON DE BUSQUEDA con window function combinando ROW_NUMBER() ROW( PARTITION BY col1, col2, col3, ...)

SELECT *,
ROW_NUMBER() OVER (
PARTITION BY company, industry, total_laid_off, percentage_laid_off, `date`) AS row_num
FROM layoffs_stagging;



-- 1.2 Generamos una CTE para mayor legibilidad

WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER (
PARTITION BY company, industry, total_laid_off, percentage_laid_off, `date`) AS row_num
FROM layoffs_stagging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;


-- 1.3 Comprobar duplicados, en este caso los registros son muy parecidos en varias columnas pero difieren en un dato (no duplicado).

SELECT *
FROM layoffs_stagging
WHERE company = 'Oda';


-- Rehacemos la particion del paso 1.2 incluyendo mas columnas y actualizamos el CTE

WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER (
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_stagging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- Rehacemos el paso 1.3

SELECT *
FROM layoffs_stagging
WHERE company = 'Yahoo';


-- 1.4 ❌ Eliminar duplicados ERROR: (The target table duplicate_cte of the DELETE is not updatable)

WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER (
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_stagging
)
DELETE 
FROM duplicate_cte
WHERE row_num > 1;

-- 1.4.1 Creamos una Tabla adicional que contenga esa columna y eliminar la fila que contenga ese "> 1" 


CREATE TABLE `layoffs_stagging2` (
  `company` varchar(50) DEFAULT NULL,
  `location` varchar(50) DEFAULT NULL,
  `industry` varchar(50) DEFAULT NULL,
  `total_laid_off` varchar(50) DEFAULT NULL,
  `percentage_laid_off` varchar(50) DEFAULT NULL,
  `date` varchar(50) DEFAULT NULL,
  `stage` varchar(50) DEFAULT NULL,
  `country` varchar(50) DEFAULT NULL,
  `funds_raised_millions` varchar(50) DEFAULT NULL,
  `row_num` INT 
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


-- 1.4.2 Comprobamos que se ha creado la estructura de la tabla

SELECT *
FROM layoffs_stagging2;


-- 1.4.3 Insertamos los datos del CTE para completar nuestra tabla modificable.

INSERT INTO layoffs_stagging2
SELECT *,
ROW_NUMBER() OVER (
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_stagging


-- 1.4.4 Ahora verificamos que nuestra nueva tabla tenga el contenido inicial + la columna "row_num" en este momento ya contamos con una tabla modificable para eliminar los duplicados

SELECT *
FROM layoffs_stagging2;

-- 1.4.5 Filtramos, una ultiima revision

SELECT *
FROM layoffs_stagging2
WHERE row_num > 1;

-- 1.4.6 Eliminamos duplicados

DELETE 
FROM layoffs_stagging2
WHERE row_num > 1;

-- 1.4.7 Comprobamos eliminacion

SELECT *
FROM layoffs_stagging2
WHERE row_num > 1;

SELECT *
FROM layoffs_stagging2;
