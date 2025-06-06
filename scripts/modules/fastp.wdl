version 1.1

task fastp {
    input {
        # Input files: read1 and read2
        File read1
        File read2
        String sample_name
        # Do i need a defined output directory OutputDir?
    }

    # Command block for fastp docker
    command <<<
        fastp -i ~{read1} -I ~{read2} -o ~{sample_name}_trimmed_R1.fastq.gz -O ~{sample_name}_trimmed_R2.fastq.gz -h ~{sample_name}_fastp.html -j ~{sample_name}_fastp.json
    >>>

    # Define the output files
    output {
        File? trimmed_read1 = "~{sample_name}_trimmed_R1.fastq.gz"
        File? trimmed_read2 = "~{sample_name}_trimmed_R2.fastq.gz"
        File? ReportHtml = "~{sample_name}_fastp.html"
        File? ReportJson = "~{sample_name}_fastp.json"
    }

    # Specify the Docker image to use for this task
    runtime {
        docker: "mattwherlock/fastp:0.23.2"
        memory: "8 GB"
        cpu: 4
        continueOnReturnCode: true
    }
}