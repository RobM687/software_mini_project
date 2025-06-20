version 1.1

task bwamem2 {
    #this block of code was quite a faff to build, initially only defining the reference.fa, ulitmately had to define each reference/index required so WDL can identifiy it when needed
    input {
        File reference_fa   #reference genome FASTA
        File reference_fabwt2bit64  #BWA-MEM2 index file, used implicitly
        File reference_faann    #reference genome annotation, used implicitly
        File reference_faamb    #BWA-MEM2 index file, used implicitly
        File reference_fapac    #BWA-MEM2 index file, used implicitly
        File reference_fa0123   #BWA-MEM2 index file, used implicitly
        File? read1
        File? read2
        String sample_name
    }

    command <<<
        #this is linked to the block above, it forces the WDL code to recognise the additional reference/index files. The && means the next step in the code cannot proced unless the rpevious has completed successfully 
        #this ensures that the reference files actually exists
        touch reference_fabwt2bit64 &&
        touch reference_faann &&
        touch reference_faamb &&
        touch reference_fapac &&
        touch reference_fa0123 &&
        #code to run bwa-mem2 aligner, will use index file already present in file
        bwa-mem2 mem \
        -R $(echo "@RG\tID:~{sample_name}\tSM:~{sample_name}\tPL:ILLUMINA\tLB:~{sample_name}") \
        ~{reference_fa} \
        ~{read1} ~{read2} | \

        #convert SAM to BAM
        samtools view -Sb - | \

        #Sort bam file
        samtools sort -o ~{sample_name}_sorted.bam
    >>>

    output {
        File? alignedBam = "~{sample_name}_sorted.bam"
    }

    runtime {
        docker: "swglh/bwamem2:v2.2.1"
        memory: "60 GB"
        cpu: 16
        continueOnReturnCode: true
    }
}