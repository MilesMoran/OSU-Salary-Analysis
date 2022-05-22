################################################################################
################################################################################
################################################################################

require(tidyverse)
require(magrittr)  # includes pipe-operator-friendly aliases for r operators 
require(lubridate) # useful for the date-type variables
require(pdftools)  # needed to scrape the unaltered PDF documents

################################################################################

define_utility_variables <- function() {

    ############################################################################
    #' This function defines several variables used by the 
    #' parse_salaries_single_year() function.
    #' 
    #' @return *vars (list)* contains
    #'   *employee.dlms (character):* 
    #'       a regex pattern for separating the variables when they are stored 
    #'       in plaintext format
    #'   *employee.names (character[]):* 
    #'       shortened versions of the variable names seen in 'employee.dlms' 
    #'       (used to define the columns of the final data.frame object)
    #'       Note: the names are repeated 4 times to accommodate faculty listed 
    #'             as having 2, 3, or 4 positions (see parse_process.pdf)
    #'   *names.numeric (character[]):* 
    #'       names for the columns to be converted to numeric 
    #'   *names.dmy (character[]):* 
    #'       names for the columns to be converted to dmy 
    #'   *names.factor (character[]):* 
    #'       names for the columns to be converted to factor
    #'   *header.regex (character):*
    #'       a regex pattern for removing the header present on each page
    #'   *footer.regex (character):* 
    #'       a regex pattern for removing the footer present on the /last/ page
    #'   *salary.regex (character):*
    #'       a regex pattern for separating the salary information to two parts 
    #'       (one for salary $, and one for appointment type (9mo or 12mo))
    ############################################################################

    vars <- list()
    
    vars$employee.dlms <- paste(
        "(Name:)|(First Hired:)|(Home Orgn:)|(Adj Service Date:)|(Job Orgn:)",
        "(Job Type:)|(Job Title:)|(Posn-Suff:)|(Rank:)|(Rank Effective Date:)",
        "(Appt Begin Date:)|(Appt Percent:)|(Appt End Date:)",
        "(Annual Salary Rate:)", 
        sep="|"
    )
    vars$employee.names <- c(
        "Name",         "FirstHired", "HomeOrgn",   "AdjServiceDate","JobOrgn",     
        "JobType",      "JobTitle",   "PosnSuff",   "Rank", "RankEffDate",    
        "ApptBeginDate","ApptPercent","ApptEndDate", 
        "AnnSalary"
    ) %>% c(
        str_replace(.[5:14], "(.*)", "\\1\\_2"),
        str_replace(.[5:14], "(.*)", "\\1\\_3"),
        str_replace(.[5:14], "(.*)", "\\1\\_4")
    )
    
    vars$names.numeric <- c("ApptPercent", "AnnSalary")
    vars$names.dmy     <- c("FirstHired", "AdjServiceDate", "RankEffDate",
                            "ApptBeginDate", "ApptEndDate", "ReportDate")
    vars$names.factor  <- c("HomeOrgn", "JobOrgn", "JobType", "JobTitle",
                            "PosnSuff", "Rank", "ApptType")
    
    vars$header.regex <- "(PHR0210).*(Page)\\s*\\d+"
    vars$footer.regex <- "\\d+\\s*(rows selected.)"
    vars$salary.regex <- "(\\d+\\.\\d\\d)?\\s?(\\d\\d?)?"   

    ### Note that `tidyr::extract` is masked by `magrittr::extract`
    vars$extract_col <- tidyr::extract
    
    return(vars)   
}

################################################################################

parse_salaries_single_year <- function(fname, vars=NULL) {

    ############################################################################
    #' This function scrapes an OSU Salary Report .PDF file and turns the 
    #' contents into a nice data.frame object. The parsing process is a bit
    #' complicated, so see the "parse_process.pdf" file for more details
    #' 
    #' @param *fname (character):* 
    #'     the name of the PDF file to scrape
    #' @return *employees (data.frame):* 
    #'     the information contained in the PDF, scraped and returned in a 
    #'     usable data.frame format
    ############################################################################

    if(is.null(vars)) { vars <- define_utility_variables() }
    list2env(vars, envir = environment())

    names.default <- list() 
    names.default[paste0("X", 1:44)] <- ""
    
    report.date <- (
        pdf_text(fname)
        %>% extract(1)
        %>% str_extract("^.*\\n")
        %>% str_extract("\\d{2}\\-\\w{3}\\-\\d{4}")
    )
        
    employees <- (
        pdf_text(fname)                               # 1(a)
            %>% paste0(collapse=" ")                  #   1(b)
            %>% str_replace_all(header.regex, " ")    #   2(a)
            %>% str_replace_all(footer.regex, " ")    #   2(b)
            %>% str_squish()                          #   2(c)
        %>% str_split("\u002D{81}")                   # 3(a)
            %>% extract2(1)                           #   3(b)
            %>% extract(-1)                           #   3(c)
        %>% str_split(employee.dlms, simplify=TRUE)   # 4(a)
            %>% apply(2, str_trim, simplify=TRUE)     #   4(b)
            %>% extract(,-1)                          #   4(c)
        %>% data.frame()                              # 5(a)
            %>% add_column( ### add columns if they don't exist (so always 44 total)
                    !!!names.default[!names(names.default) %in% names(.)]
                )                                
            %>% set_colnames(employee.names)           #   5(b)
            %>% bind_rows(
                    filter(., JobOrgn_2 != "") %>% select(c(1:4, 15:24)),
                    filter(., JobOrgn_3 != "") %>% select(c(1:4, 25:34)),
                    filter(., JobOrgn_4 != "") %>% select(c(1:4, 35:44))
            )                                     # 6(a)
            %>% select(1:14)                          #   6(b)
            %>% extract_col(
                    AnnSalary,
                    c("AnnSalary", "ApptType"),
                    salary.regex
            )                                     # 7(a) 
            %>% separate(
                    Name, 
                    c("LastName", "FirstName"), 
                    sep="\\,\\s",
                    extra="merge")                                      # 7(b) 
            %>% add_column(ReportDate=report.date)                      # 
            %>% filter(!if_any(everything(), str_detect, "\\*"))        # 7(c)
        %>% mutate(                                               # 7(d)
                across(all_of(names.numeric), as.numeric),
                across(all_of(names.dmy),     dmy),
                across(all_of(names.factor),  as.factor)
            )
    )
    
    return(employees)
} 

################################################################################

parse_salaries_all_years <- function(fnames) {

    ############################################################################
    #' This function is just an easy way to call parse_salaries_single_year()
    #' for a series of salary report PDFs.
    #' 
    #' Note: the final result is returned to the caller, instead of being 
    #'       saved into memory. If you would like to save the object, I
    #'       recommend using 'save()' with a .rdata filetype in order to 
    #'       preseve typings (as opposed to, say, 'read.csv()')
    #' 
    #' @param *fnames (character[]):* 
    #'     the vector of names of the PDF files to scrape
    #' @return *(unnamed) (data.frame):*
    #'     the final result of the PDF scraping. Should contain 17 columns.
    ############################################################################
    
    vars <- define_utility_variables()

    (
    fnames 
    %>% lapply(parse_salaries_single_year, vars)
    %>% bind_rows()
    %>% return()
    )
}

################################################################################
################################################################################
################################################################################

