#The following is a script to turn .cha files from CHILDES into clean text data
#and then input the following as a GPT3 prompt for a completion task

#required libraries, if needed, use the install.packages() command in the R console

library(tidyverse)
library(stringr)
library(rgpt3)
library(readtext)


### Reading and cleaning of the CHILDES files (dirty .cha -> clean .txt)

#Converting cha to txt, reading txts from dir, cleaning the txt files and saving the clean txt files

setwd("C:/Users/Lenovo/Documents/wug-gpt/dirtychafiles")

file.rename(list.files(pattern="*.cha"), gsub("\\.cha$", ".txt", list.files(pattern="*.cha")))

transcripts = list.files(pattern="*.txt")

for (i in transcripts) {
  transcript = readLines(i)
  transcript = str_remove_all(transcript, "^%mor:.*")
  transcript = str_remove_all(transcript, "^%gra:.*")
  transcript = str_remove_all(transcript, "\\x15.*?\\x15")
  transcript = str_remove_all(transcript, "\\[ \\+ NAC \\]")
  transcript = str_remove_all(transcript, "^\\t.*")
  transcript = str_remove_all(transcript, "^(\\r|\\n)*")
  transcript = str_remove_all(transcript, "^\\s+$")
  transcript = str_remove_all(transcript, "\\[[^\\]]+\\]")
  transcript = str_subset(transcript, "^(?!\\s*$).*")
  childage = str_extract(transcript,"(?<=CHI\\|).+?(?=\\|)")
  childage = childage[!is.na(childage)]
  chi_yr = str_extract(childage,"^([^;]+)")
  chi_yr = chi_yr[!is.na(chi_yr)]
  chi_mnt = str_extract(childage,"(?<=;)[^;.]+(?=\\.)")
  chi_mnt = chi_mnt[!is.na(chi_mnt)]
  chi_day = str_extract(childage,"(?<=\\.)\\d+")
  chi_day = chi_day[!is.na(chi_day)]
  childappendix = paste0("*Child that is ", chi_yr," years, ", chi_mnt," months and ", chi_day, " days old:")
  transcript = str_replace_all(transcript, "\\*CHI:", childappendix)
  transcript = str_remove_all(transcript, "^@.*")
  transcript = str_subset(transcript, "^(?!\\s*$).*")
  writeLines(transcript, i)
}


# Prompting the LLM and saving it as an entry of a csv file

setwd("C:/Users/Lenovo/Documents/wug-gpt")

gpt3_authenticate("access_key.txt")

setwd("C:/Users/Lenovo/Documents/wug-gpt/dirtychafiles")

promptlist = c()
transcrip = list.files(pattern="*.txt")
transcripts = head(transcrip,n=10)

for (i in transcripts) {
  transcript = readtext(i)$text
  transcript = substring(transcript, first = 1, last = 1000) 
  transcript = paste("The following is a transcript of a conversation between an adult and a child. Approach the following text as closed captions of the conversation and try to complete the text below to the best of your abilities ", transcript)
  promptlist = append(promptlist,transcript)
}

my_prompts = data.frame('prompts' = promptlist
                        ,'prompt_id' = c(LETTERS[1:length(promptlist)]))


completions = gpt3_completions(prompt_var = my_prompts$prompts
                             , id_var = my_prompts$prompt_id
                             , param_model = 'text-davinci-003'
                             , param_max_tokens = 3000
                             , param_n = 1
                             , param_temperature = 0)

setwd("C:/Users/Lenovo/Documents/wug-gpt")

vysledky = data.frame(completions[[1]][["gpt3"]])

write_csv(vysledky, "výsledky_completions.csv")
