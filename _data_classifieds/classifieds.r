
library(tidyverse)
library(magrittr)
library(lubridate)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

################################################################################
### Scrape the .txt file to define the data.frame ##############################
################################################################################

employee.dlms <- paste("(Name:)|(First Hired:)|(Home Orgn:)|(Adj Service Date:)",
                       "(Job Orgn:)|(Job Type:)|(Job Title:)|(Posn-Suff:)", 
                       "(Appt Percent:)|(Appt:)|(Full-Time Monthly Salary:)",
                       "(Hourly Rate:)",
                       sep="|")
employee.vars <- c("Name", "FirstHired", "HomeOrgn", "AdjServiceDate",
                   "JobOrgn", "JobType", "JobTitle", "PosnSuff", 
                   "ApptPercent", "Appt", "FullTimeMonthlySalary")

employees <- 
    read_file("classified.txt")     %>%
    str_squish()                    %>%
    str_split("\u002D{81}")         %>%
        extract2(1)                 %>%
        extract(-1)                 %>%
    str_split(employee.dlms, simplify=TRUE) %>%
        apply(2, str_trim, simplify=TRUE)   %>%
        extract(,2:12)              %>%
    data.frame()                    %>%
        set_colnames(employee.vars) %>%
        mutate(FirstHired = dmy(FirstHired),          # to date
               AdjServiceDate = dmy(AdjServiceDate),  # to date
               HomeOrgn = factor(HomeOrgn),  # to factor
               JobOrgn = factor(JobOrgn),    # to factor
               JobType = factor(JobType),    # to factor
               JobTitle = factor(JobTitle),  # to factor
               Appt = factor(Appt),          # to factor
               ApptPercent = as.integer(ApptPercent), # to integer
               FullTimeMonthlySalary = as.numeric(FullTimeMonthlySalary) # to num
               )                    %>% 
        drop_na()

rm(employee.dlms)
rm(employee.vars)

################################################################################
### Fix the "FullTimeMonthlySalary" variable
################################################################################

x <- seq(0,1,0.001)
employees %>%
    use_series(FullTimeMonthlySalary) %>%
    sort() %>% 
    diff() %>%
    which.max()
employees %>% 
    use_series(FullTimeMonthlySalary) %>%
    sort() %>% 
    extract(c(570,571))

### based on an 8-hour workday with 22 workdays in a month ###
### i.e. 8*22 = 176 work-hours in a month ###

### unknown::: is FullTimeMonthlySalary already adjusted for ApptPercent? 
###            or is it based on the assumption ApptPercent == 100?

employees <-
    employees %>% 
    mutate(ApptProp = ApptPercent / 100,
           HourlyRate = ifelse(FullTimeMonthlySalary > 100,
                               FullTimeMonthlySalary/(176*ApptProp),
                               FullTimeMonthlySalary
                               ),
           FullTimeMonthlySalary = ifelse(FullTimeMonthlySalary < 100,
                                          HourlyRate*(176*ApptProp),
                                          FullTimeMonthlySalary
                                         )
                                          
          )

                
n.employees <- dim(employees)[1]

