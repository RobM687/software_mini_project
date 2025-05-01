version 1.0

task VcfFilter {
    input {
        File annotated_vcf
    }

    String outputName = sub(basename(annotated_vcf), "_annotated\\.vcf$", "")

    command <<<
        python3 vcf_filter_script.py ~{annotated_vcf} ~{outputName}_filtered.vcf
    >>>

    output {
        File filtered_vcf = "~{outputName}_filtered.vcf"
    }

    runtime {
        docker: "swglh/vcf_filter_script:1.1"
        memory: "4 GB"
        cpu: 2
    }
}