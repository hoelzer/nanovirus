process racon {
      publishDir "${params.output}/${name}/", mode: 'copy', pattern: "${name}_consensus.fasta"
      label 'racon'
   input:
      tuple val(name), file(read), file(assembly), file(mapping) 
   output:
   	tuple val(name), file(read), file("${name}_consensus.fasta") 
   shell:
      """
      racon --include-unpolished --quality-threshold=9 -t ${task.cpus} ${read} ${mapping} ${assembly} > ${name}_consensus.fasta
      """
  }

  /*
  run three times
  */