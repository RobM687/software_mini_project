version 1.0

task fastqc {
    input {
        Array[File] fastq_files
        File read1  # This is just being used to establish the output file names, the fastqc task is run on all fastq files named in the fastq_files array
    }

    String outputName = sub(basename(read1), "_R1_001\\.fastq.gz$", "")

    command <<<
        for file in ~{sep=' ' fastq_files}; do
            fastqc $file
        done
    >>>

    output {
        Array[File?] qc_reports = glob("*_fastqc.zip")  # This now includes wildcard '*' to ensure all _fastqc.zip files are captured in the glob
        Array[File?] qc_summaries = glob("*_fastqc.html")  # This now includes wildcard '*' to ensure all _fastqc.html files are captured in the glob
    }

    runtime {
        docker: "swglh/fastqc:v0.11.9"
        memory: "4G"
        cpu: 2
    }
}