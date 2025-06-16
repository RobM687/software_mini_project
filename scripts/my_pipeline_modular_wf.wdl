version 1.1

import "modules/fastqc.wdl" as fastqc
import "modules/fastp.wdl" as fastp
import "modules/bwamem2.wdl" as bwamem2
import "modules/remove_dups.wdl" as remove_dups
import "modules/freebayes.wdl" as freebayes
import "modules/vep.wdl" as vep
import "modules/vcf_filter.wdl" as vcf_filter
import "modules/structs.wdl"

workflow my_pipeline_modular {
    input {
        Array[Sample] samples
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
        File vcf_filter_script
        File filter_config
        # Do i need a defined output directory OutputDir?
    }
    
    scatter (sample in samples) {
     
        call fastqc.fastqc as initial_fastqc {
            input:
                fastq_files = [sample.read1, sample.read2]
        }

        call fastp.fastp as run_fastp {
            input: 
                read1 = sample.read1,
                read2 = sample.read2, 
                sample_name = sample.sample_name      
        }

        call fastqc.fastqc as post_processing_fastqc {
            input:
                fastq_files = [run_fastp.trimmed_read1, run_fastp.trimmed_read2]
        }

        call bwamem2.bwamem2 as run_bwamem2 {
            input:
                read1 = run_fastp.trimmed_read1,
                read2 = run_fastp.trimmed_read2,
                reference_fa = reference_fa,
                reference_fabwt2bit64 = reference_fabwt2bit64,
                reference_faann = reference_faann,
                reference_faamb = reference_faamb,
                reference_fapac = reference_fapac,
                reference_fa0123 = reference_fa0123,
                sample_name = sample.sample_name
        }

        call remove_dups.RemoveDuplicates {
            input:
                alignedBam = run_bwamem2.alignedBam,
                alignedBai = run_bwamem2.alignedBai,
                sample_name = sample.sample_name
        }
        
        call remove_dups.IndexDedupBam {
            input:
                dedup_bam = RemoveDuplicates.dedup_bam
        }

        call freebayes.freebayes as run_freebayes{
            input:
                dedup_bam = RemoveDuplicates.dedup_bam,
                dedup_bai = IndexDedupBam.dedup_bai,
                reference_fa = reference_fa,
                reference_fafai = reference_fafai,
                bed_file = bed_file,
                sample_name = sample.sample_name
        }

        call vep.vep as run_vep {
            input:
                vep_tar = vep_tar,
                vcf = run_freebayes.vcf,
                reference_fa = reference_fa,
                cache_version = cache_version,
                fork = fork,
                sample_name = sample.sample_name
        }

        call vcf_filter.VcfFilter {
            input:
                annotated_vcf = run_vep.annotated_vcf,
                vcf_filter_script = vcf_filter_script,
                filter_config = filter_config,
                sample_name = sample.sample_name
        }
    }

    output {        
        Array[Array[File?]] initial_qc_reports = initial_fastqc.qc_reports
        Array[Array[File?]] initial_qc_summaries = initial_fastqc.qc_summaries
        Array[Array[File?]] post_processing_qc_reports = post_processing_fastqc.qc_reports
        Array[Array[File?]] post_processing_qc_summaries = post_processing_fastqc.qc_summaries
        Array[File?] trimmed_read1 = run_fastp.trimmed_read1
        Array[File?] trimmed_read2 = run_fastp.trimmed_read2
        Array[File?] alignedBam = run_bwamem2.alignedBam
        Array[File?] alignedBai = run_bwamem2.alignedBai
        Array[File?] dedup_bam = RemoveDuplicates.dedup_bam
        Array[File?] dedup_bai = IndexDedupBam.dedup_bai
        Array[File?] dedup_metrics = RemoveDuplicates.dedup_metrics
        Array[File?] vcf = run_freebayes.vcf
        Array[File?] annotated_vcf = run_vep.annotated_vcf
        Array[File?] filtered_vcf = VcfFilter.filtered_vcf
    }
}