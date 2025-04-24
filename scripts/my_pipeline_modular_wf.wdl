version 1.0

import "modules/fastqc.wdl" as fastqc
import "modules/fastp.wdl" as fastp
import "modules/bwamem2.wdl" as bwamem2
import "modules/remove_dups.wdl" as remove_dups
import "modules/freebayes.wdl" as freebayes
import "modules/vep.wdl" as vep

workflow my_pipeline_modular {
    input {
        File read1
        File read2
        File reference_fa
        File reference_fabwt2bit64
        File reference_faann
        File reference_faamb
        File reference_fapac
        File reference_fa0123
        File reference_fafai
        File bed_file
        File vep_tar
        String cache_version
        Int fork
        # Do i need a defined output directory OutputDir?
    }

    Array[File] fastqs_initial_qc = [read1, read2]
    
    call fastqc.fastqc as initial_fastqc {
        input:
            fastq_files = fastqs_initial_qc,
            read1 = read1
    }

    call fastp.fastp {
        input: 
            read1 = read1,
            read2 = read2       
    }

    Array[File] fastqs_post_processing_qc = [fastp.trimmed_read1, fastp.trimmed_read2]

    call fastqc.fastqc as post_processing_fastqc {
        input:
            fastq_files = fastqs_post_processing_qc,
            read1 = read1
    }

    call bwamem2.bwamem2 {
        input:
            read1 = fastp.trimmed_read1,
            read2 = fastp.trimmed_read2,
            reference_fa = reference_fa,
            reference_fabwt2bit64 = reference_fabwt2bit64,
            reference_faann = reference_faann,
            reference_faamb = reference_faamb,
            reference_fapac = reference_fapac,
            reference_fa0123 = reference_fa0123
    }

    call remove_dups.RemoveDuplicates {
        input:
            alignedBam = bwamem2.alignedBam,
            alignedBai = bwamem2.alignedBai
    }
    
    call remove_dups.IndexDedupBam {
        input:
            dedup_bam = remove_dups.RemoveDuplicates.dedup_bam
    }

    call freebayes.freebayes {
        input:
            alignedBam = bwamem2.alignedBam,
            alignedBai = bwamem2.alignedBai,
            reference_fa = reference_fa,
            reference_fafai = reference_fafai,
            bed_file = bed_file
    }

    call vep.vep {
        input:
            vep_tar = vep_tar,
            vcf = freebayes.vcf,
            reference_fa = reference_fa,
            cache_version = cache_version,
            fork = fork
    }

    output {        
        Array[File] initial_qc_reports = initial_fastqc.qc_reports
        Array[File] initial_qc_summaries = initial_fastqc.qc_summaries
        Array[File] post_processing_qc_reports = post_processing_fastqc.qc_reports
        Array[File] post_processing_qc_summaries = post_processing_fastqc.qc_summaries
        File trimmed_read1 = fastp.trimmed_read1
        File trimmed_read2 = fastp.trimmed_read2
        File alignedBam = bwamem2.alignedBam
        File alignedBai = bwamem2.alignedBai
        File dedup_bam = RemoveDuplicates.dedup_bam
        File dedup_bai = IndexDedupBam.dedup_bai
        File dedup_metrics = RemoveDuplicates.dedup_metrics
        File vcf = freebayes.vcf
        File annotated_vcf = vep.annotated_vcf
    }
}