import vcf


def get_csq_keys(vcf_file):
    """
    Parses the CSQ field of a VCF (VEP generated) and returns a list of its annotations

    Args:
        vcf_file (str): Path to the VCF file.

    Returns
        list: A list of annotations/CSQ keys.
    """
    with open(vcf_file, 'r') as f:
        for line in f:
            if line.startswith('##INFO=<ID=CSQ'):
                # Extract the CSQ keys from the INFO field
                description = line.split("Format: ")[1].strip('">')
                csq_keys = description.split('|')
                return csq_keys
    return []

def parse_csq_field(csq_value, csq_keys):
    """
    Parses a CSQ field value and returns a dictionary of its annotations.
    Args:
        csq_value (str): The CSQ field value from a VCF record.
        csq_keys (list): The list of CSQ keys.
    Returns:
        dict: A dictionary of annotations.
    """

    csq_values = csq_value.split('|')
    return dict(zip(csq_keys, csq_values))

def passes_filters(record, csq_keys, config):  
    """
    Determines if a VCF record passes the defined filters.

    Args:
        record (vcf.model._Record): A single variant call in a VCF record.
        csq_keys (list): The list of CSQ keys.

    Returns:
        bool: True if the record passes the filters, False otherwise.
    """
    # Defining filtering thresholds from filter config file
    low_freq_threshold = float(config["low_freq_threshold"])
    high_freq_threshold = float(config["high_freq_threshold"])
    
    # Parsing the the CSQ field
    csq_values = record.INFO.get('CSQ', ['NA'])
    csq_annotations = [parse_csq_field(csq, csq_keys) for csq in csq_values]
    #print(f"CSQ Annotations: {csq_annotations}")  # For debugging

    # Retrieves the ClinVar (CLIN_SIG) annotation from the vcf record INFO field, if its not present it returns an 'NA'
    clinvar = csq_annotations[0].get('CLIN_SIG', 'NA')
    #print(f"ClinVar: {clinvar}")  # For debugging

    # List collecting all individual and cummulative Gnomad allele population frequencies.
    gnomad_populations = [
        csq_annotations[0].get('gnomADe_AF', 'NA'),       # Overall allele frequency (exome)
        csq_annotations[0].get('gnomADe_AFR_AF', 'NA'),   # African/African American (exome)
        csq_annotations[0].get('gnomADe_AMR_AF', 'NA'),   # Admixed American (exome)
        csq_annotations[0].get('gnomADe_ASJ_AF', 'NA'),   # Ashkenazi Jewish (exome)
        csq_annotations[0].get('gnomADe_EAS_AF', 'NA'),   # East Asian (exome)
        csq_annotations[0].get('gnomADe_FIN_AF', 'NA'),   # Finnish (exome)
        csq_annotations[0].get('gnomADe_NFE_AF', 'NA'),   # Non-Finnish European (exome)
        csq_annotations[0].get('gnomADe_OTH_AF', 'NA'),   # Other (exome)
        csq_annotations[0].get('gnomADe_SAS_AF', 'NA'),   # South Asian (exome)
        csq_annotations[0].get('gnomADg_AF', 'NA'),       # Overall allele frequency (genome)
        csq_annotations[0].get('gnomADg_AFR_AF', 'NA'),   # African/African American (genome)
        csq_annotations[0].get('gnomADg_AMI_AF', 'NA'),   # Amish (genome)
        csq_annotations[0].get('gnomADg_AMR_AF', 'NA'),   # Admixed American (genome)
        csq_annotations[0].get('gnomADg_ASJ_AF', 'NA'),   # Ashkenazi Jewish (genome)
        csq_annotations[0].get('gnomADg_EAS_AF', 'NA'),   # East Asian (genome)
        csq_annotations[0].get('gnomADg_FIN_AF', 'NA'),   # Finnish (genome)
        csq_annotations[0].get('gnomADg_MID_AF', 'NA'),   # Middle Eastern (genome)
        csq_annotations[0].get('gnomADg_NFE_AF', 'NA'),   # Non-Finnish European (genome)
        csq_annotations[0].get('gnomADg_OTH_AF', 'NA'),   # Other (genome)
        csq_annotations[0].get('gnomADg_SAS_AF', 'NA')    # South Asian (genome)
    ]

    # This filters out the 'NA' records which would otherwise trip-up the down stream filters which are expecting only floats
    try:
        gnomad_populations = [freq for freq in gnomad_populations if freq != 'NA']
    except ValueError as e:
        print(f"Error filtering absent gnomAD frequencies: {e}")
        print(f"Record {record.CHROM}:{record.POS}")
        return False

    print(f"Record CHROM: {record.CHROM}, POS: {record.POS}")
    #print(f"ClinVar: {clinvar}")  # For debugging
    #print(f"GnomAD Populations: {gnomad_populations}")  # For debugging

    # Defining conditional filters. This may need to be expanded and applied to individual Gnomad populations
    if any(freq and float(freq) < low_freq_threshold for freq in gnomad_populations):
        if not (clinvar and 'benign' in clinvar.lower()):
            print(f"Record {record.CHROM}:{record.POS} passes filters: Gnomad allele frequency < 0.05 and not benign in ClinVar.")
            return True  #Gnomad allele frequency < 0.05 AND NOT clinvar 'benign'
    elif any(freq and float(freq) > high_freq_threshold for freq in gnomad_populations):
        if clinvar and 'pathogenic' in clinvar.lower():
            print(f"Record {record.CHROM}:{record.POS} passes filters: Gnomad allele frequency > 0.05 and pathogenic in ClinVar.")
            return True  #Gnomad allele frequency > 0.05 AND clinvar 'pathogenic'
    print(f"Record {record.CHROM}:{record.POS} does not pass filters")
    return False

