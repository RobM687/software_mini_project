# software_mini_project for software training module

## Overview
This repository contains a modular Workflow Description Language (WDL) workflow (`my_pipeline_modular_wf.wdl`), designed to process constitutional genomic data. The workflow includes quality control, read trimming, alignment, duplicate removal, variant calling, annotation, and VCF filtering.

The Docker images used are specified within the runtime block of each module WDL script. These images are automatically pulled and executed by `miniwdl` WDL engine when running locally or by the DNA Nexus platform when deployed in the cloud.

The workflow is structured using modular WDL imports and uses a `Sample` struct to define paired-end FASTQ inputs. It uses a `scatter` block to parallelize processing across multiple samples

The final output of the workflow is a filtered VCF file that contains variant calls annotated by the Variant Effect Predictor (Ensembl VEP). The filtering criteria are based on the following conditions:

- Variants with GnomAD allele frequencies < 0.05 that are **NOT** marked as '*benign*' in ClinVar.
- Variants with GnomAD allele frequencies > 0.05 that **ARE** marked as '*pathogenic*' in ClinVar.

The filtering is implemented via a Python script that parses the CSQ field of the VCF file, extracts relevant annotations, and applies the defined filters. The filtering thresholds for the Gnomad allele frequencies are stored in the `filter_config.json`.

### Pipeline Flowchart
Here is a visual representation of the `my_pipeline_modular_wf.wdl` workflow using a mermaid flowchart:

```mermaid
 
graph TD
    A[**Input Files**: <br>- FASTQ<br>- GRCh38 reference files<br>- BED<br>- VEP.tar.gz<br>- vcf_filter_script.py<br>- filter_config.json]
    A -->|Sample struct<br>read1.fastq.gz, read2.fastq.gz| S[**Scatter over samples**:<br>Parallel processing]
    S --> B[**Initial FastQC**:<br>Perform initial QC on read pairs<br><i>fastqc.wdl</i>]
    S --> C[**FastP**:<br>Trim and filter the read pairs<br><i>fastp.wdl</i>]
    C --> D[**Post-Processing FastQC**: *Perform quality control on the trimmed read pairs*<br><i>fastqc.wdl</i>]
    C -->|trimmed FASTQ| E[**BwaMem2**:<br>Align reads to the reference genome<br><i>bwamem2.wdl</i>]
    A -->|GRCh38 reference files| E
    E -->|BAM, BAI| F[**RemoveDuplicates**:<br>Remove duplicate reads<br><i>remove_dups.wdl</i>]
    F -->|dedup BAM| G[**IndexDedupBam**:<br>Index the deduplicated BAM file<br><i>remove_dups.wdl</i>]
    G --> |dedup BAM, dedup BAI| H[**FreeBayes**:<br>Call variants<br><i>freebayes.wdl</i>]
    A -->|BED, <br>GRCh38.fa reference files| H
    H -->|VCF| I[**VEP**:<br>Annotate variants<br><i>vep.wdl</i>]
    A -->|VEP.tar.gz, GRCh38.fa| I
    I -->|annotated.vcf| J[**VcfFilter**:<br>Filter annotated variants<br><i>vcf_filter.wdl</i>]
    A -->|vcf_filter_script.py, <br>filter_config.json| J
    B -->|HTML, ZIP| K[**Output Files**]
    D -->|HTML, ZIP| K
    F -->|dedup_metrics.txt| K
    J -->|filtered.vcf| K

    subgraph Inputs
        A
    end

    subgraph Scatter Processing
        S
        C
        E
        F
        G
        H
        I
        J

        subgraph QC
           B
           D
        end
        
    end  
```
## Installation
To set up the workflow, follow these steps:

1. Clone the repository:
```bash
git clone https://github.com/RobM687/software_mini_project.git
cd software_mini_project
```

2. Set up and activate the Python virtual environment:
```bash
python3 -m venv venv
source venv/bin/activate
 ```

3. Install dependencies: Install the required Python packages using `requirements.txt`:
- `miniwdl==1.12.0`
- `docker==5.0.3`
```bash
pip install -r requirements.txt
 ```


4. Ensure packages have installed
```bash
pip show <package>
```

5. Run the workflow from the project root: Use `miniwdl` to run the WDL workflow. Replace `config/my_pipeline_modular_inputs.json` with your input JSON file.
```wdl
miniwdl run scripts/my_pipeline_modular_wf.wdl -i config/test_inputs.json
```



