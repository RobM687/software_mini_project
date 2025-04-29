import vcf

def passes_filters(record):
    # Retrieves the ClinVar (CLIN_SIG) annotation from the vcf record INFO field, if its not present it returns an 'NA'
    clinvar = record.INFO.get('CLIN_SIG', 'NA')
    # List collecting all individual and cummulative Gnomad allele population frequencies.
    gnomad_populations = [
        record.INFO.get('gnomADe_AF', 'NA'),       # Overall allele frequency (exome)
        record.INFO.get('gnomADe_AFR_AF', 'NA'),   # African/African American (exome)
        record.INFO.get('gnomADe_AMR_AF', 'NA'),   # Admixed American (exome)
        record.INFO.get('gnomADe_ASJ_AF', 'NA'),   # Ashkenazi Jewish (exome)
        record.INFO.get('gnomADe_EAS_AF', 'NA'),   # East Asian (exome)
        record.INFO.get('gnomADe_FIN_AF', 'NA'),   # Finnish (exome)
        record.INFO.get('gnomADe_NFE_AF', 'NA'),   # Non-Finnish European (exome)
        record.INFO.get('gnomADe_OTH_AF', 'NA'),   # Other (exome)
        record.INFO.get('gnomADe_SAS_AF', 'NA'),   # South Asian (exome)
        record.INFO.get('gnomADg_AF', 'NA'),       # Overall allele frequency (genome)
        record.INFO.get('gnomADg_AFR_AF', 'NA'),   # African/African American (genome)
        record.INFO.get('gnomADg_AMI_AF', 'NA'),   # Amish (genome)
        record.INFO.get('gnomADg_AMR_AF', 'NA'),   # Admixed American (genome)
        record.INFO.get('gnomADg_ASJ_AF', 'NA'),   # Ashkenazi Jewish (genome)
        record.INFO.get('gnomADg_EAS_AF', 'NA'),   # East Asian (genome)
        record.INFO.get('gnomADg_FIN_AF', 'NA'),   # Finnish (genome)
        record.INFO.get('gnomADg_MID_AF', 'NA'),   # Middle Eastern (genome)
        record.INFO.get('gnomADg_NFE_AF', 'NA'),   # Non-Finnish European (genome)
        record.INFO.get('gnomADg_OTH_AF', 'NA'),   # Other (genome)
        record.INFO.get('gnomADg_SAS_AF', 'NA')    # South Asian (genome)
    ]

    # Defining conditional filters. This may need to be expanded and applied to individual Gnomad populations
    if any(freq and float(freq) < 0.05 for freq in gnomad_populations):
        if not (clinvar and 'benign' in clinvar.lower()):
            return True  #Gnomad allele frequency < 0.05 AND NOT clinvar 'benign'
    elif any(freq and float(freq) > 0.05 for rfeq in gnomad_populations):
        if clinvar and 'pathogenic' in clinvar.lower():
            return True  #Gnomad allele frequency > 0.05 AND clinvar 'pathogenic'
    return False

# Read the VCF file
vcf_reader = vcf.Reader(open('your_annotated_file.vcf', 'r'))

# Initialize a list to store filtered records
filtered_records = [record for record in vcf_reader if passes_filters(record)]

# Create a new VCF writer
vcf_writer = vcf.Writer(open('filtered_variants.vcf', 'w'), vcf_reader)

# Write filtered records to the new VCF file
for record in filtered_records:
    vcf_writer.write_record(record)

vcf_writer.close()

