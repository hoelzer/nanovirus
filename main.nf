#!/usr/bin/env nextflow
nextflow.preview.dsl=2

/*
* Nextflow -- Virus Analysis Pipeline for Nanopore data
* Author: hoelzer.martin@gmail.com
*/

/************************** 
* Help messages & user inputs & checks
**************************/

/* Comment section:
First part is a terminal print for additional user information, followed by some help statements (e.g. missing input)
Second part is file channel input. This allows via --list to alter the input of --nano & --illumina to
add csv instead. name,path   or name,pathR1,pathR2 in case of illumina
*/

    // terminal prints
        println " "
        println "\u001B[32mProfile: $workflow.profile\033[0m"
        println " "
        println "\033[2mCurrent User: $workflow.userName"
        println "Nextflow-version: $nextflow.version"
        println "Starting time: $nextflow.timestamp"
        println "Workdir location:"
        println "  $workflow.workDir\u001B[0m"
        println " "
        if (workflow.profile == 'standard') {
        println "\033[2mCPUs to use: $params.cores"
        println "Output dir name: $params.output\u001B[0m"
        println " "}

        if (params.help) { exit 0, helpMSG() }
        if (params.profile) {
            exit 1, "--profile is WRONG use -profile" }
        if (params.nano == '' &&  params.fasta == '' ) {
            exit 1, "input missing, use [--nano] or [--fasta]"}

/************************** 
* INPUT CHANNELS 
**************************/

    // nanopore reads input & --list support
        if (params.nano && params.list) { nano_input_ch = Channel
                .fromPath( params.nano, checkIfExists: true )
                .splitCsv()
                .map { row -> ["${row[0]}", file("${row[1]}")] }
                .view() }
        else if (params.nano) { nano_input_ch = Channel
                .fromPath( params.nano, checkIfExists: true)
                .map { file -> tuple(file.simpleName, file) }
                .view() }

    // direct fasta input for test & --list support
        if (params.fasta && params.list) { fasta_input_ch = Channel
                .fromPath( params.fasta, checkIfExists: true )
                .splitCsv()
                .map { row -> ["${row[0]}", file("${row[1]}")] }
                .view() }
        else if (params.fasta) { fasta_input_ch = Channel
                .fromPath( params.fasta, checkIfExists: true)
                .map { file -> tuple(file.simpleName, file) }
                .view() }



/************************** 
* MODULES
**************************/

/* Comment section: */

//db
include './modules/kaijuGetDB' params(cloudProcess: params.cloudProcess, cloudDatabase: params.cloudDatabase)

//detection
include './modules/kaiju' params(output: params.output, nano: params.nano, fasta: params.fasta)
include './modules/filter_reads' params(output: params.output)
include './modules/kmerfreq' params(output: params.output)
include './modules/umap' params(output: params.output)
include './modules/hdbscan' params(output: params.output)
include './modules/filter_bins' params(output: params.output)
include './modules/get_reads_per_bin' params(output: params.output)
include './modules/filter_kaiju' params(output: params.output)
include './modules/filter_corrected_reads' params(output: params.output)
include './modules/fastani' params(output: params.output)
include './modules/cluster_ani' params(output: params.output)
include './modules/prodigal' params(output: params.output)

//qc
include './modules/nanoplot' params(output: params.output)
include './modules/filtlong'

//assembly
include './modules/flye' params(output: params.output)
include './modules/canu' params(output: params.output)

//polishing
include './modules/racon' params(output: params.output)
include './modules/medaka' params(output: params.output, model: params.model, assemblydir: params.assemblydir)
include './modules/minimap2'

//visuals
include './modules/krona' params(output: params.output)


/************************** 
* DATABASES
**************************/

/* Comment section:
The Database Section is designed to "auto-get" pre prepared databases.
It is written for local use and cloud use.*/

// TODO: currently I am downloading a smaller refseq db for testing. 
// the final version should use the large db like in the paper
workflow download_kaiju_db {
    main:
    // local storage via storeDir
    if (!params.cloudProcess) { kaijuGetDB(); db = kaijuGetDB.out }
    // cloud storage via db_preload.exists()
    if (params.cloudProcess) {
      db_preload = file("${params.cloudDatabase}/kaiju/nr_euk")
      if (db_preload.exists()) { db = db_preload }
      else  { kaijuGetDB(); db = kaijuGetDB.out } 
    }
  emit: db    
}


/************************** 
* SUB WORKFLOWS
**************************/

