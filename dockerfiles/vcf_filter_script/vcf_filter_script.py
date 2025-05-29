import vcf


def get_csq_keys(vcf_file):
    """
    Extracts the CSQ annotation keys from the VCF header.

    This function searches for the '##INFO=<ID=CSQ' line in a VEP-annotated VCF file
    and parses the annotation format to return a list of CSQ field keys

    Args:
        vcf_file (str): Path to the VCF file.

    Returns
        list: A list of annotations/CSQ keys.
    """
    with open(vcf_file, 'r') as f:
        for line in f:
            # Looks for the CSQ line in the vcf file
            if line.startswith('##INFO=<ID=CSQ'):
                # Extracts the CSQ keys from the INFO field that occur after the 'Format: ', removing trailing spaces and the '>' found at the end of the CSQ line.
                # The cleaned CSQ line is stored in the description variable.
                description = line.split("Format: ")[1].strip('">')
                # THe clean CSQ line is then split at each '|' to generate a list of csq_keys which is later used in the parse_csq_field function.
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
        dict: A dictionary mapping CSQ keys to their corresponding values.
    """
    # This splits the vcf record CSQ string at '|' saving the csq values alongside the csq keys as a zipped dictionary
    csq_values = csq_value.split('|')
    return dict(zip(csq_keys, csq_values))

def passes_filters(record, csq_keys, config):  
    """
    Determines if a VCF record passes the defined filters by evaluating each CSQ annotation independently.

    Args:
        record (vcf.model._Record): A single variant call in a VCF record.
        csq_keys (list): The list of CSQ keys.
        config (dict): Dictionary with filtering thresholds.

    Returns:
        bool: True if the record passes the filters, False otherwise.
    """
    # Defining filtering thresholds from filter config file
    low_freq_threshold = float(config["low_freq_threshold"])
    high_freq_threshold = float(config["high_freq_threshold"])
    
    # Parsing the the CSQ field, splitting each records csq line into comma separated strings, enabled by PyVCF library.
    csq_values = record.INFO.get('CSQ', ['NA'])
    # This parses the individual csq strings through the parse_csq_field function, creating a list of dicts
    csq_annotations = [parse_csq_field(csq, csq_keys) for csq in csq_values]
    #print(f"CSQ Annotations: {csq_annotations}")  # For debugging

    # This iterates through each csq annotation string separately, pulling its clinvar status and gnomAD freqs, and applies filter conditions
    for annotation in csq_annotations:

        # Retrieves the ClinVar (CLIN_SIG) annotation from the vcf record INFO field, if its not present it returns an 'NA'
        clinvar = annotation.get('CLIN_SIG', 'NA')
        #print(f"ClinVar: {clinvar}")  # For debugging

        # List collecting all individual and cummulative Gnomad allele population frequencies.
        gnomad_populations = [
            annotation.get('gnomADe_AF', 'NA'),       # Overall allele frequency (exome)
            annotation.get('gnomADe_AFR_AF', 'NA'),   # African/African American (exome)
            annotation.get('gnomADe_AMR_AF', 'NA'),   # Admixed American (exome)
            annotation.get('gnomADe_ASJ_AF', 'NA'),   # Ashkenazi Jewish (exome)
            annotation.get('gnomADe_EAS_AF', 'NA'),   # East Asian (exome)
            annotation.get('gnomADe_FIN_AF', 'NA'),   # Finnish (exome)
            annotation.get('gnomADe_NFE_AF', 'NA'),   # Non-Finnish European (exome)
            annotation.get('gnomADe_OTH_AF', 'NA'),   # Other (exome)
            annotation.get('gnomADe_SAS_AF', 'NA'),   # South Asian (exome)
            annotation.get('gnomADg_AF', 'NA'),       # Overall allele frequency (genome)
            annotation.get('gnomADg_AFR_AF', 'NA'),   # African/African American (genome)
            annotation.get('gnomADg_AMI_AF', 'NA'),   # Amish (genome)
            annotation.get('gnomADg_AMR_AF', 'NA'),   # Admixed American (genome)
            annotation.get('gnomADg_ASJ_AF', 'NA'),   # Ashkenazi Jewish (genome)
            annotation.get('gnomADg_EAS_AF', 'NA'),   # East Asian (genome)
            annotation.get('gnomADg_FIN_AF', 'NA'),   # Finnish (genome)
            annotation.get('gnomADg_MID_AF', 'NA'),   # Middle Eastern (genome)
            annotation.get('gnomADg_NFE_AF', 'NA'),   # Non-Finnish European (genome)
            annotation.get('gnomADg_OTH_AF', 'NA'),   # Other (genome)
            annotation.get('gnomADg_SAS_AF', 'NA')    # South Asian (genome)
        ]

        # This filters out the 'NA' records which would otherwise trip-up the downstream filters which are expecting only floats
        try:
            gnomad_populations = [freq for freq in gnomad_populations if freq != 'NA']
        except ValueError as e:
            print(f"Error filtering absent gnomAD frequencies: {e}")
            print(f"Record {record.CHROM}:{record.POS}")
            continue

        #print(f"Record CHROM: {record.CHROM}, POS: {record.POS}")  # For debugging
        #print(f"ClinVar: {clinvar}")  # For debugging
        #print(f"GnomAD Populations: {gnomad_populations}")  # For debugging

        try:
            # Defining conditional filters.
            if any(freq and float(freq) < low_freq_threshold for freq in gnomad_populations):
                if not (clinvar and 'benign' in clinvar.lower()):
                    print(f"Record {record.CHROM}:{record.POS} passes filters: Gnomad allele frequency < {low_freq_threshold} and not benign in ClinVar.")
                    return True  #Gnomad allele frequency < low_freq_threshold (filter_config.json) AND NOT clinvar 'benign'
            elif any(freq and float(freq) > high_freq_threshold for freq in gnomad_populations):
                if clinvar and 'pathogenic' in clinvar.lower():
                    print(f"Record {record.CHROM}:{record.POS} passes filters: Gnomad allele frequency > {high_freq_threshold} and pathogenic in ClinVar.")
                    return True  #Gnomad allele frequency > high_freq_threshold (filter_config.json) AND clinvar 'pathogenic'
        except ValueError as e:
            print(f"Error pasing gnomAD frequencies for {record.CHROM}:{record.POS}:{e}")
            continue
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

    total_records = 0
    filtered_records = []

    for record in vcf_reader:
        total_records += 1
        if passes_filters(record, csq_keys, config):
            filtered_records.append(record)

    # Create a new vcf_writer object using the vcf.writer class in the PyVCF/vcf module.
    vcf_writer = vcf.Writer(open(output_vcf, 'w'), vcf_reader)

    print(f"Total records processed: {total_records}")
    print(f"Records passing filter: {len(filtered_records)}")
    print(f"Records NOT passing filter: {total_records-len(filtered_records)}")

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