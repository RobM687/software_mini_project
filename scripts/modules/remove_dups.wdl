version 1.1

task RemoveDuplicates {
    input {
        File? alignedBam
        String sample_name
    }

    command <<<
        java -jar /app/picard.jar \
        MarkDuplicates \
        I=~{alignedBam} \
        O=~{sample_name}_dedup.bam \
        M=dedup_metrics.txt &&

        java -jar /app/picard.jar \
        BuildBamIndex \
        I=~{sample_name}_dedup.bam \
        O=~{sample_name}_dedup.bam.bai
    >>>

    output {
        File? dedup_bam = "~{sample_name}_dedup.bam"
        File? dedup_metrics = "dedup_metrics.txt"
        File? dedup_bai = "~{sample_name}_dedup.bam.bai"
    }

    runtime {
        docker: "swglh/picard:1.1" # Docker image i've created, will it work, who knows???
        memory: "8 GB" # Check if this is appropriate
        cpu: 2 # Check if this is appropriate
        continueOnReturnCode: true
    }
}