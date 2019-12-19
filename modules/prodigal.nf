/*Comment section: */

process prodigal {
  label 'prodigal'  
  publishDir "${params.output}/${dir}/prodigal/", mode: 'copy', pattern: "${name}.faa"

  input:
    tuple val(dir), val(name), file(genome)

  output:
    tuple val(dir), val(name), file("${name}.faa")

  script:
    """
    prodigal -i ${genome} -f gff -a ${name}.faa > /dev/null 2> ${name}.log
    """
}
