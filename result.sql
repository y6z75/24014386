DROP TABLE IF EXISTS Annotation;
DROP TABLE IF EXISTS CompetenceTerm;
DROP TABLE IF EXISTS Protein;
DROP TABLE IF EXISTS GoTerm;
DROP TABLE IF EXISTS Organism;

    CREATE TABLE Organism (
        organism_id INT AUTO_INCREMENT PRIMARY KEY,
        species_name VARCHAR(255) NOT NULL,
        strain VARCHAR(100),
        taxon_id VARCHAR(50)
    );
    

    CREATE TABLE Protein (
        protein_id INT AUTO_INCREMENT PRIMARY KEY,
        uniprot_id VARCHAR(50) NOT NULL,
        symbol VARCHAR(100),
        name VARCHAR(255),
        organism_id INT NOT NULL,
        FOREIGN KEY (organism_id) REFERENCES Organism(organism_id)
    );
    

    CREATE TABLE GoTerm (
        go_id VARCHAR(20) PRIMARY KEY,
        aspect CHAR(1),
        description VARCHAR(255)
    );
    

    CREATE TABLE Annotation (
        annotation_id INT AUTO_INCREMENT PRIMARY KEY,
        protein_id INT NOT NULL,
        go_id VARCHAR(20) NOT NULL,
        evidence_code VARCHAR(10),
        reference VARCHAR(255),
        qualifier VARCHAR(50),
        with_from VARCHAR(255),
        date VARCHAR(8),
        assigned_by VARCHAR(100),
        FOREIGN KEY (protein_id) REFERENCES Protein(protein_id),
        FOREIGN KEY (go_id) REFERENCES GoTerm(go_id)
    );
    

    CREATE TABLE CompetenceTerm (
        competence_id INT AUTO_INCREMENT PRIMARY KEY,
        go_id VARCHAR(20) NOT NULL,
        is_direct BOOLEAN DEFAULT TRUE,
        FOREIGN KEY (go_id) REFERENCES GoTerm(go_id)
    );
    
INSERT IGNORE INTO Organism (species_name, taxon_id) VALUES ('Escherichia coli K-12', '83333');

        INSERT IGNORE INTO Protein (uniprot_id, symbol, name, organism_id) 
        SELECT 'P37443', 
               'ycaI', 
               'metallo-beta-lactamase superfamily inner membrane protein YcaI', 
               organism_id 
        FROM Organism 
        WHERE species_name = 'Escherichia coli K-12';
        

        INSERT IGNORE INTO Protein (uniprot_id, symbol, name, organism_id) 
        SELECT 'P75869', 
               'sxy', 
               'transcriptional coactivator for CRP', 
               organism_id 
        FROM Organism 
        WHERE species_name = 'Escherichia coli K-12';
        
INSERT IGNORE INTO GoTerm (go_id) VALUES ('GO:0030420');

        INSERT IGNORE INTO Annotation (protein_id, go_id, evidence_code, reference, qualifier, with_from, date, assigned_by)
        SELECT p.protein_id, 'GO:0030420', 'IEA', 
               'GO_REF:0000002', '', 
               'InterPro:IPR004797', '20190112', 'InterPro'
        FROM Protein p
        JOIN Organism o ON p.organism_id = o.organism_id
        WHERE p.uniprot_id = 'P37443' 
        AND o.species_name = 'Escherichia coli K-12';
        

        INSERT IGNORE INTO Annotation (protein_id, go_id, evidence_code, reference, qualifier, with_from, date, assigned_by)
        SELECT p.protein_id, 'GO:0030420', 'IEA', 
               'GO_REF:0000037', '', 
               'SP_KW:KW-0178', '20190112', 'UniProtKB'
        FROM Protein p
        JOIN Organism o ON p.organism_id = o.organism_id
        WHERE p.uniprot_id = 'P75869' 
        AND o.species_name = 'Escherichia coli K-12';
        
INSERT IGNORE INTO CompetenceTerm (go_id, is_direct) VALUES ('GO:0030420', TRUE);
INSERT IGNORE INTO CompetenceTerm (go_id, is_direct) VALUES ('GO:0009290', FALSE);
INSERT IGNORE INTO CompetenceTerm (go_id, is_direct) VALUES ('GO:0009291', FALSE);
INSERT IGNORE INTO CompetenceTerm (go_id, is_direct) VALUES ('GO:0030422', FALSE);
INSERT IGNORE INTO CompetenceTerm (go_id, is_direct) VALUES ('GO:0030423', FALSE);