# software_mini_project for software training module

Below is a flow diagram for the `my_pipeline_modular_wf.wdl` workflow:

```mermaid
graph TD
    B[**Input Files**: <br>- FASTQ<br>- GRCh38 reference files<br>- BED<br>- VEP.tar.gz]
    B -->|read1.fastq.gz, read2.fastq.gz| D[**Initial FastQC**:<br>Perform initial QC on read pairs<br><i>fastqc.wdl</i>]
    B -->|read1.fastq.gz, read2.fastq.gz| E[**FastP**:<br>Trim and filter the read pairs<br><i>fastp.wdl</i>]
    F[**Post-Processing FastQC**: *Perform quality control on the trimmed read pairs*<br><i>fastqc.wdl</i>]
    E -->|trimmed FASTQ| F
    B -->|GRCh38.fa, fa.bwt.2bit.64, .fa.ann, .fa.amb, .fa.pac, .fa.0123, .fa.fai| G[**BwaMem2**:<br>Align reads to the reference genome<br><i>bwamem2.wdl</i>]
    B -->|BED, GRCh38.fa, .fa.fai| H[**FreeBayes**:<br>Call variants<br><i>freebayes.wdl</i>]
    E -->|trimmed FASTQ| G[**BwaMem2**:<br>Align reads to the reference genome<br><i>bwamem2.wdl</i>]
    G -->|BAM, BAI| H[**FreeBayes**:<br>Call variants<br><i>freebayes.wdl</i>]
    B -->|VEP.tar.gz, GRCh38.fa| I[**VEP**:<br>Annotate variants<br><i>vep.wdl</i>]
    H -->|VCF| I[**VEP**:<br>Annotate variants<br><i>vep.wdl</i>]
    D -->|HTML, ZIP| J
    F -->|HTML, ZIP| J
    I -->|annotated.tsv| J[**Output Files**]

    subgraph Inputs
        B
    end

    subgraph QC
        D
        F
    end

    subgraph Processing
        E
        G
        H
        I
    end

    subgraph Outputs
        J
    end