/* Comment section:
This sub workflow is based on Beaulaurier et al. 2019, Assembly-free single-molecule nanopore sequencing
recovers complete virus genomes from natural microbial communities. [https://www.biorxiv.org/content/biorxiv/early/2019/04/26/619684.full.pdf]
*/
workflow classify {
    get:    nanopore_reads
            kaiju_db

    main:
        //kaiju
        kaiju(filtlong(nanopore_reads), kaiju_db)

        //add virus classified reads to the read list
        filter_kaiju(kaiju.out[0])

        //krona
        krona(kaiju.out[1])

        //kmer frequencies
        //TODO run this in parallel for filter_kaiju.out[0] (cellular) and filter_kaiju.out[1] (noncellular)
        filter_reads(filter_kaiju.out[1].join(filtlong.out))
        kmerfreq(filter_reads.out[0])

        //UMAP
        umap(kmerfreq.out)

        //HDBSCAN
        hdbscan(umap.out)

        //filter bins
        filter_bins(hdbscan.out)

        //generate a fastq for each bin
        get_reads_per_bin_ch = hdbscan.out.join(filter_bins.out).join(filter_reads.out[1])
        get_reads_per_bin(get_reads_per_bin_ch)

        bin(get_reads_per_bin.out[0].transpose())
}


workflow bin {
    get: bins

    main:

        //canu
        canu(bins)
        //canu.out.view()

        //Bandage?

        //filter reads
        filter_corrected_reads(canu.out)

        //FastANI
        fastani(filter_corrected_reads.out)

        //cluster ANI
        cluster_ani(fastani.out)

        polish(cluster_ani.out)
}

workflow polish {
    get: ani

    main:

        //polishing
        //TODO: perform racon 3 times like in the manuscript
        medaka(racon(minimap2(ani)))

        //porechop
        //TODO: the manuscript uses porechop for adapter clipping which is abandoned, some alternative?

        annotate(medaka.out)
}

workflow annotate {
    get: viruses

    main:

        //orf prediction
        prodigal(viruses)

        //find DTR (direct terminal repeats)

}


/************************** 
* WORKFLOW ENTRY POINT
**************************/

/* Comment section: */

workflow {
    if (params.db_kaiju) {
        kaiju_db = file(params.db_kaiju)
    } else {
        download_kaiju_db()
        kaiju_db = download_kaiju_db.out
    }

    // nanopore data
    if (params.nano) { 
        classify(nano_input_ch, kaiju_db)           
    }

}




/*************  
* --help
*************/
def helpMSG() {
    c_green = "\033[0;32m";
    c_reset = "\033[0m";
    c_yellow = "\033[0;33m";
    c_blue = "\033[0;34m";
    c_dim = "\033[2m";
    log.info """
    ____________________________________________________________________________________________
    
    nanovirus
    
    ${c_yellow}Usage example:${c_reset}
    nextflow run main.nf --nano '*/*.fastq' 

    ${c_yellow}Input:${c_reset}
    ${c_green} --nano ${c_reset}              '*.fasta' or '*.fastq.gz'   -> one sample per file
    ${c_green} --fasta ${c_reset}             '*.fasta'                   -> one sample per file, no assembly produced
    ${c_dim}  ..change above input to csv:${c_reset} ${c_green}--list ${c_reset}            

    ${c_yellow}Options:${c_reset}
    --cores             max cores for local use [default: $params.cores]
    --memory            max memory for local use [default: $params.memory]
    --output            name of the result folder [default: $params.output]
    --assemblerLong     long-read assembly tool used [spades, default: $params.assemblerLong]

    ${c_yellow}Parameters:${c_reset}
    --gsize             estimated genome size [default: $params.gsize]
    --kaiju             a kaiju database [default: $params.db_kaiju]

    ${c_yellow}HPC or cloud computing:${c_reset}
    For execution of the workflow in the cloud or on a HPC (such as provided with LSF) 
    you might want to adjust the following parameters.
    --databases         defines the path where databases are stored [default: $params.cloudDatabase]
    --workdir           defines the path where nextflow writes tmp files [default: $params.workdir]
    --cachedir          defines the path where images (singularity) are cached [default: $params.cachedir] 

    ${c_dim}Nextflow options:
    -with-report rep.html    cpu / ram usage (may cause errors)
    -with-dag chart.html     generates a flowchart for the process tree
    -with-timeline time.html timeline (may cause errors)

    Profile:
    -profile                 standard, lsf, ebi, googlegenomics [default: standard] ${c_reset}
    """.stripIndent()
}