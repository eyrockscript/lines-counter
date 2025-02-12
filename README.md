
lines-counter
=============

A bash script to recursively count lines of code in files and directories, generating detailed reports in either TXT or CSV format.

Features
--------

*   Recursive file scanning
*   Configurable file/directory ignoring
*   Progress bar visualization
*   Multiple output formats (TXT/CSV)
*   Detailed reports by directory and file type
*   Support for custom ignore patterns
*   Debug mode for troubleshooting

Installation
------------

1.  Download the script:
    
        curl -O https://raw.githubusercontent.com/yourusername/lines-counter/main/count_lines.sh
    
2.  Make it executable:
    
        chmod +x count_lines.sh
    

Usage
-----

### Basic Usage

Count lines in current directory:

    ./count_lines.sh

Count lines in a specific directory:

    ./count_lines.sh /path/to/directory

Generate CSV report (experimental):

    ./count_lines.sh /path/to/directory csv

Debug mode:

    DEBUG=1 ./count_lines.sh /path/to/directory

### Ignoring Files (experimental)

Create a `.countignore` file in the target directory to specify patterns to ignore. Example:

    # Ignore node_modules directory
    node_modules/*
    
    # Ignore all log files
    *.log
    
    # Ignore dist directory
    dist/*
    
    # Ignore test specs
    test/*.spec.js

Output Format
-------------

### TXT Output (Default)

    CODE LINES COUNT REPORT
    Date: Wed Feb 12 10:30:15 EST 2025
    ----------------------------------------
    
    FILE DETAILS BY DIRECTORY:
    ----------------------------------------
    
    /your/project/src/
    main.js                            150 lines
    utils.js                            80 lines
    
    SUMMARY BY FILE TYPE:
    ----------------------------------------
    js                      1500 lines in   12 files
    py                      1200 lines in    8 files
    
    GENERAL SUMMARY:
    ----------------------------------------
    Total lines: 2700
    Total files: 20

### CSV Output

    Directory,File,Lines
    /your/project/src/,main.js,150
    /your/project/src/,utils.js,80
    ...
    
    EXTENSION SUMMARY
    Extension,Total Lines,File Count
    js,1500,12
    py,1200,8

Features Explained
------------------

*   **Directory Traversal:** Recursively scans all subdirectories
*   **Ignore Patterns:** Supports glob-style patterns in `.countignore`
*   **Progress Bar:** Shows real-time progress during analysis
*   **Multiple Formats:** Choose between human-readable (TXT) or machine-parseable (CSV) output
*   **Detailed Reports:**
    *   File-by-file breakdown
    *   Summary by file type
    *   Total line counts
    *   Total file counts

Debug Mode
----------

Run with `DEBUG=1` to see detailed information about:

*   Files being processed
*   Ignore patterns being applied
*   Pattern matching results

Notes
-----

*   Hidden files (starting with .) are ignored by default
*   Empty lines are not counted
*   The report is generated in the current directory
*   The script requires bash and common Unix utilities (find, grep, awk)

Contributing
------------

Feel free to submit issues and enhancement requests!
