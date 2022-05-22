# OSU-Salary-Analysis

This is an ongoing project, so let me know if there are things you'd like to see improved. 

### Notes, Issues, and Concerns

- as discussed in `parse_process.pdf`, many faculty have multiple entries in the PDF file to match each of their different positions within the university. The parser creates a different observation for each of these positions; but, it is still unclear how to best account for them (i.e. how to avoid double-counting somebody) 

- documentation for the original salary report PDFs is slim. Details have been included below (and an additional copy is located in `_data_unclassifieds > unclassified_defns.txt`)

- Does the "Annual Salary Rate" reflect exactly what a person makes in a year? Or has it been scaled to account for appointment type and/or appointment percent? 
    - currently leaning towards the answer that no scaling/adjustment has been made

### File Contents:

- `analysis.rmd` / `analysis.pdf`
    - code and outputs for all analyses performed thus far 
    - not well documented at this point
- `salary_pdf_parser.r`
    - a script for scraping the information from the original OSU salary report PDF files
- `parse_process.rmd` / `parse_process.pdf`
    - documentation for the `parse_salaries_all_years()` function located within the `salary_pdf_parser.r` script 
- `_Unclassifieds_All_Years.rds`
    - a final result of the `salary_pdf_parser.r` script
    - load into your environment using `readRDS("_Unclassifieds_All_Years.rds")`
    - use this in your analysis unless you want to tinker directly with the parser
- `_Unclassifieds_All_Years.csv`
    - a final result of the `salary_pdf_parser.r` script
    - ONLY use this file for viewing in excel / outside of R. Loading this .csv will give you issues since the `write.csv()` function does not preserve typings 

### Data Description (from OSU HR website, verbatim)

- ADJ SERVICE DATE:
    - For classified employees, this is the initial date of employment into a classified or unclassified position with OUS. If the employee was employed by OUS or another state agency in a classified position prior to July 1, 1996, this date reflects prior state service.
- ANNUAL SALARY RATE:
    - This is the salary equivalent of this job at full time (100% appointment).
- APPT BASIS:
    - The number of months on the appointment that the employee will work during a full year.
- APPT BEGIN DATE:
    - The date the job originally started. This date is not changed when a job is reactivated after summer leave
- APPT END DATE:
    - The date the job is scheduled to end.  If null, the job is indefinite.
- APPT PERCENT:
    - Indicates the percentage of full time the position uses
- FIRST HIRED:
    - The date the employee first started with OSU in any position.
- HOME ORGN:
    - The organization code associated with the department the employee reports to.  If the employee has more than one job the Home Org is the org associated with the job which provides the highest level of benefits and leave eligibility.
- JOB ORGN:
    - Organization code to which this job reports; the department responsible for time or - leave entry on this job
- JOB TITLE:
    - For classified employees job title reflects the position class title.  For unclassified employees this reflects the working title.
- JOB TYPE:
    - Job type coded as P (primary), S (secondary) and O (overload).
- RANK:
    - Descriptive title associated with the Faculty Rank Code. Example: Professor
- RANK EFFECTIVE DATE:
    - The date the faculty member achieved the current rank
    
    