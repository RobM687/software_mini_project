version 1.0

task fastp {
    input {
        # Input files: read1 and read2
        File read1
        File read2
        # Do i need a defined output directory OutputDir?
    }

    # Derive the output name from read1 by removing the '_R1_001.fastq.gz' suffix
    String outputName = sub(basename(read1), "_R1_001\\.fastq.gz$", "")

    # Command block for fastp docker
    command <<<
        fastp -i ~{read1} -I ~{read2} -o ~{outputName}_trimmed_R1.fastq.gz -O ~{outputName}_trimmed_R2.fastq.gz -h ~{outputName}_fastp.html -j ~{outputName}_fastp.json
    >>>

    # Define the output files
    output {
        File? trimmed_read1 = "~{outputName}_trimmed_R1.fastq.gz"
        File? trimmed_read2 = "~{outputName}_trimmed_R2.fastq.gz"
        File? ReportHtml = "~{outputName}_fastp.html"
        File? ReportJson = "~{outputName}_fastp.json"
    }

    # Specify the Docker image to use for this task
    runtime {
        docker: "mattwherlock/fastp:0.23.2"
    }
}