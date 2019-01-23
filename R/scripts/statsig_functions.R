##==================================================================================##
# STATISTICAL SIGNIFICANCE TESTING
#  Library of functions for testing statistical signifiance with ACS data
#
# Cecile Murray
# September 2017
##==================================================================================##

#============================================================#
# BASIC FUNCTIONS
#============================================================#

# convert error margins to standard errors squared
convert_moe <- function(moe) {
  return((moe/1.645)^2)
}

# convert standard error squared to error margin
convert_se2 <- function(se2) {
  return(sqrt(se2)*1.645)
}

# compute Z scores
calcz <- function(a, b, a_se2, b_se2) {
  return((a-b)/sqrt(a_se2+b_se2))
} 


# check z score significance at 90% level
is_sig <- function(z) {
  return(ifelse(abs(z)>1.645, 1, 0))
}

# check the difference between two estimates is stat sig (90%)
check_sig <- function(df, a, b, a_se2, b_se2) { 
  
  temp <- df %>% select(a, b, a_se2, b_se2)
  outvar <- paste0(a, "_sig_change")
  temp %<>% mutate(is_change_sig = is_sig(calcz(a, b, a_se2, b_se2)))
  df[, c(outvar)] <- temp$is_change_sig
  return(df)
  
}

#============================================================#
# DERIVED ESTIMATES
#============================================================#

# compute standard errors for derived estimates
derive_se2 <- function(a, b, a_se2, b_se2, type) {
  
  # check that type is one of the derived options
  derived_options <- c("sumdiff", "prop", "perc", "ratio", "prod")
  stopifnot(type %in% derived_options)
  
  # for sums or differences of the form a + b
  if(type=="sumdiff") {
    return(a_se2 + b_se2)
    
    # for proportions or percents of the form a / b
  } else if(type=="prop" | type=="perc") {
    return(ifelse(a_se2 >= (a / b) * b_se2,
                  (1 / b)^2 * (a_se2 - (a / b)^2 * b_se2) * ifelse(type=="perc", 100, 1),
                  (1 / b)^2 * (a_se2 + (a / b)^2 * b_se2) * ifelse(type=="perc", 100, 1)))
    
    # for ratios where numerator is not a subset of denominator, a / b
  } else if(type=="ratio") {
    return((1 / b)^2 * (a_se2 + (a / b)^2 * b_se2))
    
    # for products a x b    
  } else if(type=="prod") {
    return(a^2 * b_se2 + b^2 * a_se2)
    
  } else {
    stop("Type not defined.")
  }
}

#============================================================#
# HELPFUL CLEANING FUNCTIONS
#============================================================#

# Pad FIPS codes with leading zeroes
padz <- function(x, n=max(nchar(x))) gsub(" ", "0", formatC(x, width=n)) 


# convert error margins to SE2 
# NOTE: mutate_at() works as well or better in basic cases
convert_errors <- function(df, geoid, moe_id, source, col_start = "") {
  
  if(!source %in% c("api", "ff")) {
    print("Syntax error: source must be api or ff.")
    return(df)
  }
  
  if(source=="api") {
    error_df <- df %>% select(ends_with(moe_id)) %>%
      apply(2, convert_moe) %>%
      data.frame() 
    error_df[, c(geoid)] <- df[, c(geoid)]
    df %<>% select(-ends_with(moe_id)) %>% merge(error_df, by=geoid)
    df <- df[, c(geoid, sort(names(df)[2:ncol(df)]))]
    
  } else if(source=="ff") {
    col_start <- ifelse(col_start=="", 3, col_start)
    error_df <- df %>% select(starts_with(moe_id)) %>%
      apply(2, convert_moe) %>%
      data.frame() 
    error_df[, c(geoid)] <- df[, c(geoid)]
    df %<>% select(-starts_with(moe_id)) %>% merge(error_df, by=geoid)
    names(df)[col_start:ncol(df)] <- lapply(names(df)[col_start:ncol(df)], 
                        function(x) {paste0(strsplit(x, "_")[[1]][2], "_", strsplit(x, "_")[[1]][1])})
    df <- df[, c(geoid, sort(names(df)[col_start:ncol(df)]))]
  }
  
  return(df)
}

#============================================================#
# CALCULATING CHANGE
#============================================================#

# calculate change across two identical data frame (w/adjustment to any SE2s)
calc_change <- function(df1, df2, geoid, se2_char) {
  ch_df <- df1
  df2 %<>% mutate_at(vars(contains(se2_char)), funs(. * -1))
  ch_df[, 2:ncol(ch_df)] <- df1[, 2:ncol(df1)] - df2[, 2:ncol(df2)]
  df2 %<>% mutate_at(vars(contains(se2_char)), funs(. * -1))
  return(ch_df)
}

# function to calculate stat sig difference from zero given a change dataframe
calc_sig <- function(ch_df, geoid, se2_char, vars, years){
  sig_df <- ch_df %>% mutate(b = 0, b_se2 = 0)
  
  for(v in seq_along(vars)){
    sig_df %<>% se_mutate4(function(a, b, c, d) {is_sig(calcz(a, b, c, d))},
                           vars[v], "b", paste0(vars[v], se2_char), "b_se2",
                           paste0(vars[v], "_sig_", years[1], years[2]))
  }
  
  sig_df %<>% select(one_of(geoid), contains("_sig_"))
  return(sig_df)
}

# function to calculate change and add stat sig using two identical dataframes
add_change <- function(df1, df2, geoid, se2_char, vars, years){
  
  ch_df <- calc_change(df1, df2, geoid, se2_char)
  sig_df <- calc_sig(ch_df, geoid, se2_char, vars, years)
  
  # now, renaming change df:
  ch_names <- lapply(vars, function(x) {paste0(x, "_ch_", years[1], years[2])})
  ch_df %<>% select(-contains(se2_char)) %>% select(one_of(geoid), everything())
  names(ch_df)[2:ncol(ch_df)] <- ch_names
  
  # last, merging change and stat sig together
  rv <- merge(ch_df, sig_df, by=geoid)
  return(rv)
}