## Inputs
### samples: An array of `Sample` structs, each containing:
- **sample_name**: Name of sample. *(Used in fastp, bwamem2, remove_dups, freebayes, vep, vcf_filter)*
- **read1**: First read file in FASTQ format. *(Used in fastqc, fastp, bwamem2)*
- **read2**: Second read file in FASTQ format. *(Used in fastqc, fastp, bwamem2)*
### Other inputs:
- **reference_fa**: Reference genome in FASTA format. *(Used in bwamem2)*
- **reference_fabwt2bit64**: BWT 2-bit 64 file for the reference genome. *(Used in bwamem2)*
- **reference_faann**: ANN file for the reference genome. *(Used in bwamem2)*
- **reference_faamb**: AMB file for the reference genome. *(Used in bwamem2)*
- **reference_fapac**: PAC file for the reference genome. *(Used in bwamem2)*
- **reference_fa0123**: 0123 file for the reference genome. *(Used in bwamem2)*
- **reference_fafai**: FAI index file for the reference genome. *(Used in freebayes)*
- **bed_file**: BED file for regions of interest. *(Used in freebayes)*
- **vep_tar**: VEP annotation tool tarball. *(Used in vep)*
- **cache_version**: Cache version for VEP. *(Used in vep)*
- **fork**: Number of forks for VEP. *(Used in vep)*
- **vcf_filter_script**: Python script for filtering annotated VCF. *(Used in vcf_filter)*
- **filter_config**: JSON config for filtering criteria. *(Used in vcf_filter)*

