
# IMAGE-metadata

[IMAGE](http://www.imageh2020.eu/) (Innovative Management of Animal Genetic Resources) is a EU project with aims to enhance the use of genetic collections and to upgrade animal gene bank management. To achieve this goal, a well-defined data structure is the key to maintain the high quality of collected data and make them more re-usable. This repository contains two rule sets for sample and experiment to which all IMAGE samples will be standardised against.
The ruleset contains a number of fields that will be collected by the IMAGE ingest tool on submission (for example your contact details) or created for your sample automatically (for example a unique BioSample ID). 
# File organization

 * README.md this document which briefly describes this repository
 * **docs**  folder   
   the main documents to view the rulesets: 
     * MD files: to view on the website
     * PDF files : a downloadable version
 * **rulesets** folder   
   The folder contains current rulesets files. For each ruleset, we have provided three versions of the same ruleset: 
     * Markdown document: the same one as in the **docs** folder with a different file name
     * Tab-delimited text file: a more detailed spreadsheet with additional notes and examples for some fields
     * JSON file: for developers who want to programmatically operate on the ruleset content. 
 * **scripts** folder   
   the scripts used to convert among different file formats
 