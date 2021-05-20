args <- commandArgs()
# print(args)                                           # for validatin purposes, see: https://stackoverflow.com/a/50108581
user_id = as.character(args[6])
token = as.character(args[7])
previous_n_days = as.character(args[8])
DATE = as.character(args[9])
sleep_time_begins = as.character(args[10])
sleep_time_ends = as.character(args[11])
asc_desc_linestring = as.character(args[12])
time_zone = as.character(args[13])
buffer_meters = as.character(args[14])
resolution_dem = as.character(args[15])
verbose_Rmd = as.character(args[16])                    # !!!!!! verbosity for the .Rmd file, while I've set for the .R script the verbosity to TRUE by default I might have to enable this parameter to debug any errors


#..........................
# specify the time interval
#..........................

next_n_days = as.integer(previous_n_days)
date_start = as.Date(DATE) - next_n_days
DATE = as.character(date_start)


# print(user_id)                                        # !!!! don't print 'user-id' and 'token'
# print(token)
print(previous_n_days)
print(DATE)
print(sleep_time_begins)
print(sleep_time_ends)
print(asc_desc_linestring)
print(time_zone)
print(buffer_meters)
print(resolution_dem)
print(verbose_Rmd)


#................................
# Directory to save the .RDS data
#................................

# dir_save = "content/post"
dir_save = file.path("content/post", glue::glue("{DATE}-fitbitviz"))          # create a separate directory for each Date's data (I'll have many .Rds files each time)
if (!dir.exists(dir_save)) dir.create(dir_save)

# path_rmd = file.path(dir_save, glue::glue("{DATE}-fitbitviz.Rmd"))          # !!! the '.Rmd' file path has to begin with the input DATE
path_rmd = file.path(dir_save, "index.Rmd")


#....................
# parameters (modify)
#....................

date_end = date_start + next_n_days                   # Add 'next_n_days' days to the 'date_start' variable to come to a N-days plot  (normally 7-days plot)
rows_plots = ceiling((next_n_days + 1) / 2)           # account for the fact that I'll have 2-column plots, therefore compute the number of plot-rows
num_character_error = 135                             # print that many character in case of an error
verbose = TRUE                                        # Enable verbosity to spot any errors when I run the .R script
CRS_value = 4326


#.......................
# heart rate time series
#.......................

heart_dat = fitbitViz::heart_rate_time_series(user_id = user_id,
                                              token = token,
                                              date_start = DATE,
                                              date_end = as.character(date_end),
                                              time_start = '00:00',
                                              time_end = '23:59',
                                              detail_level = '1min',
                                              ggplot_intraday = TRUE,
                                              ggplot_ncol = 2,
                                              ggplot_nrow = rows_plots,
                                              verbose = verbose,
                                              show_nchar_case_error = num_character_error)

path_heart_dat = file.path(dir_save, glue::glue("heart_dat_{DATE}.RDS"))
saveRDS(object = heart_dat, file = path_heart_dat)

cat("======================================================\n")
cat("The 'heart_dat' object was saved ..\n")
str(heart_dat)
cat("======================================================\n")


#.......................
# sleep data time series
#.......................

sleep_ts = fitbitViz::sleep_time_series(user_id = user_id,
                                        token = token,
                                        date_start = DATE,
                                        date_end = as.character(date_end),
                                        ggplot_color_palette = 'ggsci::blue_material',
                                        ggplot_ncol = 2,
                                        ggplot_nrow = rows_plots,
                                        show_nchar_case_error = num_character_error,
                                        verbose = verbose)

path_sleep_ts = file.path(dir_save, glue::glue("sleep_ts_{DATE}.RDS"))
saveRDS(object = sleep_ts, file = path_sleep_ts)

cat("======================================================\n")
cat("The 'sleep_ts' object was saved ..\n")
print(names(sleep_ts))
str(sleep_ts[1:2])
cat("======================================================\n")


#...................
# extract the log-id   (required for the GPS data)
#...................

log_id = fitbitViz::extract_LOG_ID(user_id = user_id,
                                   token = token,
                                   after_Date = DATE,
                                   limit = 10,
                                   sort = 'asc',
                                   verbose = verbose)

path_log_id = file.path(dir_save, glue::glue("log_id_{DATE}.RDS"))
saveRDS(object = log_id, file = path_log_id)

cat("======================================================\n")
cat("The 'log_id' object was saved ..\n")
print(log_id)
cat("======================================================\n")


#....................................................
# return the gps-ctx data.table for the output log-id
#....................................................

res_tcx = NULL

if (!is.null(log_id)) {

  res_tcx = fitbitViz::GPS_TCX_data(log_id = log_id,
                                    user_id = user_id,
                                    token = token,
                                    time_zone = time_zone,
                                    verbose = verbose)
}

path_res_tcx = file.path(dir_save, glue::glue("res_tcx_{DATE}.RDS"))
saveRDS(object = res_tcx, file = path_res_tcx)


