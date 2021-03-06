process kaiju {
      publishDir "${params.output}/${name}/", mode: 'copy', pattern: "${name}.out"
      label 'kaiju'

    input:
      tuple val(name), file(fastq) 
      file(database) 
    
    output:
      tuple val(name), file("${name}.out")
      tuple val(name), file("${name}.out.krona")
    
    shell:
      if (params.fasta) {
      '''
      kaiju -z !{task.cpus} -t !{database}/nodes.dmp -f !{database}/!{database}/kaiju_db_!{database}.fmi -i !{fastq} -o !{name}.out
      kaiju2krona -t !{database}/nodes.dmp -n !{database}/names.dmp -i !{name}.out -o !{name}.out.krona
      '''
      }
      if (params.nano) {
      '''
      kaiju -a greedy -e 5 -z !{task.cpus} -t !{database}/nodes.dmp -f !{database}/!{database}/kaiju_db_!{database}.fmi -i !{fastq} -o !{name}.out
      kaiju2krona -t !{database}/nodes.dmp -n !{database}/names.dmp -i !{name}.out -o !{name}.out.krona
      '''
      }
}

/*
todo: also get lists for the Classified reads!
*/