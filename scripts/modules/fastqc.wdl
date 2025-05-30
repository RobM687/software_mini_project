version 1.1

task fastqc {
    input {
        Array[File?] fastq_files
    }
    
    command <<<
        for file in ~{sep=' ' fastq_files}; do
            fastqc $file
        done
        true
    >>>

    output {
        Array[File?] qc_reports = glob("*_fastqc.zip")  # This now includes wildcard '*' to ensure all _fastqc.zip files are captured in the glob
        Array[File?] qc_summaries = glob("*_fastqc.html")  # This now includes wildcard '*' to ensure all _fastqc.html files are captured in the glob
    }

    runtime {
        docker: "swglh/fastqc:v0.11.9"
        memory: "4G"
        cpu: 2
        continueOnReturnCode: true
    }
}