cat("======================================================\n")
cat("The 'res_tcx' object was saved ..\n")
str(res_tcx)
cat("======================================================\n")


#...................................................
# compute the sf-object buffer and the raster-extend  (1000 meters buffer)
#...................................................

sf_rst_ext = NULL

if (!is.null(res_tcx)) {

  sf_rst_ext = fitbitViz::extend_AOI_buffer(dat_gps_tcx = res_tcx,
                                            buffer_in_meters = as.integer(buffer_meters),
                                            CRS = CRS_value,
                                            verbose = verbose)
}

path_sf_rst_ext = file.path(dir_save, glue::glue("sf_rst_ext_{DATE}.RDS"))
saveRDS(object = sf_rst_ext, file = path_sf_rst_ext)

cat("======================================================\n")
cat("The 'sf_rst_ext' object was saved ..\n")
print(sf_rst_ext)
cat("======================================================\n")


#..................................................................
# Download the Copernicus DEM 30m elevation data
# there is also the option to download the DEM 90m elevation data
# which is of lower resolution but the image size is smaller which
# means faster download
#..................................................................

raysh_rst = NULL

if (!is.null(sf_rst_ext)) {

  dem_dir = tempdir()

  dem30 = CopernicusDEM::aoi_geom_save_tif_matches(sf_or_file = sf_rst_ext$sfc_obj,
                                                   dir_save_tifs = dem_dir,
                                                   resolution = as.integer(resolution_dem),
                                                   crs_value = CRS_value,
                                                   threads = parallel::detectCores(),
                                                   verbose = verbose)

  TIF = list.files(dem_dir, pattern = '.tif', full.names = T)

  if (length(TIF) > 1) {

    #....................................................
    # create a .VRT file if I have more than 1 .tif files
    #....................................................

    file_out = file.path(dem_dir, 'VRT_mosaic_FILE.vrt')

    vrt_dem30 = CopernicusDEM::create_VRT_from_dir(dir_tifs = dem_dir,
                                                   output_path_VRT = file_out,
                                                   verbose = verbose)
  }

  if (length(TIF) == 1) {

    #..................................................
    # if I have a single .tif file keep the first index
    #..................................................

    file_out = TIF[1]
  }

  #.......................................
  # crop the elevation DEM based on the
  # coordinates extent of the GPS-CTX data
  #.......................................

  raysh_rst = fitbitViz::crop_DEM(tif_or_vrt_dem_file = file_out,
                                  sf_buffer_obj = sf_rst_ext$sfc_obj,
                                  CRS = CRS_value,
                                  digits = 6,
                                  verbose = verbose)
}


path_raysh_rst = file.path(dir_save, glue::glue("INIT_INVALID_PATH.tif"))

if (!is.null(raysh_rst)) {
  path_raysh_rst = file.path(dir_save, glue::glue("raysh_rst_{DATE}.tif"))
  raster::writeRaster(x = raysh_rst, filename = path_raysh_rst)
}


cat("======================================================\n")
cat("The 'raysh_rst' object was saved ..\n")
print(raysh_rst)
cat("======================================================\n")


#....................................................................................
# expand the knitr .Rmd file
#
# References for "knitr::knit_expand()":
#         - https://jdblischak.github.io/workflowr/articles/wflow-07-common-code.html
#         - https://cran.r-project.org/web/packages/knitr/vignettes/knit_expand.html
#....................................................................................

rmd_data = knitr::knit_expand(file = 'R_templates/functions_template.Rmd',
                              doc_title = glue::glue("{DATE}  to  {as.character(date_end)}  ( Fitbit Visualizations )"),
                              path_heart_dat = basename(path_heart_dat),
                              sleep_time_begins = sleep_time_begins,
                              sleep_time_ends = sleep_time_ends,
                              path_sleep_ts = basename(path_sleep_ts),                    # !!! in the Rmarkdown file I call the basename() of the file.path because the current directory is "/Users/runner/work/fitbitVizBlog/fitbitVizBlog/content/post/"
                              path_log_id = basename(path_log_id),
                              DATE = DATE,
                              date_end = as.character(date_end),
                              path_res_tcx = basename(path_res_tcx),
                              verbose = verbose_Rmd,
                              path_sf_rst_ext = basename(path_sf_rst_ext),
                              path_raysh_rst = basename(path_raysh_rst),
                              CRS_value = CRS_value,
                              asc_desc_linestring = asc_desc_linestring)

writeLines(text = rmd_data, con = path_rmd)

cat("======================================================\n")
cat("The 'rmd_data' object was saved ..\n")
str(rmd_data)
cat("======================================================\n")


#................................................................
# remove the next line if for some reason I receive an error (for
# instance if the files do not exist between github action runs)
#................................................................

if (dir.exists(dem_dir)) unlink(dem_dir, recursive = TRUE)


