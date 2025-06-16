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
        #running Freebayes in standard configuration
        touch reference_fafai &&
        touch dedup_bai &&
        freebayes -f ~{reference_fa} -t ~{bed_file} ~{dedup_bam} > ~{sample_name}.vcf
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