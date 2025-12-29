# ==============================================================================
# CSV DIAGNOSTIC SCRIPT
# ==============================================================================
# Use this script to inspect your CSV file and identify column names

# Configuration
DATA_FILE <- "data/raw/dados.csv"
HEADER_SKIP_LINES <- 11

cat("=== CSV FILE DIAGNOSTIC ===\n\n")

# Test different encodings
encodings <- c("UTF-8", "latin1", "ISO-8859-1", "CP1252")

for (enc in encodings) {
  cat(paste0("\n--- Testing encoding: ", enc, " ---\n"))
  
  tryCatch({
    # Read header
    header <- read.csv(file = DATA_FILE, header = TRUE, fill = TRUE, sep = ";", nrows = 1)
    cat("Header metadata (first 4 lines):\n")
    print(header[1:min(4, ncol(header))])
    
    # Read actual data
    df <- read.csv(
      file = DATA_FILE,
      skip = HEADER_SKIP_LINES - 1,
      header = TRUE,
      fill = TRUE,
      sep = ";",
      fileEncoding = enc,
      nrows = 5  # Just first 5 rows for inspection
    )
    
    cat("\nColumn names found:\n")
    for (i in seq_along(names(df))) {
      cat(sprintf("%2d. %s\n", i, names(df)[i]))
    }
    
    cat("\nFirst 2 rows of data:\n")
    print(head(df, 2))
    
    cat("\n", strrep("=", 80), "\n")
    
  }, error = function(e) {
    cat(paste("ERROR with encoding", enc, ":", e$message, "\n"))
  })
}

cat("\n=== DIAGNOSTIC COMPLETE ===\n")
cat("Copy the correct encoding and column names to update data_loader.R\n")