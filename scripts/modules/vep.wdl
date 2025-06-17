version 1.1

task vep {
    input {
        File vep_tar
        File? vcf
        File reference_fa
        String cache_version
        Int fork
        String sample_name
    }

    command <<<
        # Copying and unpacking vep tar file/cache
        cp ~{vep_tar} .
        tar --no-same-owner -zxvf ~{basename(vep_tar)}

        # Changing permissions of files to ensure all are readable and executable if needed
        chmod -R a+rX .

        # Running vep
        vep \
        --vcf \
        --no_stats \
        -i ~{vcf} \
        -o ~{sample_name}_annotated.vcf \
        --assembly GRCh38 \
        --refseq \
        --offline \
        --cache \
        --dir_cache ./homo_sapiens_merged \
        --plugin_dir ./Plugins \
        --cache_version ~{cache_version} \
        --fork ~{fork} \
        --fasta ~{reference_fa} \
        --exclude_predicted \
        --everything \
        --hgvsg \
        --show_ref_allele \
        --uploaded_allele \
        --check_existing \
        --transcript_version
    >>>

    output {
        File? annotated_vcf = "~{sample_name}_annotated.vcf"
    }

    runtime {
        docker: "swglh/ensembl-vep:86"
        memory: "16G"
        cpu: 16
        continueOnReturnCode: true
    }
}