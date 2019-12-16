process filter_corrected_reads {
      publishDir "${params.output}/${name}/", mode: 'copy', pattern: "${name}.*.filtered.fasta"
      label 'marine_phage_paper_scripts'

    input:
      tuple val(name), file(canu_corrected_reads), file(gsize) 

    output:
      tuple val(name), file("${name}.*.filtered.fasta")

    script:
      """
      GSIZE=\$(cat ${gsize})
      BIN=\$(echo "${gsize}" | sed 's/${name}.//g' | sed 's/.gsize//g')
      gunzip -kf ${canu_corrected_reads}
      filter_reads.py -p ${name}.\${BIN}.filtered ${canu_corrected_reads.baseName} \${GSIZE}
      """
}

/* COMMENTS
# Optional arguments
    parser.add_argument("-p", "--prefix", help="Output file prefix [len_filtered_reads]", type=str, default="len_filtered_reads")
    parser.add_argument("-f", "--len_frac", help="Fraction of genome size to use as min length cutoff [0.9]", type=float, default=0.9)
*/