library(httr2)

resp <- request("https://api.github.com/users/octocat") |>
  req_perform()

# Print status code
print(resp_status(resp))

# Parse JSON body
user_data <- resp_body_json(resp)

# Print some fields
print(user_data$login)
print(user_data$name)
print(user_data$public_repos)