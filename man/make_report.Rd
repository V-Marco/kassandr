% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/reporter.R
\name{make_report}
\alias{make_report}
\title{Produces report table}
\usage{
make_report(download_log, path, SUCCESS = "success")
}
\arguments{
\item{download_log}{metadata about downloaded series}

\item{path}{path to specific day}

\item{SUCCESS}{string marker for success in download_log tibble}
}
\value{
data.frame
}
\description{
Produces table with additional information concerning downloaded data.
}
\details{
Several metrics to detect potential download errors.
}
\examples{
\donttest{
info = Sys.info() # получаем информацию о системе

if (info[1] == "Linux") {
  docxtractr::set_libreoffice_path("/usr/bin/libreoffice")  # ubuntu or macos
  Sys.setenv(LD_LIBRARY_PATH = "/usr/lib/libreoffice/program/") # ubuntu protection against libreglo.so not found
}

if (info[1] == "Windows") {
  Sys.setenv("TAR" = "internal") # if install_github() fails on Windows OS
  docxtractr::set_libreoffice_path("C:/Program Files/LibreOffice/program/soffice.exe")  # windows
}
path = tempdir()
path_day = paste0(path, "/", Sys.Date(), "/") # add current date to path
dir.create(path_day)
# download_log_new = download_statistics(path_day, watchdog)
# report_table = make_report(download_log_new, path_day)
}
}
