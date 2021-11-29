
<br>

#### **Hugo Lithium (theme) of R blogdown for Fitbit Visualizations**

<br>

* There were a [few changes](https://stackoverflow.com/a/43505891/8302386) compared to the [initial hugo-lithium-theme](https://github.com/jrutheiser/hugo-lithium-theme)

* I modified the [main.css 'img'](https://github.com/mlampros/fitbitVizBlog/blob/master/themes/hugo-lithium/static/css/main.css#L32-L34) and [main.css 'content'](https://github.com/mlampros/fitbitVizBlog/blob/master/themes/hugo-lithium/static/css/main.css#L97-L98) to increase the wide of the plots in the output website.

* For more details on how to setup a similar website take a look to the [README.md file of the fitbitViz](https://github.com/mlampros/fitbitViz#keep-track-of-your-activities-using-fitbitviz-blogdown-and-github-actions) R package

<br>

##### **Frequent issues when running the [gh_fitbit_blog.yaml](https://github.com/mlampros/fitbitVizBlog/blob/master/.github/workflows/gh_fitbit_blog.yaml) file:**

<br>

* `Error in content_list_obj$sleep[[1]] : subscript out of bounds  Calls: <Anonymous> -> sleep_single_day`
    * *You haven't updated the Fitbit data in your account! Connect to the application to upload the recent data for this Date*

* `Error in hillshade[, , 1] * scales::rescale(shadowmap, c(max_darken, 1)) : non-conformable arrays`
    * *Highly probable it's caused by the 'linestring_ASC_DESC' parameter of the 'fitbitViz::rayshader_3d_DEM()' function. Set this parameter to NULL for the specific route or specify a time point for the split (see documentation)*

* `Error: Using bundled GitHub PAT. Please add your own PAT to the env var `GITHUB_PAT` Error: Failed to install 'unknown package' from GitHub: HTTP error 401. Bad credentials`
    * Use the **auth_token = '${{ secrets.GH_PAT }}'** parameter in **remotes::install_github()** ( See the **README.md** file of the [fitbitViz](https://github.com/mlampros/fitbitViz#keep-track-of-your-activities-using-fitbitviz-blogdown-and-github-actions) package on how to create the **GH_PAT** environment variable)
    * In case that it still gives the error then first run **Sys.setenv(GITHUB_PAT = '${{ secrets.GH_PAT }}')** and then proceed with the **remotes::install_github()** function **without** the **auth_token** parameter. See (and use) for instance [this line of code](https://github.com/mlampros/fitbitVizBlog/blob/master/.github/workflows/gh_fitbit_blog.yaml#L118).
    
<br>