def filter_vcf(input_vcf, output_vcf):
    """
    Filters a VCF file based on defined criteria and writes the filtered records to a new VCF file.

    Args:
        input_file (str): Path to the input VCF file.
        output_file (str): Path to the output VCF file.
    """
    csq_keys = get_csq_keys(input_vcf)

    # Read the inputted VCF file, collecting metadata (headers) for the vcf.Writer process, essentially allows the format from input.vcf to be copied over to output.vcf
    vcf_reader = vcf.Reader(open(input_vcf, 'r'))

    # Uses list comprehension to iterate through each vcf record (single variant), filter them using the passes_filer function and collect those 'True' records in the filtered_records list.
    filtered_records = [record for record in vcf_reader if passes_filters(record, csq_keys, config)]

    # Create a new vcf_writer object using the vcf.writer class in the PyVCF/vcf module.
    vcf_writer = vcf.Writer(open(output_vcf, 'w'), vcf_reader)

    print(f"Number of filtered records: {len(filtered_records)}")

    # Writes the filtered_records to the new VCF file using the vcf_record(record) method from the vcf_writer object created earlier.
    for record in filtered_records:
        vcf_writer.write_record(record)

    vcf_writer.close()

if __name__ == "__main__":
    import argparse
    import json

    # Set up argument parser
    parser = argparse.ArgumentParser(description="Filter VCF file based on Gnomad allele frequencies and ClinVar annotations.")
    parser.add_argument("input_vcf", help="Input VCF file to be filtered.")
    parser.add_argument("output_vcf", help="Output VCF file after filtering.")
    parser.add_argument("--config", required=True, help="Path to JSON config file with filtering parameters.")

    # Parse arguments
    args = parser.parse_args()

    # Parsing config file and loading contents in config library
    config = {}
    if args.config:
        with open(args.config) as f:
            config = json.load(f)

    required_keys = ["low_freq_threshold", "high_freq_threshold"]
    missing_keys = [key for key in required_keys if key not in config]
    if missing_keys:
        raise ValueError(f"Missing required config keys: {','.join(missing_keys)}")
    
    # Call the filter function
    filter_vcf(args.input_vcf, args.output_vcf)
    # Print a message indicating completion
    print(f"Filtered VCF file saved as {args.output_vcf}")
# This script filters a VCF file based on Gnomad allele frequencies and ClinVar annotations.
# It retains records with allele frequencies below 0.05 and not marked as 'benign' in ClinVar,
# or those with allele frequencies above 0.05 and marked as 'pathogenic' in ClinVar.


