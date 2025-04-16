configfile: "config1.yaml"

SAMPLES = config["sample"]["single"]
GENOME = "reference_genome/mm10"

rule all:
    input:
        expand("peaks/{sample}_peaks.narrowPeak", sample=SAMPLES)


rule fastqc:
    input:
        "data/{sample}.fastq.gz"
     output:
        html="results/fastqc/{sample}_fastqc.html",
        zip="results/fastqc/{sample}_fastqc.zip"
    threads: 2
    shell:
        "mkdir -p results/fastqc && fastqc -t {threads} {input} --outdir results/fastqc"

rule trim:
    input:
        "data/{sample}.fastq.gz"
    output:
        "trimmed/{sample}.fastq.gz"
    shell:
        "trimmomatic SE -phred33 {input} {output} SLIDINGWINDOW:4:20 MINLEN:25"

rule align:
    input:
        "trimmed/{sample}.fastq.gz"
    output:
        "aligned/{sample}.bam"
    params:
        index="reference_genome/mm10"
    shell:
        "bowtie2 -x {params.index} -U {input} | samtools sort -o {output}"

rule dedup:
    input:
        "aligned/{sample}.bam"
    output:
        "filtered/{sample}_dedup.bam"
    shell:
        "picard MarkDuplicates I={input} O={output} REMOVE_DUPLICATES=true"

rule call_peaks:
    input:
        "filtered/{sample}_dedup.bam"
    output:
        "peaks/{sample}_peaks.narrowPeak"
    shell:
        "macs2 callpeak -t {input} -f BAM -g mm -n {wildcards.sample} --outdir peaks/"



