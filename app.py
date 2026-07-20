import os
import re
from datetime import datetime

def getOrganismFiles():
    'Get all organism files from input_files directory.'
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    input_dir = os.path.join(base_dir, 'input_files')
    
    # Adjust path if it is runninf=g directly
    if not os.path.exists(input_dir):
        input_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'input_files')
    
    return [f for f in os.listdir(input_dir) 
            if not f.startswith('.') and os.path.isfile(os.path.join(input_dir, f))]

def parse_organism_from_file(filename):
    'Extract organism name from filename.'
    if 'Escherichia_coli_K-12' in filename:
        return 'Escherichia coli K-12'
    elif 'Bacillus_subtilis_168' in filename:
        return 'Bacillus subtilis 168'
    elif 'Bacillus_amyloliquefaciens' in filename:
        return 'Bacillus amyloliquefaciens FZB42'
    elif 'Bacillus_licheniformis' in filename:
        return 'Bacillus licheniformis ATCC 14580'
    elif 'Bacillus_megaterium' in filename:
        return 'Bacillus megaterium DSM 319'
    elif 'Geobacillus_kaustophilus' in filename:
        return 'Geobacillus kaustophilus HTA426'
    else:
        return 'Geobacillus thermodenitrificans NG80-2'

def escape_sql(value):
    """Escape single quotes for SQL."""
    if not value:
        return ''
    return value.replace("'", "''")

def generate_sql():
    """Generate SQL statements to create and populate the database."""
    sql = []
    
    # Dropping existing tables
    sql.append("DROP TABLE IF EXISTS Annotation;")
    sql.append("DROP TABLE IF EXISTS CompetenceTerm;")
    sql.append("DROP TABLE IF EXISTS Protein;")
    sql.append("DROP TABLE IF EXISTS GoTerm;")
    sql.append("DROP TABLE IF EXISTS Organism;")
    
    # Creating tables
    sql.append("""
    CREATE TABLE Organism (
        organism_id INT AUTO_INCREMENT PRIMARY KEY,
        species_name VARCHAR(255) NOT NULL,
        strain VARCHAR(100),
        taxon_id VARCHAR(50)
    );
    """)
    
    sql.append("""
    CREATE TABLE Protein (
        protein_id INT AUTO_INCREMENT PRIMARY KEY,
        uniprot_id VARCHAR(50) NOT NULL,
        symbol VARCHAR(100),
        name VARCHAR(255),
        organism_id INT NOT NULL,
        FOREIGN KEY (organism_id) REFERENCES Organism(organism_id)
    );
    """)
    
    sql.append("""
    CREATE TABLE GoTerm (
        go_id VARCHAR(20) PRIMARY KEY,
        aspect CHAR(1),
        description VARCHAR(255)
    );
    """)
    
    sql.append("""
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
    """)
    
    sql.append("""
    CREATE TABLE CompetenceTerm (
        competence_id INT AUTO_INCREMENT PRIMARY KEY,
        go_id VARCHAR(20) NOT NULL,
        is_direct BOOLEAN DEFAULT TRUE,
        FOREIGN KEY (go_id) REFERENCES GoTerm(go_id)
    );
    """)
    
    # Collecting all data
    organisms = {}
    proteins = {}
    go_terms = set()
    annotations = []
    
    for filename in getOrganismFiles():
        filepath = os.path.join(os.path.dirname(os.path.abspath(__file__)), "input_files", filename)
        if not os.path.exists(filepath):
            filepath = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "input_files", filename)
        
        if os.path.exists(filepath):
            organism_name = parse_organism_from_file(filename)
            
            with open(filepath, 'r') as f:
                for line in f:
                    if line.startswith('!'):
                        continue
                    
                    fields = line.strip().split('\t')
                    if len(fields) < 17:
                        continue
                    
                    # Extracting fields
                    uniprot_id = fields[1]
                    symbol = fields[2]
                    go_id = fields[4]
                    reference = fields[5]
                    evidence = fields[6]
                    qualifier = fields[3]
                    with_from = fields[7]
                    aspect = fields[8]
                    name = fields[9] if len(fields) > 9 else ''
                    date = fields[13] if len(fields) > 13 else ''
                    assigned_by = fields[14] if len(fields) > 14 else ''
                    taxon = fields[12] if len(fields) > 12 else ''
                    
                    # Storing organism
                    organisms[organism_name] = {'taxon': taxon.replace('taxon:', '') if taxon else ''}
                    
                    # Storing protein
                    protein_key = f"{uniprot_id}_{organism_name}"
                    proteins[protein_key] = {
                        'uniprot_id': uniprot_id,
                        'symbol': symbol,
                        'name': name,
                        'organism': organism_name
                    }
                    
                    # Storing GO term
                    if go_id:
                        go_terms.add(go_id)
                    
                    # Storing annotation
                    annotations.append({
                        'uniprot_id': uniprot_id,
                        'go_id': go_id,
                        'evidence': evidence,
                        'reference': reference,
                        'qualifier': qualifier,
                        'with_from': with_from,
                        'date': date or datetime.now().strftime('%Y%m%d'),
                        'assigned_by': assigned_by,
                        'organism': organism_name
                    })
    
    # Inserting organisms
    for org_name, org_data in organisms.items():
        taxon = org_data.get('taxon', '')
        sql.append(f"INSERT IGNORE INTO Organism (species_name, taxon_id) VALUES ('{escape_sql(org_name)}', '{escape_sql(taxon)}');")
    
    # Inserting proteins
    for protein_key, protein_data in proteins.items():
        sql.append(f"""
        INSERT IGNORE INTO Protein (uniprot_id, symbol, name, organism_id) 
        SELECT '{escape_sql(protein_data['uniprot_id'])}', 
               '{escape_sql(protein_data['symbol'])}', 
               '{escape_sql(protein_data['name'])}', 
               organism_id 
        FROM Organism 
        WHERE species_name = '{escape_sql(protein_data['organism'])}';
        """)
    
    # Inserting GO terms
    for go_id in go_terms:
        sql.append(f"INSERT IGNORE INTO GoTerm (go_id) VALUES ('{go_id}');")
    
    # Inserting annotations
    for ann in annotations:
        sql.append(f"""
        INSERT IGNORE INTO Annotation (protein_id, go_id, evidence_code, reference, qualifier, with_from, date, assigned_by)
        SELECT p.protein_id, '{ann['go_id']}', '{escape_sql(ann['evidence'])}', 
               '{escape_sql(ann['reference'])}', '{escape_sql(ann['qualifier'])}', 
               '{escape_sql(ann['with_from'])}', '{ann['date']}', '{escape_sql(ann['assigned_by'])}'
        FROM Protein p
        JOIN Organism o ON p.organism_id = o.organism_id
        WHERE p.uniprot_id = '{ann['uniprot_id']}' 
        AND o.species_name = '{escape_sql(ann['organism'])}';
        """)
    
    # Inserting competence terms
    competence_terms = ['GO:0030420', 'GO:0009290', 'GO:0009291', 'GO:0030422', 'GO:0030423']
    for term in competence_terms:
        is_direct = 'TRUE' if term == 'GO:0030420' else 'FALSE'
        sql.append(f"INSERT IGNORE INTO CompetenceTerm (go_id, is_direct) VALUES ('{term}', {is_direct});")
    
    # Writing to file
    output_file = os.path.join(os.path.dirname(os.path.abspath(__file__)), "result.sql")
    with open(output_file, 'w') as f:
        f.write('\n'.join(sql))
    
    print(f"SQL file generated: {output_file}")

if __name__ == "__main__":
    generate_sql()