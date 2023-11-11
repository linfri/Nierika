# This script (not intended to run as a function) mass-mails the codes
# (download/promotion/discount/etc) using Gmail and existing email list.

# Read the documentation for gmailr on how to set up Gmail credentials:
# https://gmailr.r-lib.org/articles/oauth-client.html

library(dplyr)
library(purrr)
library(gmailr)
library(readr)

# Load the email list
emails <- read.csv("emails.csv")
emails <- emails %>% select(Name, Email) %>% unique()

# Form the dataset with names, codes and emails.
# Note that you actually must have the same number of codes and names!
df <- cbind(
  head(read.csv("codes.csv"), nrow(emails)),
  emails$Name,
  emails$Email
) %>% as.data.frame()
colnames(df) <- c("Code", "Name", "Email")

# Clean up the environment
remove(emails)

# Define the sender, the BCC and the body
email_sender <- "Nierika Productions <nierika.productions@gmail.com>"
optional_bcc <- "LR Friberg <linn.friberg@pm.me>"
body <- read_file("body.txt")

# Create the outbound emails. Don't forget to recheck the body!
outbound <- df %>%
  mutate(
    To = sprintf('%s <%s>', Name, Email),
    Bcc = optional_bcc,
    From = email_sender,
    Subject = sprintf("Download Codes for %s", Name),
    body = sprintf(body, Name, Code)) %>%
  select(To, Bcc, From, Subject, body)
write.csv(outbound, "outbound.csv")

# Register the OAuth client for use with gmailr
gm_auth_configure()
gm_oauth_client()

# Send messages
for(i in 1:nrow(outbound)) {
  email <- gm_mime() %>%
    gm_to(outbound$To[i]) %>%
    gm_from(outbound$From[i]) %>%
    gm_subject(outbound$Subject[i]) %>%
    gm_text_body(outbound$body[i])
  gm_send_message(email)
}
