version 1.1

task VcfFilter {
    input {
        File? annotated_vcf
        File vcf_filter_script
        File filter_config
        String sample_name
    }

    command <<<
        bash -c "python3 ~{vcf_filter_script} ~{annotated_vcf} ~{sample_name}_filtered.vcf --config ~{filter_config}"
        true
    >>>

    output {
        File? filtered_vcf = "~{sample_name}_filtered.vcf"
    }

    runtime {
        docker: "swglh/vcf_filter_script:1.2"
        memory: "8 GB"
        cpu: 2
        continueOnReturnCode: true
    }
}