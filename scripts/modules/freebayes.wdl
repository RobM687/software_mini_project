version 1.1

task freebayes {
    input {
        File reference_fa
        File reference_fafai
        File? alignedBam
        File? alignedBai
        File bed_file
        String sample_name
    }

    command <<<
        #running Freebayes in standard configuration
        touch reference_fafai &&
        touch alignedBai &&
        freebayes -f ~{reference_fa} -t ~{bed_file} ~{alignedBam} > ~{sample_name}.vcf
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