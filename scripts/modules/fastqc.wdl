version 1.1

task fastqc {
    input {
        Array[File?] fastq_files
    }
    
    command <<<
        mkdir -p fastqc_output

        for file in ~{sep(" ", select_all(fastq_files))}; do  # This line removes all the null entries (missing /corrupt fastqs) from fastq_files, sep() then separates these into a list of files to be fed into fastqc command.
            fastqc -o fastqc_output $file
        done
    >>>

    output {
        Array[File?] qc_reports = glob("fastqc_output/*_fastqc.zip")  # This now includes wildcard '*' to ensure all _fastqc.zip files are captured in the glob
        Array[File?] qc_summaries = glob("fastqc_output/*_fastqc.html")  # This now includes wildcard '*' to ensure all _fastqc.html files are captured in the glob
    }

    runtime {
        docker: "swglh/fastqc:v0.11.9"
        memory: "4G"
        cpu: 2
    }
}