version 1.1

task freebayes {
    input {
        File reference_fa
        File reference_fafai
        File? dedup_bam
        File? dedup_bai
        File bed_file
        String sample_name
    }

    command <<<
        # Copy BAM and BAI
        cp ~{dedup_bam} dedup.bam
        if [ -f "~{dedup_bai}" ]; then
            cp ~{dedup_bai} dedup.bam.bai
        fi
        
        # Copy ref FASTA index to expected name
        cp ~{reference_fafai} ~{reference_fa}.fai

        # Running Freebayes in standard configuration
        freebayes -f ~{reference_fa} -t ~{bed_file} dedup.bam > ~{sample_name}.vcf
    >>>

    output {
        File? vcf = "~{sample_name}.vcf"
    }

    runtime {
        docker: "swglh/freebayes:1.3.6"
        memory: "16 GB"
        cpu: 4
        continueOnReturnCode: true
    }
}