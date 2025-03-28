#!/bin/bash
#SBATCH --job-name=RNA-seq
#SBATCH --mem-per-cpu=16G
#SBATCH --cpus-per-task=6
#SBATCH --export=ALL
#SBATCH -p short

set -e  # stop on error

# ----------------------
# preparation
# ----------------------

# activate conda environment
source ~/.bashrc
conda activate rnaseq

# ----------------------
# read comparison name
# ----------------------

COMPARISON=$1

if [ -z "$COMPARISON" ]; then
   echo "usage: sbatch pipeline.sh COMPARISON_NAME"
   echo "example: sbatch pipeline.sh KOvsNT"
   exit 1
fi

echo "starting pipeline for: ${COMPARISON}"

# ----------------------
# reference files
# ----------------------

GENOME_DIR="/ref_genome/star-index"
GTF_FILE="/ref_genome/gtf/gencode.v46.annotation.gtf"
RSEM_INDEX="/ref_genome/rsem_hg38_gencode46/rsem_hg38_gencode46"
THREADS=6

# ----------------------
# load sample list
# ----------------------

SAMPLES_FILE="${COMPARISON}_samples.txt"

if [ ! -f "$SAMPLES_FILE" ]; then
    echo "sample file ${SAMPLES_FILE} not found!"
    exit 1
fi

samples=($(cat ${SAMPLES_FILE}))
echo "loaded ${#samples[@]} samples"

# ----------------------
# create output folders
# ----------------------

mkdir -p results/fastp results/star results/rsem logs

# ----------------------
# fastp
# ----------------------

echo "running fastp"

for sample in "${samples[@]}"; do
    R1=$(ls ${sample}_S*_R1_001.fastq.gz)
    R2=$(ls ${sample}_S*_R2_001.fastq.gz)

    fastp -i ${R1} \
          -I ${R2} \
          -o results/fastp/${sample}_R1.fq.gz \
          -O results/fastp/${sample}_R2.fq.gz \
          -w $THREADS -h results/fastp/${sample}.html \
          > logs/${sample}_fastp.log 2>&1
done
echo "fastp completed"

# ----------------------
# STAR
# ----------------------

echo "running STAR"

for sample in "${samples[@]}"; do
    mkdir -p results/star/${sample}
    STAR --genomeDir $GENOME_DIR \
         --runThreadN $THREADS \
         --readFilesIn results/fastp/${sample}_R1.fq.gz results/fastp/${sample}_R2.fq.gz \
         --readFilesCommand zcat \
         --sjdbGTFfile $GTF_FILE \
         --quantMode TranscriptomeSAM \
         --outSAMtype BAM SortedByCoordinate \
         --outFileNamePrefix results/star/${sample}/ \
         > logs/${sample}_STAR.log 2>&1
done
echo "STAR completed"

# ----------------------
# RSEM
# ----------------------

echo "running RSEM"

for sample in "${samples[@]}"; do
    mkdir -p results/rsem/${sample}
    rsem-calculate-expression --alignments --paired-end -p $THREADS \
        results/star/${sample}/Aligned.toTranscriptome.out.bam \
        $RSEM_INDEX \
        results/rsem/${sample}/${sample} \
        > logs/${sample}_RSEM.log 2>&1
done
echo "RSEM completed"

# ----------------------
# ready for differential analysis
# ----------------------

echo "all processing finished for ${COMPARISON}"
echo "you can now run your R analysis"

echo "pipeline finished at: $(date)"
