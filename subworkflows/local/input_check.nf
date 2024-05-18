//
// Check input samplesheet and get read channels
//

include { SAMPLESHEET_CHECK } from '../../modules/local/samplesheet_check'

workflow INPUT_CHECK {
    take:
    samplesheet

    main:

    // 1. run samplesheet_check (same for all entrypoints)
    SAMPLESHEET_CHECK( samplesheet )
        .samplesheet_utf8
        .set { samplesheet_utf8 }

    // 2. Identify pipeline entrypoint (-entry [bulk,sc,spatial])
    def cmdline = "$workflow.commandLine"
    def entrystring = (cmdline =~ /-entry (\w+)/)
    def entry = entrystring[0][1]

    // 3. Parse samplesheet depending on -entry value [bulk,sc,spatial]
    if (entry == 'bulk') {
        
        samplesheet_utf8
            .splitCsv(header: true, sep: ',')
            .map { row -> 
                meta_map = [row.sample , row.subject_id]
                row.each { key, value ->
                    if (key != 'sample' && key != 'subject_id') {
                        meta_map << value
                    }
                }
                [meta_map, file(row.file)]}
            .set { sample_map }

    } else if (entry == 'sc') {

        samplesheet_utf8
            .splitCsv(header: true, sep: ',')
            .map { row -> 
                meta_map = [row.sample]
                row.each { key, value ->
                    if (key != 'sample') {
                        meta_map << value
                    }
                }
                [meta_map, file(row.files)]
            }
            .set { sample_map }
            
    } else if (entry == 'spatial') {
        // println '-- Spatial entrypoint'
        samplesheet_utf8
            .splitCsv(header: true, sep: ',')
            .map { row -> 
                meta = [:]
                row.each { column, value ->
                    if (value) {
                        meta[column] = value
                    }
                }
                [meta, file(row.path_reads), file(row.path_image)]
                // def paths = ['path_image', 'path_cytaimage', 'path_darkimage', 'path_colorizedimage', 'path_alignment', 'path_slidefile']
                // paths.each { path ->
                //     files << file(row[path])
                // }
                // files
            }
            .set { sample_map }
    } else {
        error 'Invalid entrypoint'
    }
    
    emit:
    sample_map
    samplesheet_utf8
    // versions = SAMPLESHEET_CHECK.out.versions // channel: [ versions.yml ]
}
