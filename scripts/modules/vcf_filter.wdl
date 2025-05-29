version 1.0

task VcfFilter {
    input {
        File? annotated_vcf
        File vcf_filter_script
        File filter_config
    }

    String outputName = sub(basename(annotated_vcf), "_annotated\\.vcf$", "")

    command <<<
        bash -c "python3 ~{vcf_filter_script} ~{annotated_vcf} ~{outputName}_filtered.vcf --config ~{filter_config}"
    >>>

    output {
        File? filtered_vcf = "~{outputName}_filtered.vcf"
    }

    runtime {
        docker: "swglh/vcf_filter_script:1.2"
        memory: "4 GB"
        cpu: 2
    }
}