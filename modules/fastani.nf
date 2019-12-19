process fastani {
      publishDir "${params.output}/${name}/", mode: 'copy', pattern: "${name}.fastani.out"
      label 'fastani'

    input:
      tuple val(name), file(fasta) 
    
    output:
      tuple val(name), file("${name}.fastani.out")
    
    shell:
    """
      fastANI -q ${fasta} -r ${fasta} --fragLen=1500 --minFraction=0.1 -k 10 -o ${name}.fastani.out
    """
}

/*
TODO: I am not sure if this is the correct call. Should I use --ql and --rl? see
https://github.com/ParBLiSS/FastANI
Most likely I want to have a pairwise comparison of each read with each read in one fasta bin?
and then cut the results together in one file and give this to the cluster_ani.py script
*/