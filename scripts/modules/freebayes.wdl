version 1.0

task freebayes {
    input {
        File reference_fa
        File reference_fafai
        File alignedBam
        File alignedBai
        File bed_file
    }

    # Derive the output name from read1 by removing the '_R1.fastq.gz' suffix
    String outputName = sub(basename(alignedBam), "_sorted\\.bam$", "")

    command <<<
        #running Freebayes in standard configuration
        touch reference_fafai &&
        touch alignedBai &&
        freebayes -f ~{reference_fa} -t ~{bed_file} ~{alignedBam} > ~{outputName}.vcf
    >>>

    output {
        File vcf = "~{outputName}.vcf"
    }

    runtime {
        docker: "swglh/freebayes:1.3.6"
    }
}