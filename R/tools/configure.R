#!/usr/bin/env Rscript

# Set platform specific name of tskitr library and add appropriate flags
setTskitrLibAndFlags <- function() {
  if (.Platform$OS.type == "unix") {
    # Unix/Linux & macOS
    libname <- "tskitr.so"
  } else if (.Platform$OS.type == "windows") {
    libname <- "tskitr.dll.a" # MinGW/Rtools (default)
    # "tskitr.lib" # MSVC (backup to MinGW/Rtools)
    # "tskitr.dll" # DLL (backup to MinGW/Rtools)
  } else {
    stop("Unknown .Platform$OS.type!")
  }
  # TODO: Make this portable across Unix/Linux/macOS/Windows platforms
  ret <- paste0("-Wl,-install_name,@rpath/", libname)
  return(ret)
}

# Render a Makevars file from a template by replacing placeholders.
# @param template character path to the template Makevars file
# @param output character path to the output Makevars file
renderMakevars <- function(template, output) {
  if (!file.exists(template)) {
    stop("Template file does not exist: ", template, "!")
  }
  tskitrLibAndFlags <- setTskitrLibAndFlags()
  lines <- readLines(con = template)
  lines <- gsub(
    x = lines,
    pattern = "@TSKITR_LIB@",
    replacement = tskitrLibAndFlags,
    fixed = TRUE
  )
  writeLines(text = lines, con = output)
  invisible(TRUE)
}

# renderMakevars(template = "this_should_fail", output = "before_getting_to_output")
if (.Platform$OS.type == "unix") {
  # readLines(con = "src/Makevars.in")
  success <- renderMakevars(
    template = "src/Makevars.in",
    output = "src/Makevars"
  )
} else {
  # readLines(con = "src/Makevars.win.in")
  success <- renderMakevars(
    template = "src/Makevars.win.in",
    output = "src/Makevars.win"
  )
}
if (!success) {
  stop("renderMakevars() failed!")
}
