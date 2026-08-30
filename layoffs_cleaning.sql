-- PROYECTO: Limpieza de Datos - World Layoffs Dataset

-- 0. COPIA DE TRABAJO
-- Se crea una tabla "layoffs_staging" con la misma estructura y se copian los datos.

SELECT *
FROM layoffs;

CREATE TABLE layoffs_staging
LIKE layoffs;

INSERT layoffs_staging
SELECT *
FROM layoffs;

SELECT *
FROM layoffs_staging;


-- 1. ELIMINAR REGISTROS DUPLICADOS

-- Se usa ROW_NUMBER() particionando por todas las columnas: si una
-- combinación de valores se repite, la segunda aparición (row_num > 1)
-- es un duplicado.

-- 1.1 Primer intento, con pocas columnas
SELECT *,
    ROW_NUMBER() OVER (
        PARTITION BY company, industry, total_laid_off, percentage_laid_off, `date`
    ) AS row_num
FROM layoffs_staging;

-- 1.2 CTE para filtrar los duplicados
WITH duplicate_cte AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY company, industry, total_laid_off, percentage_laid_off, `date`
        ) AS row_num
    FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- 1.3 Verificación: no son duplicados reales, solo parecidos
SELECT *
FROM layoffs_staging
WHERE company = 'Oda';

-- 1.4 Se rehace el CTE particionando por todas las columnas relevantes
WITH duplicate_cte AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY company, location, industry, total_laid_off,
                         percentage_laid_off, `date`, stage, country,
                         funds_raised_millions
        ) AS row_num
    FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- 1.5 Verificación con un duplicado real
SELECT *
FROM layoffs_staging
WHERE company = 'Yahoo';

-- 1.6 MySQL no permite DELETE directo sobre un CTE
-- ❌ ERROR: "The target table duplicate_cte of the DELETE is not updatable"
--
-- WITH duplicate_cte AS (...)
-- DELETE FROM duplicate_cte WHERE row_num > 1;

-- 1.7 Solución: tabla física con columna row_num para poder eliminar
CREATE TABLE `layoffs_staging2` (
    `company` varchar(50) DEFAULT NULL,
    `location` varchar(50) DEFAULT NULL,
    `industry` varchar(50) DEFAULT NULL,
    `total_laid_off` varchar(50) DEFAULT NULL,
    `percentage_laid_off` varchar(50) DEFAULT NULL,
    `date` varchar(50) DEFAULT NULL,
    `stage` varchar(50) DEFAULT NULL,
    `country` varchar(50) DEFAULT NULL,
    `funds_raised_millions` varchar(50) DEFAULT NULL,
    `row_num` INT -- columna agregada
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci; -- Generado mediante copia de tabla

SELECT *
FROM layoffs_staging2;

INSERT INTO layoffs_staging2
SELECT *,
    ROW_NUMBER() OVER (
        PARTITION BY company, location, industry, total_laid_off,
                     percentage_laid_off, `date`, stage, country,
                     funds_raised_millions
    ) AS row_num
FROM layoffs_staging;

SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

DELETE
FROM layoffs_staging2
WHERE row_num > 1;

SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

SELECT *
FROM layoffs_staging2;


-- ---------------------------------------------------------------------
-- 2. ESTANDARIZACIÓN DE DATOS
-- ---------------------------------------------------------------------

-- 2.1 Espacios en blanco sobrantes en "company"
SELECT company, TRIM(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);

-- 2.2 Unificar categorías de "industry" (ej: Crypto, Crypto Currency)
SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;

SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;

-- 2.3 Unificar formato de "country" (ej: "United States." con punto extra)
SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;

SELECT *
FROM layoffs_staging2
WHERE country LIKE 'United States%'
ORDER BY 1;

-- TRIM normal no quita el punto final; se usa TRIM(TRAILING ...)
SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;

-- 2.4 Convertir "date" de texto a tipo DATE
-- Primero se homogeneizan los 'NULL' (texto) a NULL real
SELECT `date`
FROM layoffs_staging2
WHERE `date` = 'NULL';

UPDATE layoffs_staging2
SET `date` = NULL
WHERE `date` = 'NULL';

-- STR_TO_DATE convierte el texto (mes/día/año) a fecha real
SELECT `date`,
    STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

SELECT `date`
FROM layoffs_staging2;

-- Recién ahora se puede cambiar el tipo de dato de la columna
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

SELECT *
FROM layoffs_staging2;


-- ---------------------------------------------------------------------
-- 3. VALORES NULL Y EN BLANCO
-- ---------------------------------------------------------------------

-- 3.1 La importación trajo todo como texto: se corrige el string
-- 'NULL' a NULL real en las columnas relevantes
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL;

UPDATE layoffs_staging2
SET total_laid_off = NULL
WHERE total_laid_off = 'NULL';

UPDATE layoffs_staging2
SET percentage_laid_off = NULL
WHERE percentage_laid_off = 'NULL';

UPDATE layoffs_staging2
SET funds_raised_millions = NULL
WHERE funds_raised_millions = 'NULL';

UPDATE layoffs_staging2
SET stage = NULL
WHERE stage = 'NULL';

UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = 'NULL';

-- 3.2 Filas con NULL en ambas columnas clave (se eliminarán en el paso 4)
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;

-- 3.3 Rellenar "industry" buscando otra fila de la misma empresa
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL OR industry = '';

-- Ejemplo: Airbnb tiene una fila sin industry y otra con "Travel"
SELECT *
FROM layoffs_staging2
WHERE company = 'Airbnb';

-- Self-join por "company" para cruzar filas sin industry con filas que sí la tienen
SELECT t1.industry, t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
    ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry = '')
  AND t2.industry IS NOT NULL;

-- Se convierten los blancos ('') a NULL para que el UPDATE con JOIN funcione
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
    ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
  AND t2.industry IS NOT NULL;

-- Verificación: solo queda sin rellenar la empresa sin otra fila (Bally's)
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL OR industry = '';

SELECT *
FROM layoffs_staging2
WHERE company LIKE 'Bally%';


-- ---------------------------------------------------------------------
-- 4. ELIMINAR COLUMNAS Y FILAS INNECESARIAS
-- ---------------------------------------------------------------------

-- 4.1 Filas sin total_laid_off ni percentage_laid_off: no aportan
-- información confiable para el análisis
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;

DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;

SELECT *
FROM layoffs_staging2;

-- 4.2 row_num ya cumplió su función, se elimina
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

-- FIN: layoffs_staging2 queda lista para el análisis exploratorio (EDA)