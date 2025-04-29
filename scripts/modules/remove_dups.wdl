version 1.0

task RemoveDuplicates {
    input {
        File alignedBam
        File alignedBai
    }

     # Derive the output name from alignedBam by removing the '_sorted.bam' suffix
    String outputName = sub(basename(alignedBam), "_sorted\\.bam$", "")

    command <<<
        java -jar /app/picard.jar \
        MarkDuplicates \
        I=~{alignedBam} \
        O=~{outputName}_dedup.bam \
        M=dedup_metrics.txt
    >>>

    output {
        File dedup_bam = "~{outputName}_dedup.bam"
        File dedup_metrics = "dedup_metrics.txt"
    }

    runtime {
        docker: "swglh/picard:1.1" # Docker image i've created, will it work, who knows???
        memory: "4 GB" # Check if this is appropriate
        cpu: 2 # Check if this is appropriate

    }
}

task IndexDedupBam {
    input {
        File dedup_bam
    }

    # Derive the output name from read1 by removing the '_dedup.bam' suffix
    String outputName = sub(basename(dedup_bam), "_dedup\\.bam$", "")

    command <<<
        java -jar /app/picard.jar \
        BuildBamIndex \
        I=~{dedup_bam} \
        O=~{dedup_bam}.bai
    >>>

    output {
        File dedup_bai = "~{dedup_bam}.bai"
    }

    runtime {
        docker: "swglh/picard:1.1" # Docker image i've created, will it work, who knows???
        memory: "2 GB" # Check if this is appropriate
        cpu: 1 # Check if this is appropriate
    }
}