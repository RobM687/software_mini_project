version 1.0

task vep {
    input {
        File vep_tar
        File vcf
        File reference_fa
        String cache_version
        Int fork
    }

    String outputName = sub(basename(vcf), ".vcf$", "")

    command <<<
        #copying and unpacking vep tar file/cache
        cp ~{vep_tar} .
        tar -zxvf ~{basename(vep_tar)}
        
        #running vep
        vep \
        --vcf \
        --no_stats \
        -i ~{vcf} \
        -o ~{outputName}_annotated.vcf \
        --assembly GRCh38 \
        --refseq \
        --offline \
        --cache \
        --dir_cache . \
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
        File annotated_vcf = "~{outputName}_annotated.vcf"
    }

    runtime {
        docker: "swglh/ensembl-vep:86"
        memory: "16G"
        cpu: 16
    }
}