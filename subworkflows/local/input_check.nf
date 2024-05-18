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

    // 2. Parse samplesheet depending
        
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
    
    emit:
    sample_map
    samplesheet_utf8
    // versions = SAMPLESHEET_CHECK.out.versions // channel: [ versions.yml ]
}
