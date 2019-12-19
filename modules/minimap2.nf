process minimap2 {
  publishDir "${params.output}/${name}/", mode: 'copy', pattern: "${name}.paf"
  label 'minimap2'
      input:
  	    tuple val(name), file(read), file(assembly) 
      output:
        tuple val(name), file(read), file(assembly), file("${name}.paf") 
      script:
        """
      	minimap2 -x map-ont -t ${task.cpus} ${assembly} ${read} > ${name}.paf
        """
      }