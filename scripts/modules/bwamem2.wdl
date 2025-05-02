version 1.0

task bwamem2 {
    #this block of code was quite a faff to build, initially only defining the reference.fa, ulitmately had to define each reference/index required so WDL can identifiy it when needed
    input {
        File reference_fa   #reference genome FASTA
        File reference_fabwt2bit64  #BWA-MEM2 index file
        File reference_faann    #reference genome annotation
        File reference_faamb    #BWA-MEM2 index file
        File reference_fapac    #BWA-MEM2 index file
        File reference_fa0123   #BWA-MEM2 index file
        File read1
        File read2
    }

    # Derive the output name from read1 by removing the 'trimmed_R1.fastq.gz' suffix
    String outputName = sub(basename(read1), "_trimmed_R1\\.fastq.gz$", "")

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
        -R $(echo "@RG\tID:~{outputName}\tSM:~{outputName}\tPL:ILLUMINA\tLB:~{outputName}") \
        ~{reference_fa} \
        ~{read1} ~{read2} > ~{outputName}.sam &&

        #convert SAM to BAM
        samtools view -Sb ~{outputName}.sam > ~{outputName}.bam &&

        #Sort bam file
        samtools sort ~{outputName}.bam -o ~{outputName}_sorted.bam &&

        #Index sorted bam file
        samtools index ~{outputName}_sorted.bam
    >>>

    output {
        File alignedBam = "~{outputName}_sorted.bam"
        File alignedBai = "~{outputName}_sorted.bam.bai"
    }

    runtime {
        docker: "swglh/bwamem2:v2.2.1"
    }
}