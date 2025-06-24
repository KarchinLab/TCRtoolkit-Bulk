//
// Check input samplesheet and get read channels
//

include { SAMPLESHEET_CHECK } from '../../modules/local/samplesheet/samplesheet_check'
include { SAMPLESHEET_RESOLVE } from '../../modules/local/samplesheet/samplesheet_resolve'

workflow INPUT_CHECK {
    take:
    samplesheet

    main:

    // 1. run samplesheet_check (same for all entrypoints)
    SAMPLESHEET_CHECK( samplesheet )
        .samplesheet_utf8
        .set { samplesheet_utf8 }

    // 2. Parse samplesheet
    samplesheet_utf8
        .splitCsv(header: true, sep: ',')
        .map { row ->
            def meta = row.findAll { k, v -> k != 'file' }  // everything except the file column
            def file_obj = file(row.file)
            return [meta, file_obj]
        }
        .set { sample_map }
        
    // 3. Write resolved samplesheet with absolute paths
    sample_map
        .map { _, f -> f }
        .collect()
        .set { all_sample_files }
    
    sample_map
        .map { meta, f ->
            def row = (meta.values() + [f.getName()]).join(',')
            return row
        }
        .collect()
        .set { resolved_rows }

    samplesheet_utf8
        .splitCsv(header: true, sep: ',')
        .first()
        .map { row -> 
            def header = row.keySet().findAll { it != 'file' } + ['file']
            return header.join(',')  // <-- convert to string
        }
        .set { resolved_header }

    SAMPLESHEET_RESOLVE(
            resolved_rows,
            resolved_header
        )
        .samplesheet_resolved
        .set { samplesheet_resolved }

    emit:
    sample_map          //input to sample-level analysis
    samplesheet_resolved    //input to comparison analysis
    all_sample_files
    // versions = SAMPLESHEET_CHECK.out.versions // channel: [ versions.yml ]
}