*GRCh38 Reference Genome files can be downloaded from [Ensembl](https://ftp.ensembl.org/pub/release-114/fasta/homo_sapiens/dna/Homo_sapiens.GRCh38.dna_sm.primary_assembly.fa.gz)*

*Index files for the* `reference.fa` *file can be generated using BWA-MEM2*:
```bash
bwa-mem2 index reference.fa
```

*VEP cache files can be downloaded from [Ensembl](https://ftp.ensembl.org/pub/release-111/variation/vep/homo_sapiens_refseq_vep_111_GRCh38.tar.gz). This pipeline was developed using VEP version 111, if you wish to use an alternate version of VEP the Docker image used by `vep.wdl`, the VEP cache will need to be updated to a compatible version. Using mismatched versions (e.g., VEP 110 Docker with VEP 114 cache) can lead to errors or incorrect annotations.*

## Outputs

- **initial_qc_reports**: Initial QC reports in ZIP format. *(Generated by fastqc)*
- **initial_qc_summaries**: Initial QC summaries in HTML format. *(Generated by fastqc)*
- **post_processing_qc_reports**: Post-processing QC reports in ZIP format. *(Generated by fastqc)*
- **post_processing_qc_summaries**: Post-processing QC summaries in HTML format. *(Generated by fastqc)*
- **trimmed_read1**: Trimmed first read file. *(Generated by fastp)*
- **trimmed_read2**: Trimmed second read file. *(Generated by fastp)*
- **alignedBam**: Aligned BAM file. *(Generated by bwamem2)*
- **alignedBai**: Aligned BAI index file. *(Generated by bwamem2)*
- **dedup_bam**: Deduplicated BAM file. *(Generated by remove_dups)*
- **dedup_bai**: Deduplicated BAI index file. *(Generated by remove_dups)*
- **dedup_metrics**: Deduplication metrics file. *(Generated by remove_dups)*
- **vcf**: VCF file with called variants. *(Generated by freebayes)*
- **annotated_vcf**: Annotated VCF file. *(Generated by vep)*
- **filtered_vcf**: Filtered VCF file. *(Generated by vcf_filter)*

## Struct Definitions
The workflow uses a custom `Sample` struct defined in `modules/structs.wdl`:
```wdl
struct Sample {
    String sample_name
    File read1
    File read2
}
```
## Input JSON Schema
The `input.json` file provides all the necessary inputs for running the workflow. Below is a breakdown of the `config/my_pipeline_modular_inputs.json` file with its expected keys and corresponding value types:
```JSON
{
    "my_pipeline_modular.samples": [
        {
            "read1": "File (path to read1 FASTQ file)",
            "read2": "File (path to read2 FASTQ file)",
            "sample_name": "String (sample name)"
        }
    ],
    "my_pipeline_modular.reference_fa": "File (path to GRCh38_reference.fa)",
    "my_pipeline_modular.reference_fabwt2bit64": "File (path to GRCh38_reference.bwt.2bit.64 index)",
    "my_pipeline_modular.reference_faann": "File (path to GRCh38_reference.ann index)",
    "my_pipeline_modular.reference_faamb": "File (path to GRCh38_reference.amb index)",
    "my_pipeline_modular.reference_fapac": "File (path to GRCh38_reference.pac index)",
    "my_pipeline_modular.reference_fa0123": "File (path to GRCh38_reference.0123 index)",
    "my_pipeline_modular.reference_fafai": "File (path to GRCh38_reference.fai index)",
    "my_pipeline_modular.bed_file": "File (path to BED file)",
    "my_pipeline_modular.vep_tar": "File (path to VEP tar.gz)",
    "my_pipeline_modular.cache_version": "String (VEP cache version)",
    "my_pipeline_modular.fork": "Int (number of forks for VEP)",
    "my_pipeline_modular.vcf_filter_script": "File (path to VCF filtering script)",
    "my_pipeline_modular.filter_config": "File (path to JSON config for filtering)"
    }
```
- Ensure all file paths point to existing, accessible files.
- Each Sample must include both read1 and read2.
- Set fork based on available CPU cores. Too high a value may cause memory issues.
- Omitting required keys (e.g., `reference_fafai`) will cause the workflow to fail.

## Filter Config JSON Schema
The `filter_config.json` file defines the allele frequency thresholds used during the VCF filtering step. These thresholds determine which variants are retained based on their frequency in the GnomAD database, alongside their ClinVar status annotations.
```JSON
{
    "low_freq_threshold": 0.05,
    "high_freq_threshold": 0.05
}
```
**low_freq_threshold** (Float):
Variants with a GnomAD allele frequency below this threshold are retained only if they are not marked as 'benign' in ClinVar.

**high_freq_threshold** (Float):
Variants with a GnomAD allele frequency above this threshold are retained only if they are marked as 'pathogenic' in ClinVar.

- Omitting either threshold will cause the filtering script to fail or behave unpredictably.
- Values must be numeric (floats), not strings (e.g., `"0.05"` is incorrect).

## ☁️ Running the workflow on DNAnexus
This workflow can also be deployed and executed on the DNAnexus Platform using dxCompiler.

#### Requirements
- A DNAnexus account and contributor access to a project.
- Java 8 or later installed
- dxCompiler JAR file (e.g., `dxCompiler-2.11.4.jar`)
- dx command-line tool installed and authenticated (`dx login`)
- All Docker images specified in the runtime blocks are publicly accessible (e.g., on Docker Hub).

### Upload input files to DNAnexus
Upload all required input files (FASTQs, reference genome files, BED, VEP tarball, filtering script, and configs) to your DNAnexus project:
``` bash
dx upload /path/to/file.fastq.gz --destination "project-xxxx:/input_data/"
```

### Compile the worklfow
Use `dxCompiler` to compile the WDL script into a DNAnexus workflow:
```bash
java -jar dxCompiler-2.11.4.jar \
  compile scripts/my_pipeline_modular_wf.wdl \
  -compileMode All \
  -extras config/extras.json \
  -destination "project-xxxx:/workflows/"
```
This will create a DNAnexus workflow in your chosen project under the `/workflows/` folder.

### Generate `dx.json` input file
Convert your local input JSON to a DNAnexus-compatible format:
```bash
java -jar dxCompiler-2.11.4.jar \
  compile scripts/my_pipeline_modular_wf.wdl \
  -compileMode IR \
  -inputs config/my_pipeline_modular_inputs.json \
  > config/my_pipeline_modular_inputs.dx.json
```
The `dx.json` file can then be edited to replace local file paths with DNAnexus file IDs or project-relative paths, e.g.:
```JSON
"my_pipeline_modular.reference_fa": "project-xxxx:/input_data/GRCh38.fa"
```

### Run the workflow
Use the dx run command to launch the workflow using the workflow name:
```bash
dx run my_pipeline_modular \
  -f config/test_inputs.dx.json \
  --destination "project-xxxx:/results/" \
  --delay-workspace-destruction
```
or specificing the workflow-ID
```bash
dx run workflow-xxxxID \
  -f config/test_inputs.dx.json \
  --destination "project-xxxx:/results/" \
  --delay-workspace-destruction
```
