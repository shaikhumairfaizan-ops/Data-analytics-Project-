create database PCOS_Project;
use PCOS_Project;

create table probes (
id_ref varchar (70) primary key,
identifier varchar (100),
gene_symbole varchar (55),
gene_tile varchar (255),
gene_id varchar (70),
chromosome_location varchar (70),
go_function TEXT,
go_process TEXT,
go_component TEXT
);

create table samples( 
sample_id varchar (50) primary key,
group_status varchar (30)
);

create table Expression(
id_ref varchar (50),
sample_id varchar(50),
expression_value FLOAT,
Foreign key (id_ref) references Probes (id_ref ),
Foreign key (sample_id) references samples (sample_id)
);

use PCOS_Project;
INSERT INTO samples VALUES 
('GSM1684095','Control'),
('GSM1684096','PCOS'),
('GSM1684097','Control'),
('GSM1684098','PCOS'),
('GSM1684099','Control'),
('GSM1684100','PCOS'),
('GSM1684101','Control'),
('GSM1684102','PCOS'),
('GSM1684103','Control'),
('GSM1684104','PCOS');

select count(*) FROM probes;
select count(*) FROM expression;

USE PCOS_Project;
SET FOREIGN_KEY_CHECKS=0;
TRUNCATE TABLE Expression;

SET FOREIGN_KEY_CHECKS=1;

USE PCOS_Project;
SET FOREIGN_KEY_CHECKS=0;
TRUNCATE TABLE Expression;


SELECT COUNT(*) FROM Expression;
SELECT COUNT(*) FROM Probes;
SELECT COUNT(*) FROM Samples;


-- Top 10 genes with the highest average expression overall

SELECT gene_symbole, AVG(expression_value) AS avg_expr
FROM Expression e
JOIN Probes p ON e.id_ref = p.id_ref
GROUP BY gene_symbole
ORDER BY avg_expr DESC
LIMIT 10;


-- 2. Genes with the biggest expression difference between PCOS and Control

SELECT gene_symbole,
       AVG(CASE WHEN s.group_status = 'PCOS' THEN e.expression_value END) AS avg_pcos,
       AVG(CASE WHEN s.group_status = 'Control' THEN e.expression_value END) AS avg_control,
       AVG(CASE WHEN s.group_status = 'PCOS' THEN e.expression_value END) -
       AVG(CASE WHEN s.group_status = 'Control' THEN e.expression_value END) AS fold_diff
FROM Expression e
JOIN Samples s ON e.sample_id = s.sample_id
JOIN Probes p ON e.id_ref = p.id_ref
GROUP BY gene_symbole
ORDER BY ABS(fold_diff) DESC
LIMIT 20;

-- 3. Rank genes within each chromosome by average expression (window function)

SELECT p.chromosome_location, gene_symbole, AVG(e.expression_value) AS avg_expr,
       RANK() OVER (PARTITION BY p.chromosome_location ORDER BY AVG(e.expression_value) DESC) AS rnk
FROM Expression e
JOIN Probes p ON e.id_ref = p.id_ref
GROUP BY p.chromosome_location, gene_symbole;

-- 4. Genes linked to insulin/metabolic processes and their expression by group

SELECT gene_symbole, s.group_status, AVG(e.expression_value) AS avg_expr
FROM Expression e
JOIN Probes p ON e.id_ref = p.id_ref
JOIN Samples s ON e.sample_id = s.sample_id
WHERE p.go_process LIKE '%insulin%' OR p.go_process LIKE '%glucose%'
GROUP BY gene_symbole, s.group_status
ORDER BY gene_symbole, s.group_status;

-- 5. CTE to find high-variance genes across the 10 samples (candidate DE genes)

WITH gene_variance AS (
    SELECT id_ref, 
           AVG(expression_value) AS mean_expr,
           VAR_SAMP(expression_value) AS variance_expr
    FROM Expression
    GROUP BY id_ref
)
SELECT gene_symbole, gv.mean_expr, gv.variance_expr
FROM gene_variance gv
JOIN Probes p ON gv.id_ref = p.id_ref
ORDER BY gv.variance_expr DESC
LIMIT 25;

-- 6. Count of "Unknown" (unannotated) probes per chromosome

SELECT chromosome_location, COUNT(*) AS unknown_count
FROM Probes
WHERE gene_symbole = 'Unknown'
GROUP BY chromosome_location
ORDER BY unknown_count DESC;


USE PCOS_Project;
SELECT 'Probes' as TableName, COUNT(*) as TotalRows FROM Probes
UNION ALL
SELECT 'Samples', COUNT(*) FROM Samples
UNION ALL
SELECT 'Expression', COUNT(*) FROM Expression;