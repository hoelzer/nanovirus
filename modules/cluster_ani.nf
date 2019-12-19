process cluster_ani {
      publishDir "${params.output}/${name}/", mode: 'copy', pattern: "${name}.*.cluster_ani"
      label 'marine_phage_paper_scripts'

    input:
      tuple val(name), file(ani) 

    output:
      tuple val(name), file("${name}.*.cluster_ani")

    script:
      """
      BIN=\$(echo "${ani}" | sed 's/${name}.//g' | sed 's/.gsize//g')
      cluster_ani.py -p ${name}.\${BIN}.cluster_ani ${ani} \${BIN}
      """
}

/* COMMENTS
    # Optional arguments
    parser.add_argument("-p", "--prefix", help="Output files prefix [ani_clusters]", type=str, default="ani_clusters")
    parser.add_argument("-r", "--min_reads", help="Minimum number of reads in ANI cluster. Polishing with too few reads (e.g. <5) is ineffective. [10]", type=int, default=10)
    parser.add_argument("-s", "--min_sim", help="Minimum average similarity among reads in ANI cluster [0.95]", type=float, default=.95)
    parser.add_argument("-l", "--min_len", help="Minimum average read length in ANI cluster. May help filter out incomplete genome reads. [28000]", type=int, default=28000)
    parser.add_argument("-d", "--max_d", help="Cophenetic distance at which ANI cluster boundaries are drawn [1.0]", type=float, default=1.0)
    parser.add_argument("-m", "--method", help="Method used to calculate distance in hierarchical clustering [ward]", type=str, default="ward")
*/