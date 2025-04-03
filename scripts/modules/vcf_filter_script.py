import vcf

def passes_filters(record):
    clinvar = record.INFO.get('CLINVAR', 'NA')
    # List collecting all individual and cummulative Gnomad allele population frequencies.
    # TODO: sense check annotation ID e.g.'gnomAD_AFR'
    gnomad_populations = [
        record.INFO.get('gnomAD_AF', 'NA'),
        record.INFO.get('gnomAD_AFR', 'NA'),
        record.INFO.get('gnomAD_AMR', 'NA'),
        record.INFO.get('gnomAD_ASJ', 'NA'),
        record.INFO.get('gnomAD_EAS', 'NA'),
        record.INFO.get('gnomAD_FIN', 'NA'),
        record.INFO.get('gnomAD_NFE', 'NA'),
        record.INFO.get('gnomAD_SAS', 'NA')
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

