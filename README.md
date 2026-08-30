# Limpieza de Datos en MySQL — World Layoffs Dataset

## Descripción

Este proyecto toma como base un dataset crudo llamado World Layoffs, que recopila los despidos masivos ocurridos entre 2020 y 2023 a raíz del impacto de la pandemia global de COVID-19 en distintas empresas alrededor del mundo. A partir de estos datos sin procesar, se aplicó un proceso de limpieza utilizando exclusivamente scripts SQL, dejando el dataset listo para su posterior análisis exploratorio (EDA).

## Fuente de datos

Link al dataset original (https://www.kaggle.com/datasets/previnpillay/world-layoffs-2020-2023).
Aclarar que es un dataset real de despidos masivos por empresa (2020 - 2023).

## Herramientas usadas

MySQL / DBeaver.
Mencionar que el script es SQL puro, sin herramientas externas.

## Metodología

Se genera una copia de la tabla original con la extensión "\_staging" para luego aplicar los siguientes 4 pasos de limpieza:

1. Eliminación de duplicados
1. Estandarización
1. Tratamiento de null/blancos
1. Eliminación de filas/columnas sin valor

## Decisiones técnicas destacadas

En la eliminación de duplicados, debido a una limitación del motor MySQL que no permite hacer un DELETE directamente sobre un CTE, se trabajó con una copia adicional de la tabla, generando una tabla "\_staging2" en la que se añadió un campo adicional (row_num) para poder identificar y seleccionar los duplicados. Posteriormente, este campo fue eliminado una vez cumplida su función.

Por otro lado, se eliminaron filas que no aportaban información útil, debido a que campos importantes como "total_laid_off" y "percentage_laid_off" estaban en blanco o en null de forma conjunta.
