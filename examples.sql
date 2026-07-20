
-- QUERY 1: Identifying organisms that may exhibit competence for transformation
SELECT 
    o.species_name AS Organism,
    COUNT(DISTINCT p.protein_id) AS Competence_Protein_Count,
    GROUP_CONCAT(DISTINCT g.go_id ORDER BY g.go_id) AS Competence_GO_Terms,
    CASE 
        WHEN COUNT(DISTINCT p.protein_id) > 0 THEN 'Yes'
        ELSE 'No'
    END AS May_Exhibit_Competence
FROM Organism o
LEFT JOIN Protein p ON o.organism_id = p.organism_id
LEFT JOIN Annotation a ON p.protein_id = a.protein_id
LEFT JOIN CompetenceTerm ct ON a.go_id = ct.go_id
LEFT JOIN GoTerm g ON ct.go_id = g.go_id
WHERE ct.go_id IS NOT NULL
GROUP BY o.species_name
ORDER BY Competence_Protein_Count DESC;

-- QUERY 2: Finding all proteins with DNA binding function (GO:0003677)
-- This query shows which organisms have DNA binding proteins and their counts
SELECT 
    o.species_name AS Organism,
    COUNT(DISTINCT p.protein_id) AS DNA_Binding_Protein_Count
FROM Protein p
JOIN Organism o ON p.organism_id = o.organism_id
JOIN Annotation a ON p.protein_id = a.protein_id
JOIN GoTerm g ON a.go_id = g.go_id
WHERE g.go_id = 'GO:0003677'  -- DNA binding
GROUP BY o.species_name
ORDER BY DNA_Binding_Protein_Count DESC;



-- QUERY 3: Detailed competence analysis showing specific proteins and GO terms
-- This query provides detailed information about competence-associated proteins
SELECT 
    o.species_name AS Organism,
    p.uniprot_id AS Protein_ID,
    p.symbol AS Protein_Symbol,
    g.go_id AS GO_ID,
    a.evidence_code AS Evidence,
    ct.is_direct AS Direct_Term
FROM Organism o
JOIN Protein p ON o.organism_id = p.organism_id
JOIN Annotation a ON p.protein_id = a.protein_id
JOIN CompetenceTerm ct ON a.go_id = ct.go_id
JOIN GoTerm g ON ct.go_id = g.go_id
WHERE ct.go_id IN (
    'GO:0030420',  -- establishment of competence for transformation
    'GO:0009290',  -- DNA import into cell involved in transformation
    'GO:0009291',  -- DNA import into cell
    'GO:0030422',  -- production of siRNA involved in RNA interference
    'GO:0030423'   -- establishment of competence for natural transformation
)
ORDER BY o.species_name, g.go_id;

-- QUERY 4: Comparing GO term distribution across organisms
-- The query shows the most common functional categories for each organism
SELECT 
    o.species_name AS Organism,
    g.aspect AS Functional_Aspect,
    COUNT(*) AS Annotation_Count,
    COUNT(DISTINCT g.go_id) AS Unique_GO_Terms
FROM Organism o
JOIN Protein p ON o.organism_id = p.organism_id
JOIN Annotation a ON p.protein_id = a.protein_id
JOIN GoTerm g ON a.go_id = g.go_id
GROUP BY o.species_name, g.aspect
ORDER BY o.species_name, Annotation_Count DESC;

-- QUERY 5: Finding proteins with multiple annotations related to competence
-- This query identifies proteins with multiple competence-associated annotations
SELECT 
    o.species_name AS Organism,
    p.uniprot_id AS Protein_ID,
    p.symbol AS Protein_Symbol,
    COUNT(DISTINCT a.go_id) AS Competence_Annotation_Count,
    GROUP_CONCAT(DISTINCT g.go_id ORDER BY g.go_id) AS Related_GO_Terms
FROM Organism o
JOIN Protein p ON o.organism_id = p.organism_id
JOIN Annotation a ON p.protein_id = a.protein_id
JOIN GoTerm g ON a.go_id = g.go_id
WHERE a.go_id IN (
    SELECT go_id FROM CompetenceTerm
)
GROUP BY o.species_name, p.uniprot_id, p.symbol
HAVING COUNT(DISTINCT a.go_id) >= 2
ORDER BY Competence_Annotation_Count DESC, o.species_name;