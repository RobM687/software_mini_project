version 1.1

task RemoveDuplicates {
    input {
        File? alignedBam
        File? alignedBai
        String sample_name
    }

    command <<<
        java -jar /app/picard.jar \
        MarkDuplicates \
        I=~{alignedBam} \
        O=~{sample_name}_dedup.bam \
        M=dedup_metrics.txt
    >>>

    output {
        File? dedup_bam = "~{sample_name}_dedup.bam"
        File? dedup_metrics = "dedup_metrics.txt"
    }

    runtime {
        docker: "swglh/picard:1.1" # Docker image i've created, will it work, who knows???
        memory: "4 GB" # Check if this is appropriate
        cpu: 2 # Check if this is appropriate

    }
}

task IndexDedupBam {
    input {
        File? dedup_bam
    }

    command <<<
        java -jar /app/picard.jar \
        BuildBamIndex \
        I=~{dedup_bam} \
        O=~{dedup_bam}.bai
        true
    >>>

    output {
        File? dedup_bai = "~{dedup_bam}.bai"
    }

    runtime {
        docker: "swglh/picard:1.1" # Docker image i've created, will it work, who knows???
        memory: "8 GB" # Check if this is appropriate
        cpu: 2 # Check if this is appropriate
        continueOnReturnCode: true
    }
}