process kaijuGetDB {
  label 'kaiju'    
  if (params.cloudProcess) { 
    publishDir "${params.cloudDatabase}/kaiju/", mode: 'copy', pattern: "nr_euk" 
  }
  else { 
    storeDir "nextflow-autodownload-databases/kaiju/" 
  }  

  output:
    file("nr_euk")

  script:
    """
    mkdir -p nr_euk
    cd nr_euk

    #wget http://kaiju.binf.ku.dk/database/kaiju_db_nr_euk_2019-06-25.tgz 
    #tar -xvzf kaiju_db_nr_euk_2019-06-25.tgz
    #rm kaiju_db_nr_euk_2019-06-25.tgz

    wget http://kaiju.binf.ku.dk/database/kaiju_index.tgz
    tar -xvzf kaiju_index.tgz
    rm kaiju_index.tgz
    mkdir nr_euk
    mv kaiju_db.fmi nr_euk/kaiju_db_nr_euk.fmi
    """
}


